
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

has '_column_names' => (
  is      => 'ro',
  default => sub {
    [
      qw(
        sample_id
        manifest_id
        raw_data_accession
        sample_accession
        donor_id
        sample_description
        submitted_by
        tax_id
        scientific_name
        collected_by
        source
        collection_date
        location
        host_associated
        specific_host
        host_disease_status
        host_isolation_source
        patient_location
        isolation_source
        serovar
        other_classification
        strain
        isolate
        )
    ];
  }
);

#-------------------------------------------------------------------------------
#- public actions --------------------------------------------------------------
#-------------------------------------------------------------------------------

sub search : Global
             Does('~NeedsAuth') {
  my ( $self, $c ) = @_;

  # was there actually an upload ?
  my $upload;
  unless ( $upload = $c->req->upload('query') ) {
    $c->res->status(400); # bad request
    $c->res->body('You must upload a CSV file');
    return;
  }

  $c->log->debug('checking uploaded file')
    if $c->debug;

  # yes; make sure it's readable
  my $call_failed = 0;

  my $fields;
  my $query_rows;
  try {
    open my $fh, '<:encoding(utf8)', $upload->tempname
      or die "ERROR: problem reading CSV file: $!";

    $fields = $self->_csv->getline($fh);

    while ( my $row = $self->_csv->getline($fh) ) {
      push @$query_rows, $row;
    }

    close $fh;
  }
  catch {
    $c->log->error("Couldn't read uploaded file: $_");
    $c->res->status(500); # internal server error
    $c->res->body("Couldn't read your CSV file");
    $call_failed = 1;
  };
  return if $call_failed;

  $c->stash(
    fields  => $fields,
    queries => $query_rows,
  );

  # the query fields and values were readable, so we can go off and build and
  # run a query
  $c->forward('_query');

  # we should really do something more Catalyst-like, and add a CSV view, but
  # for a one-off like this we'll just build the output CSV
  my @rows;
  foreach my $row_data ( @{ $c->stash->{output} } ) {
    my $success = $self->_csv->combine( @$row_data );
    if ( not $success ) {
      $c->log->error("couldn't build result file");
      $c->res->status(500); # internal server error
      $c->res->body("Couldn't build your result CSV file");
      return;
    }
    push @rows, $self->_csv->string;
  }

  # build the response
  my ( $output_filename, $path, $suffix ) =
    fileparse( $c->req->upload('query')->filename, qr/\.[^.]*/ );

  $output_filename .= '_result.csv';
  my $output = join "\n", @rows;

  $c->res->status(200); # OK
  $c->res->content_type('text/csv');
  $c->res->header('Content-disposition', qq(attachment; filename="$output_filename"));
  $c->res->body($output);
}

#-------------------------------------------------------------------------------
#- private actions -------------------------------------------------------------
#-------------------------------------------------------------------------------

sub _query : Private {
  my ( $self, $c ) = @_;

  # put the output column names into the output slot in the stash
  push @{ $c->stash->{output} }, [ @{ $self->_column_names }, 'query_number' ];

  # generate a query from the CSV data
  my $query_number = 1;
  foreach my $query_values ( @{ $c->stash->{queries} } ) {

    # make sure that the query has the same number of columns as the header row
    # did
    my $num_fields = scalar @{ $c->stash->{fields} };
    my $num_values = scalar @$query_values;

    unless ( $num_fields == $num_values ) {
      $c->log->error('query had wrong number of columns');
      $c->res->status(400); # bad request
      my $problem = $num_fields > $num_values ? 'few' : 'many';
      $c->res->body("Query $query_number had too $problem fields (had $num_values; needed $num_fields)");
      return;
    }

    # zip together the column headers and values to get a hash
    my %query = mesh @{ $c->stash->{fields} }, @$query_values;

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

    # actually run the query
    my $query_results = $c->forward( '_run_query', [ \%query, $query_number ] );

    # and store the results
    push @{ $c->stash->{output} }, @$query_results;

    $query_number++;
  }

  $DB::single = 1;

  return;
}

#-------------------------------------------------------------------------------

sub _run_query : Private {
  my ( $self, $c, $query, $query_number ) = @_;

  my $rs = $c->model->resultset('Sample')->search(
    $query,
    {
      join     => [ qw( location_description antimicrobial_resistances ) ],
      prefetch => [ qw( location_description antimicrobial_resistances ) ]
    }
  );

  my @query_results = ();

  while ( my $row = $rs->next ) {
    my %row_data = $row->get_columns;

    my @row_values;
    foreach my $column_name ( @{ $self->_column_names } ) {
      push @row_values, $row_data{$column_name};
    }
    push @row_values, $query_number;

    push @query_results, \@row_values;
  }

  $DB::single = 1;

  return \@query_results;
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
