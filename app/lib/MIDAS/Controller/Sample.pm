
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
              Args()
              Does('~NeedsAuth')
              ActionClass('REST::ForBrowsers') {
  my ( $self, $c, $organism ) = @_;

  if ( $organism ) {
    $c->log->debug( "returning samples from $organism" )
      if $c->debug;
  }
  else {
    $c->log->debug( "returning all samples" )
      if $c->debug;
  }

  $c->stash(
    template => 'pages/samples.tt',
  );
}

#---------------------------------------

sub samples_GET {
  my ( $self, $c ) = @_;

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

  my $crp = $c->req->params;

  foreach my $param_name ( qw( draw start length order[0][column] ) ) {
    next unless ( defined $crp->{$param_name} and $crp->{$param_name} ne '' );
    die "not a valid value for '$param_name'"
      unless $crp->{$param_name} =~ m/^\d+$/;
  }

  if ( defined $crp->{'search[value]'} and $crp->{'search[value]'} ne '' ) {
    die "not a valid value for search term"
      unless $crp->{'search[value]'} =~ m/^\d+$/;
  }

  if ( defined $crp->{'order[dir]'} and $crp->{'order[dir]'} ne '' ) {
    die "not a valid value for search direction"
      unless ( $crp->{'order[dir]'} eq 'asc' or
               $crp->{'order[dir]'} eq 'desc' );
  }

  $c->stash(
    params           => $crp,
    returned_columns => [
      qw(
        sample_id
        manifest_id
        scientific_name
        tax_id
        collection_date
        collected_at
      )
    ],
    filter_columns => [
      qw(
        manifest_id
        scientific_name
        tax_id
        collection_date
        collected_at
      )
    ]
  );

  # we can take advantage of DBIC here by simply stacking up the modifications
  # to the query and letting it build a final SQL query that encompasses all of
  # them. The paging query has to be first, because it uses an API call to get
  # the ResultSet for the specified rows
  $c->forward('_do_paging');
  $c->forward('_do_filtering');
  $c->forward('_do_sorting');

  # if the response is going to a DataTable, we need to format it differently
  # and add extra information. Either way, we simply stash the output and let
  # Catalyst::Controller::REST take care of serialising it
  if ( $crp->{_dt} ) {
    $c->forward('_get_dt_data');
  }
  else {
    $c->forward('_get_raw_data');
  }
}

#-------------------------------------------------------------------------------

# retrieve a ResultSet containing the specified rows
sub _do_paging : Private {
  my ( $self, $c ) = @_;

  my $from = $c->stash->{params}->{start};
  my $to   = $c->stash->{params}->{start} + $c->stash->{params}->{length} - 1;

  $c->log->debug( "_do_paging: retrieving rows $from - $to" )
    if $c->debug;

  $c->stash( rs => $c->model->schema->get_samples($from, $to) );
}

#-------------------------------------------------------------------------------

# filter the resultset
sub _do_filtering : Private {
  my ( $self, $c ) = @_;

  return unless defined $c->stash->{params}->{'search[value]'};
  return if     $c->stash->{params}->{'search[value]'} eq '';

  $c->log->debug( '_do_filtering: retrieving rows matching |'
                  . $c->stash->{params}->{'search[value]'} . '|' )
    if $c->debug;

  # apply the filter to the range ResultSet, so that we end up with the set
  # of filtered samples
  my $filtered_rs = $c->model->schema->filter_rs(
    $c->stash->{rs},
    $c->stash->{filter_columns},
    $c->stash->{params}->{'search[value]'}
  );

  $c->stash( rs => $filtered_rs );
}

#-------------------------------------------------------------------------------

# sort the ResultSet
sub _do_sorting : Private {
  my ( $self, $c ) = @_;

  my $sort_column_dir  = $c->stash->{params}->{'order[0][dir]'};
  my $sort_column_num  = $c->stash->{params}->{'order[0][column]'};
  my $sort_column_name = $c->stash->{returned_columns}->[$sort_column_num];

  $c->log->debug( '_do_sorting: checking that we can sort on column '
                  . "$sort_column_num ($sort_column_name)" )
    if $c->debug;

  # check that the specified column is searchable and orderable, according to
  # the DataTables script
  return unless $c->req->params->{"columns[$sort_column_num][searchable]"} eq 'true';
  return unless $c->req->params->{"columns[$sort_column_num][orderable]"} eq 'true';

  $c->log->debug( "_do_sorting: sorting on column $sort_column_num ($sort_column_name)" )
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
  my ( $self, $c ) = @_;

  $c->log->debug( '_get_dt_data: returning data to DataTables' )
    if $c->debug;

  # if we're filtering the dataset we need to apply the filter to the ResultSet
  # containing all samples, so that we can count how many samples that leaves
  # us with
  if ( defined $c->stash->{params}->{'search[value]'} and
       $c->stash->{params}->{'search[value]'} ne '' ) {
    $c->log->debug( '_get_dt_data: counting unfiltered rows' )
      if $c->debug;
    my $count_rs = $c->model->schema->filter_rs(
      $c->model->schema->get_all_samples,
      $c->stash->{filter_columns},
      $c->stash->{params}->{'search[value]'}
    );
    $c->stash->{output}->{recordsFiltered} = $count_rs->count;
  }

  my @samples = ();
  foreach my $row ( $c->stash->{rs}->all ) {
    my $sample = [];
    push @$sample, $row->get_column($_) for @{ $c->stash->{returned_columns} };
    push @samples, $sample;
  }

  # build the data structure that we need to return to DataTables on the front
  # end
  $c->stash->{output}->{draw}              = $c->stash->{params}->{draw};
  $c->stash->{output}->{recordsTotal}      = $c->model->schema->get_all_samples->count;
  $c->stash->{output}->{recordsFiltered} ||= $c->stash->{output}->{recordsTotal};
  $c->stash->{output}->{data}              = \@samples;

  $c->log->debug( '_get_rt_data: built output' )
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
    my %sample = map { $_ => $row->get_column($_) } @{ $c->stash->{returned_columns} };
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
