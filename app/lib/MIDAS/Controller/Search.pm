
package MIDAS::Controller::Search;

use Moose;
use namespace::autoclean;

use File::Basename;
use List::MoreUtils qw( mesh );
use Text::CSV_XS;
use Try::Tiny;

BEGIN { extends 'MIDAS::Base::Controller::Restful'; }

=head1 NAME

MIDAS::Controller::Search - Catalyst Controller to handle searching of sample
data

=head1 DESCRIPTION

This is a L<Catalyst::Controller> to handle searching of HICF sample data.

=cut

#-------------------------------------------------------------------------------
#- private attributes  ---------------------------------------------------------
#-------------------------------------------------------------------------------

has '_csv' => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    Text::CSV_XS->new( { blank_is_undef => 1 } );
  },
);

#-------------------------------------------------------------------------------
#- public actions --------------------------------------------------------------
#-------------------------------------------------------------------------------

=head1 ACTIONS

=head2 search : Global Does('~NeedsAuth')

Accepts an upload of a CSV file describing a set of simple queries, then runs
the queries and returns results as a CSV file.

=cut

sub search : Global
             Does('~NeedsAuth') {
  my ( $self, $c ) = @_;

  # was there actually an upload ?
  my $upload = $c->req->upload('query');
  unless ( defined $upload ) {
    $c->res->status(400); # bad request
    $c->res->body('You must upload a CSV file');
    return;
  }

  #---------------------------------------

  # yes; read it
  $c->log->debug('checking uploaded file')
    if $c->debug;

  my ( $fields, $query_rows );

  my $call_failed = 0;
  try {
    ( $fields, $query_rows ) = $self->_parse_query_csv($upload);
  }
  catch {
    $c->log->error("Couldn't read uploaded file");
    $c->res->status(500); # internal server error
    $c->res->body("Couldn't read your CSV file");
    $call_failed = 1;
  };

  # can't "return" inside a "catch" block...
  return if $call_failed;

  #---------------------------------------

  # put the output column names into the output slot in the stash
  push @{ $c->stash->{output} }, [ @{ $self->returned_columns }, 'query_number' ];

  # run the search(es)
  my $query_number = 1;
  foreach my $query_row ( @$query_rows ) {

    # generate a query from the CSV data
    my $query = $c->forward('_build_query', [ $query_number, $fields, $query_row ] );

    # actually run the query ("forward" to this one because it needs access
    # to the context object, $c). The samples that we've found are available
    # in the stash slot "samples".
    $c->forward( '_run_query', [ $query_number, $query ] );

    $query_number++;
  }

  #---------------------------------------

  # build a header row
  my $status = $self->_csv->combine(@{ $self->returned_columns }, 'amr', 'query_number');
  unless ( $status ) {
    $c->log->error('error while generating output CSV header');
    $c->res->status(500); # internal server error
    $c->res->body('There was a problem creating the header for your results CSV file');
    return;
  }

  # add the header row to the output
  my @output = ( $self->_csv->string );

  foreach my $sample ( @{ $c->stash->{samples} } ) {

    # get the values for the database column
    my @values = map { $sample->{$_} } @{ $self->returned_columns };

    # format the AMR data for this sample and add that
    push @values, _format_amr($sample->{amr});

    # finally, add the index number for the query that returned this sample
    push @values, $sample->{query_number};

    $status = $self->_csv->combine(@values);
    unless ( $status ) {
      $c->log->error('error while generating output CSV body');
      $c->res->status(500); # internal server error
      $c->res->body('There was a problem generating your results CSV file');
      return;
    }

    # add the row for this sample to the output
    push @output, $self->_csv->string;
  }

  # build the response
  $c->res->status(200); # OK
  $c->res->content_type('text/csv');

  my ( $output_filename, $path, $suffix ) =
    fileparse( $c->req->upload('query')->filename, qr/\.[^.]*/ );
  $output_filename .= '_result.csv';
  $c->res->header('Content-disposition', qq(attachment; filename="$output_filename") );

  my $content = join "\n", @output;
  $c->res->body($content);
}

#-------------------------------------------------------------------------------
#- private actions -------------------------------------------------------------
#-------------------------------------------------------------------------------

# for each query specified by the uploaded CSV file, generate a database query.
# Returns a reference to a hash with the query terms that can be handed to
# DBIx::Class::Resultset::search

sub _build_query : Private {
  my ( $self, $c, $query_number, $fields, $query_row ) = @_;

  # first, make sure that the query has the same number of columns as the
  # header row did
  my $num_fields = scalar @$fields;
  my $num_values = scalar @$query_row;

  unless ( $num_fields == $num_values ) {
    $c->log->error('query had wrong number of columns');
    $c->res->status(400); # bad request
    my $problem = $num_fields > $num_values ? 'few' : 'many';
    $c->res->body("Query $query_number had too $problem fields (had $num_values; needed $num_fields)");
    return;
  }

  #---------------------------------------

  # zip together the column headers and values to get a hash
  my %query = mesh @$fields, @$query_row;

  # strip out fields that are undef, otherwise they'll end up creating
  # clauses in the final SQL like "WHERE x IS NULL"
  while ( my ( $key, $value ) = each %query ) {
    delete $query{$key} if not defined $value;
  }

  # make sure we're only looking at live data (we don't want rows that have a
  # value for "deleted_at")
  $query{'me.deleted_at'} = undef;

  # convert "collected_before" and "collected_after" into inequalities
  # against the "collection_date" database column
  if ( $query{collected_before} or $query{collected_after} ) {
    $query{collection_date} = [ '-and' ];
    if ( $query{collected_before} ) {
      my $before_date = delete $query{collected_before};
      push @{ $query{collection_date} }, { '<', $before_date };
    }
    if ( $query{collected_after} ) {
      my $after_date = delete $query{collected_after};
      push @{ $query{collection_date} }, { '>=', $after_date };
    }
  }

  return \%query;
}

#-------------------------------------------------------------------------------

# execute a DBIC query using the supplied query hash. Results are put into the
# stash in the "samples" slot

sub _run_query : Private {
  my ( $self, $c, $query_number, $query ) = @_;

  my $rs = $c->model->resultset('Sample')->search($query);

  # while ( my $row = $rs->next ) {
  foreach my $row ( $rs->all ) {
    my %sample = map { $_ => $row->get_column($_) } @{ $self->returned_columns };

    # convert the GAZ term into the term description, which is a proxy for the
    # location description
    $sample{location_description} = $row->location_description->description
      if defined $row->location && defined $row->location_description;

    # get the AMR data for the sample, if it exists
    my $amr_data = [];
    push @$amr_data, { $_->get_columns } for $row->get_amr->all;
    $sample{amr} = $amr_data;

    # record the query number that generated this sample row
    $sample{query_number} = $query_number;

    push @{ $c->stash->{samples} }, \%sample;
  }
}

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# reads the CSV file uploaded in the request. The CSV describes a set of
# queries that we should run. Returns a reference to an array containing the
# list of column headers for the query CSV, and a reference to an array
# containing the queries in the file, one per row

sub _parse_query_csv {
  my ( $self, $upload ) = @_;

  # no error catching here: if we hit an exception, let the caller deal with it

  open my $fh, '<:encoding(utf8)', $upload->tempname
    or die "ERROR: problem reading CSV file: $!";

  # these are the column headers, which tell us which fields to search on
  my $fields = $self->_csv->getline($fh);

  # get the values from the remaining rows; these are the search values
  my $query_rows;
  while ( my $row = $self->_csv->getline($fh) ) {
    push @$query_rows, $row;
  }

  close $fh;

  return ( $fields, $query_rows );
}

#-------------------------------------------------------------------------------

# formats the antimicrobial resistance test results for the given row. This is
# a straight clone of the method in the Restful base class. We can't hook into
# tht mechanism directly because we want the browser to receive results as a
# CSV file, without faffing about with javascript that can change "Accept" or
# "content-type" headers on the request.

sub _format_amr {
  my ( $amrs ) = shift;

  # hide warnings that pop up when there's no value for the susceptibility,
  # etc.
  no warnings 'uninitialized';

  my @amrs = ();
  foreach my $amr ( @$amrs ) {
    my $amr_string .= $amr->{antimicrobial_name} . ';'
                   .  $amr->{susceptibility} . ';'
                   .  ( $amr->{equality} eq 'eq' ? '' : $amr->{equality} )
                   .  $amr->{mic};

    $amr_string .= ';' . $amr->{method} if $amr->{method};

    push @amrs, $amr_string;
  }

  return join ',', @amrs;
}

#-------------------------------------------------------------------------------

=encoding utf8

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
