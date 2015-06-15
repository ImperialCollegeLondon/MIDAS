
package MIDAS::Controller::Sample;

use Moose;
use namespace::autoclean;

use Try::Tiny;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw( Int Str );
use MooseX::Types -declare => [ qw(
  FilterString
) ];

subtype FilterString,
  as Str,
  where { $_ !~ m/[;%]/ },
  message { 'Not a valid filter string' };

# these are the columns that can be used to filter the result set
# via "_get_sample_data"
has '_filter_columns' => (
  is => 'ro',
  default => sub {
    [ qw(
      manifest_id
      scientific_name
      tax_id
      collection_date
      collected_at
    ) ];
  }
);

# thse are the columns that will be returned by "_get_sample_data"
has '_returned_columns' => (
  is      => 'ro',
  default => sub {
    [ qw(
      sample_id
      manifest_id
      scientific_name
      tax_id
      collection_date
      collected_at
    ) ];
  }
);

BEGIN { extends 'MIDAS::Base::Controller::Restful' }

=head1 NAME

MIDAS::Controller::Sample - Catalyst Controller to handle sample data

=head1 DESCRIPTION

This is a L<Catalyst::Controller> to handle HICF sample data.

=cut

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 begin

=cut

# sub begin : Private {
#   my ( $self, $c ) = @_;
#
#   # at this point we're unauthenticated
#
#   $c->log->debug( 'begin: in begin method' )
#     if $c->debug;
# }

#-------------------------------------------------------------------------------

# sub auto : Private {
#   my ( $self, $c ) = @_;
#
#   # at this point we're unauthenticated
#
#   $c->log->debug( 'auto: in auto method' )
#     if $c->debug;
#
#   return 1;
# }

#-------------------------------------------------------------------------------

=head2 samples : Chained('/') Args(0) Does('~NeedsAuth') ActionClass('REST::ForBrowsers')

Returns information for all samples.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub samples : Chained('/')
              PathPart('samples')
              Does('~NeedsAuth')
              ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->stash( template => 'pages/samples.tt' );
}

#---------------------------------------

sub samples_GET {
  my ( $self, $c ) = @_;

  # stash two copies of the full, starting dataset. One, "rs", will be paged,
  # filtered and sorted, while the other will be kept untouched and used to
  # calculate things like the number of samples in the whole dataset.
  #
  # DBIC is (hopefully) smart enough not to instantiate the object or run the
  # query to retrieve all samples unless requested, so at this point we're just
  # storing a reference to a small DBIC object that doesn't contain any data.
  $c->stash(
    rs      => $c->model->schema->get_all_samples,
    full_rs => $c->model->schema->get_all_samples
  );

  try {
    $c->forward('_get_sample_data');
    $self->status_ok(
      $c,
      entity => $c->stash->{output}
    );
  } catch {
    $self->status_ok(
      $c,
      entity => { error => $_ }
    );
  }

  # TODO add a link to download the dataset as CSV

}

#---------------------------------------

sub samples_GET_html {
  my ( $self, $c ) = @_;

  $c->stash(
    title        => 'Samples',
    jscontroller => 'samples'
  );
}

#-------------------------------------------------------------------------------

sub samples_by_organism : Chained('/')
                          Args(1)
                          Does('~NeedsAuth')
                          ActionClass('REST::ForBrowsers') {
  my ( $self, $c, $organism ) = @_;

  # I started building a regex to detaint the organism name, but the scientific
  # names in the NCBI taxonomy appear to contain every non-word character in
  # the lexicon, with the exception of pipe ("|"), which they use as a
  # separator in "names.dmp". White-listing would end up looking something
  # like:
  #
  #   unless ( $tainted_organism =~ m|^([\w\s\.-;:'"/%\*^()[]{}\?\&\#]+)$| ) {
  #     ...
  #   }
  #
  # Basically, there's not a lot of point in trying to validate this. We'll
  # just hope that DBIC does a good job of escaping everything before it
  # hits the DB

  my $samples = $c->model->schema->get_samples_from_organism($organism);

  $c->stash(
    template => 'pages/samples.tt',
    samples  => $samples,
  );
}

#---------------------------------------

sub samples_by_organism_GET {
  my ( $self, $c ) = @_;

}

#---------------------------------------

sub samples_by_organism_GET_html {

}

#-------------------------------------------------------------------------------

=head2 sample : Chained('/') Args(1) Does('~NeedsAuth') ActionClass('REST::ForBrowsers')

Returns sample information. Captures a single argument, the ID of the sample.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub sample : Chained('/')
             Args(1)
             Does('~NeedsAuth')
             ActionClass('REST::ForBrowsers') {
  my ( $self, $c, $tainted_id ) = @_;

  # at this point the user is authenticated, either via login or session if the
  # request came from a browser, or via an HMAC in the "Authorization" header

  $c->stash( template => 'pages/sample.tt' );

  # detaint the ID from the URL
  unless ( defined $tainted_id and
           $tainted_id =~ m/^(\d+)$/ ) {
    $c->log->warn( 'Sample::sample: not a valid ID' )
      if $c->debug;
    $c->stash( error => 'Not a valid sample ID' );
    return;
  }

  my $id = $1;

  $c->log->debug( "Sample::sample: AUTHENTICATED; retrieving sample data for '$id'" )
    if $c->debug;

  my $sample = $c->model->schema->get_sample_by_id($id);

  if ( defined $sample ) {
    $c->log->debug( 'Sample::sample: stashing sample row' )
      if $c->debug;
    $c->stash( id     => $id,
               sample => $sample );
  }
  else {
    $c->log->warn( 'Sample::sample: no such sample; stashing error message' )
      if $c->debug;
    $c->stash( id    => $id,
               error => 'No such sample' );
  }
}

#---------------------------------------

# return sample data to a non-browser client

sub sample_GET {
  my ( $self, $c ) = @_;

  $c->log->debug( 'sample_GET' )
    if $c->debug;

  if ( defined $c->stash->{sample} ) {
    $self->status_ok(
      $c,
      entity => $c->stash->{sample}->fields
    );
  }
  else {
    $self->status_not_found(
      $c,
      message => $c->stash->{error}
    );
  }

}

#---------------------------------------

# return sample data to a browser

sub sample_GET_html {
  my ( $self, $c, $tainted_id ) = @_;

  $c->log->debug( 'sample_GET_html' )
    if $c->debug;

  my $title = ( defined $tainted_id and $tainted_id =~ m/^(\d+)$/ )
            ? "Sample $1"
            : "Sample";

  $c->stash(
    title        => $title,
    jscontroller => 'sample'
  );
}

#-------------------------------------------------------------------------------

=head2 summary : Chained('/') Args(0) Does('~NeedsAuth') ActionClass('REST::ForBrowsers')

Returns a summary of the samples n the database.

Requires login (for requests from a browser) or HMAC authentication (for REST
calls).

=cut

sub summary : Chained('/')
              Args(0)
              Does('~NeedsAuth')
              ActionClass('REST::ForBrowsers') {}

#---------------------------------------

before summary => sub {
  my ( $self, $c ) = @_;

  $c->stash( summary => $c->model->schema->get_sample_summary );
};

#---------------------------------------

sub summary_GET_html {
  my ( $self, $c ) = @_;

  $c->stash( template => 'pages/summary.tt' );
}

#---------------------------------------

sub summary_GET {
  my ( $self, $c ) = @_;

  $self->status_ok(
    $c,
    entity => $c->stash->{summary}
  );
}

#-------------------------------------------------------------------------------
#- private actions -------------------------------------------------------------
#-------------------------------------------------------------------------------

# return data for a set of samples
sub _get_sample_data : Private {
  my ( $self, $c ) = @_;

  die 'no resultset to work with' unless defined $c->stash->{rs};
  die 'no full resultset to work with' unless defined $c->stash->{full_rs};

  # we can take advantage of DBIC here by simply stacking up the modifications
  # to the query and letting it build a final SQL query that encompasses all of
  # them
  $c->forward('_do_paging', [ $c->req->params->{start}, $c->req->params->{length} ] );
  $c->forward('_do_filtering', [ $c->req->params->{'search[value]'} ] );
  $c->forward(
    '_do_sorting',
    [
      $c->req->params->{'order[0][dir]'},
      $c->req->params->{'order[0][column]'},
    ]
  );

  # if the response is going to a DataTable, we need to format it differently
  # and add extra information. Either way, we simply stash the output and let
  # Catalyst::Controller::REST take care of serialising it
  if ( $c->req->params->{_dt} ) {
    $c->forward(
      '_get_dt_data',
      [
        $c->req->params->{draw},
        $c->req->params->{'search[value]'},
      ]
    );
  }
  else {
    $c->forward('_get_raw_data');
  }
}

#-------------------------------------------------------------------------------

# retrieve a ResultSet containing the specified rows
sub _do_paging : Private {
  my ( $self, $c, $start, $length ) = @_;

  $c->log->debug( "_do_paging: checking bounds (start |$start|, length |$length|)" )
    if $c->debug;

  return unless defined $start;
  return unless $start =~ m/^(\d+)$/;
  my $from = $1;

  return unless defined $length;
  return unless $length =~ m/^(\d+)$/;
  my $to = $start + $1 - 1;

  $c->log->debug( "_do_paging: retrieving rows $from - $to" )
    if $c->debug;

  my $sliced_rs = $c->stash->{rs}->slice($from, $to);

  $c->stash( rs => $sliced_rs );
}

#-------------------------------------------------------------------------------

# filter the resultset
sub _do_filtering : Private {
  my ( $self, $c, $filter ) = @_;

  return if not defined $filter;
  return if $filter eq '';

  $c->log->debug( "_do_filtering: retrieving rows matching |$filter|" )
    if $c->debug;

  # apply the filter to the range ResultSet, so that we end up with the set
  # of filtered samples
  my $filtered_rs = $c->model->schema->filter_rs(
    $c->stash->{rs},
    $self->_filter_columns,
    $filter,
  );

  $c->stash( rs => $filtered_rs );
}

#-------------------------------------------------------------------------------

# sort the ResultSet
sub _do_sorting : Private {
  my ( $self, $c, $dir, $col_num ) = @_;

  my $sort_column_dir = 'asc';
  my $sort_column_num = 0;

  if ( defined $dir and ( $dir eq 'asc' or $dir eq 'desc' ) ) {
    $sort_column_dir = $dir;
  }

  if ( defined $col_num and $col_num =~ m/^(\d+)$/ ) {
    $sort_column_num = $1;
  }

  my $sort_column_name = $self->_returned_columns->[$sort_column_num];

  $c->log->debug( '_do_sorting: checking that we can sort on column '
                  . "$sort_column_num ($sort_column_name)" )
    if $c->debug;

  # check that the specified column is searchable and orderable, according to
  # the DataTables script
  return unless $c->req->params->{"columns[$sort_column_num][searchable]"} eq 'true';
  return unless $c->req->params->{"columns[$sort_column_num][orderable]"}  eq 'true';

  $c->log->debug( "_do_sorting: sorting $sort_column_dir "
                  . "on column $sort_column_num ($sort_column_name)" )
    if $c->debug;

  my $order = $sort_column_dir eq 'asc'
            ? '-asc'
            : '-desc';

  my $sorted_rs = $c->stash->{rs}->search_rs(
    undef,
    { order_by => { $order => $sort_column_name } }
  );

  $c->stash( rs => $sorted_rs );
}

#-------------------------------------------------------------------------------

# format the sample data for a DataTables table
sub _get_dt_data : Private {
  my ( $self, $c, $draw, $filter ) = @_;

  $c->log->debug( '_get_dt_data: returning data to DataTables' )
    if $c->debug;

  # if we're filtering the dataset, we need to apply the filter to the ResultSet
  # containing all samples, so that we can count how many samples that leaves
  # us with
  if ( defined $filter and $filter ne '' ) {
    $c->log->debug( '_get_dt_data: counting unfiltered rows' )
      if $c->debug;
    my $count_rs = $c->model->schema->filter_rs(
      $c->stash->{full_rs},
      $self->_filter_columns,
      $filter
    );
    $c->stash->{output}->{recordsFiltered} = $count_rs->count;
  }

  # build an array holding all of the rows in the paged, filtered, and sorted
  # ResultSet
  my @samples = ();
  foreach my $row ( $c->stash->{rs}->all ) {
    my $sample = [];
    push @$sample, $row->get_column($_) for @{ $self->_returned_columns };
    push @samples, $sample;
  }

  # build the data structure that we need to return to DataTables on the front
  # end
  $c->stash->{output}->{draw}              = $c->req->params->{draw};
  $c->stash->{output}->{recordsTotal}      = $c->stash->{full_rs}->count;
  $c->stash->{output}->{recordsFiltered} ||= $c->stash->{output}->{recordsTotal};
  $c->stash->{output}->{data}              = \@samples;

  $c->log->debug( '_get_dt_data: built output' )
    if $c->debug;
}

#-------------------------------------------------------------------------------

# format the sample data as a simple JSON data structure
sub _get_raw_data : Private {
  my ( $self, $c ) = @_;

  $c->log->debug( '_get_raw_data: returning raw data' )
    if $c->debug;

  my @samples = ();
  foreach my $row ( $c->stash->{rs}->all ) {
    my %sample = map { $_ => $row->get_column($_) } @{ $self->_returned_columns };
    push @samples, \%sample;
  }

  $c->stash->{output} = \@samples;
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
