
package MIDAS::Controller::Sample;

use Moose;
use namespace::autoclean;

use Try::Tiny;

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
has 'returned_columns' => (
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
#- samples for all organisms ---------------------------------------------------
#-------------------------------------------------------------------------------

=head2 samples : Chained('/') Args(0) Does('~NeedsAuth')

This is the beginning of a chain that returns information for samples from all
organisms. It sets up parameters that are applicable to the actions that format
sample data, and sets a couple of stash parameters that are generally useful.

Requires login (for requests from a browser) or "Authorization" header (for
REST calls).

=cut

sub samples : Chained('/')
              PathPart('samples')
              CaptureArgs(0)
              Does('~NeedsAuth') {
  my ( $self, $c ) = @_;

  # go and get the request parameters that are used by the actions that format
  # data for DataTables or REST requests
  $c->forward('_stash_params');

  # stash two copies of the full, starting dataset. One, "rs", will be paged,
  # filtered and sorted, while the other will be kept untouched and used to
  # calculate things like the number of samples in the whole dataset.
  #
  # DBIC is (hopefully) smart enough not to instantiate the object or run the
  # query to retrieve all samples unless requested, so at this point we're just
  # storing a reference to a small DBIC object that doesn't contain any data.

  $c->stash(
    title        => 'Samples',
    template     => 'pages/samples.tt',
    jscontroller => 'samples',
    rs           => $c->model->schema->get_all_samples,
    full_rs      => $c->model->schema->get_all_samples,
  );

  $c->log->debug( 'samples: returning data for samples from all organisms' )
    if $c->debug;

  # flag the response for download if the "dl" param is set
  $c->res->header('Content-disposition', qq(attachment; filename="samples"))
    if $c->req->params->{dl};
}

#-------------------------------------------------------------------------------

=head2 all_samples : Chained('samples') PathPath('') Args(0) ActionClass('REST::ForBrowsers')

This is an end-point for a chain that returns information for all samples. It
defers to two methods, C<all_samples_GET> to return information for a REST
client, and C<all_samples_GET_html> for a browser.

=cut

sub all_samples : Chained('samples')
                  PathPart('')
                  Args(0)
                  ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->log->debug( 'all_samples: returning all samples' )
    if $c->debug;
}

#---------------------------------------

sub all_samples_GET {
  my ( $self, $c ) = @_;

  try {
    $c->forward('_format_sample_data' );
    $self->status_ok(
      $c,
      entity => $c->stash->{output}
    );
  } catch {
    $self->status_ok(
      $c,
      entity => { error => $_ }
    );
  };

  $c->log->debug( 'all_samples_GET: returning raw data' )
    if $c->debug;
}

#---------------------------------------

sub all_samples_GET_html {
  my ( $self, $c ) = @_;

  $c->log->debug( 'all_samples_GET_html: returning HTML page' )
    if $c->debug;
}

#-------------------------------------------------------------------------------

=head2 paged_samples : Chained('samples') PathPath('') Args(2) ActionClass('REST::ForBrowsers')

This is an end-point for a chain that returns information for samples from a
specific organism. It defers to two methods, C<paged_samples_GET> to return
information for a REST client, and C<paged_samples_GET_html> for a browser.

Samples are always ordered by ascending sample ID.

=cut

sub paged_samples : Chained('samples')
                    PathPart('')
                    Args(2)
                    ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->log->debug( 'paged_samples: returning a subset of samples' )
    if $c->debug;
}

#---------------------------------------

sub paged_samples_GET {
  my ( $self, $c, $start, $length ) = @_;

  # make sure the page limits are valid
  foreach my $limit ( $start, $length ) {
    unless ( $limit =~ m/^\d+$/ ) {
      $self->status_bad_request(
        $c,
        message => 'not a valid range (from/to)'
      );
      return;
    }
  }

  $c->stash->{format_params}->{start}  = $start;
  $c->stash->{format_params}->{length} = $length;

  try {
    $c->forward('_format_sample_data');
    $self->status_ok(
      $c,
      entity => $c->stash->{output}
    );
  } catch {
    $self->status_ok(
      $c,
      entity => { error => $_ }
    );
  };
  $c->log->debug( 'paged_samples_GET: returning raw data' )
    if $c->debug;
}

#---------------------------------------

sub paged_samples_GET_html {
  my ( $self, $c ) = @_;

  $c->log->debug( 'paged_samples_GET_html: returning HTML' )
    if $c->debug;
}

#-------------------------------------------------------------------------------
#- samples for one organism ----------------------------------------------------
#-------------------------------------------------------------------------------

=head2 samples_from_organism : Chained('/') CaptureArgs(0) Does('~NeedsAuth')

This is the beginning of a chain that returns information for samples from
specific organisms. It sets up parameters that are applicable to the actions
that format sample data, and sets a couple of stash parameters that are
generally useful.

Requires login (for requests from a browser) or "Authorization" header (for
REST calls).

=cut

# this is patterned on "sub samples". See that action for comments too

sub samples_from_organism : Chained('/')
                            PathPart('samples_from_organism')
                            CaptureArgs(1)
                            Does('~NeedsAuth') {
  my ( $self, $c, $organism ) = @_;

  # I started building a regex to detaint the organism name, but the scientific
  # names in the NCBI taxonomy appear to contain every non-word character in
  # the lexicon, with the exception of pipe ("|"), which they use as a
  # separator in "names.dmp", and maybe angle-brackets. White-listing would end
  # up looking something like:
  #
  #   unless ( $tainted_organism =~ m|^([\w\s\.-;:'"/%\*^()[]{}\?\&\#]+)$| ) {
  #     ...
  #   }
  #
  # Basically, there's not a lot of point in trying to validate this beyond the
  # simplest of checks. We'll just hope that DBIC does a good job of escaping
  # everything before it hits the DB

  if ( $organism =~ m/[\<\>\|]/ ) {
    # amazingly, the organism name is not valid
    $c->stash(
      title        => 'Samples',
      template     => 'pages/samples.tt',
      jscontroller => 'samples',
      error        => 'Not a valid organism name',
    );
    return;
  }

  $c->forward('_stash_params');

  $c->stash(
    title        => 'Samples from $organism',
    template     => 'pages/samples.tt',
    jscontroller => 'samples',
    rs           => $c->model->schema->get_all_samples_from_organism($organism),
    full_rs      => $c->model->schema->get_all_samples_from_organism($organism),
    organism     => $organism,
  );

  $c->log->debug( "samples_by_organism: looking for samples from |$organism|" )
    if $c->debug;

  # flag the response for download if the "dl" param is set
  $c->res->header('Content-disposition', qq(attachment; filename="${organism}_samples"))
    if $c->req->params->{dl};
}

#-------------------------------------------------------------------------------

sub all_samples_from_organism : Chained('samples_from_organism')
                                PathPart('')
                                Args(0)
                                ActionClass('REST::ForBrowsers') { }

#---------------------------------------

sub all_samples_from_organism_GET {
  my ( $self, $c ) = @_;

  # throw an error if there was a problem validating the organism name
  if ( defined $c->stash->{error} or
       not defined $c->stash->{organism} ) {
    $self->status_bad_request(
      $c,
      message => $c->stash->{error} || 'No such organism'
    );
    return;
  }

  try {
    $c->forward('_format_sample_data');
    $self->status_ok(
      $c,
      entity => $c->stash->{output}
    );
  } catch {
    $self->status_ok(
      $c,
      entity => { error => $_ }
    );
  };

  $c->log->debug( 'all_samples_from_organism_GET: returning raw data' )
    if $c->debug;
}

#---------------------------------------

sub all_samples_from_organism_GET_html {
  my ( $self, $c ) = @_;

  $c->log->debug( 'all_samples_from_organism_GET_html: returning HTML page' )
    if $c->debug;
}

#-------------------------------------------------------------------------------

sub paged_samples_from_organism : Chained('samples_from_organism')
                                  PathPart('')
                                  Args(2)
                                  ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->log->debug( 'paged_samples_from_organism: returning subset of samples from '
                  . $c->stash->{organism} )
    if $c->debug;
}

#---------------------------------------

sub paged_samples_from_organism_GET {
  my ( $self, $c, $start, $length ) = @_;

  # make sure the page limits are valid
  foreach my $limit ( $start, $length ) {
    unless ( $limit =~ m/^\d+$/ ) {
      $self->status_bad_request(
        $c,
        message => 'not a valid range (from/to)'
      );
      return;
    }
  }

  $c->stash->{format_params}->{start}  = $start;
  $c->stash->{format_params}->{length} = $length;

  try {
    $c->forward('_format_sample_data');
    $self->status_ok(
      $c,
      entity => $c->stash->{output}
    );
  } catch {
    $self->status_ok(
      $c,
      entity => { error => $_ }
    );
  };

  $c->log->debug( 'paged_samples_from_organism_GET: returning raw data' )
    if $c->debug;
}

#---------------------------------------

sub paged_samples_from_organism_GET_html {
  my ( $self, $c ) = @_;

  $c->log->debug( 'paged_samples_from_organism_GET_html: returning HTML page' )
    if $c->debug;
}

#-------------------------------------------------------------------------------
#- single sample ---------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 sample : chained('/') args(1) does('~needsauth') actionclass('rest::forbrowsers')

returns sample information. captures a single argument, the id of the sample.

requires login (for requests from a browser) or hmac authentication (for
rest calls).

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

# looks at the request parameters and pulls out those that are relevant to/used
# by methods in this controller
sub _stash_params : Private {
  my ( $self, $c ) = @_;

  $c->log->debug( '_stash_params: storing parameters' )
    if $c->debug;

  # we need to handle filter terms coming from either DataTables or from
  # the download link that we build in the page
  my $tainted_filter_term = $c->req->params->{'search[value]'} ||
                            $c->req->params->{filter} ||
                            '';
  my $filter_term;
  if ( $tainted_filter_term =~ m/^([\w\-]+)$/ ) {
    $filter_term = $1;
  }

  # we're only accepting sort params from DataTables
  my $sort_column_num = $c->req->params->{'order[0][column]'};
  my $sort_column_dir = $c->req->params->{'order[0][dir]'};

  # "draw" must be an integer. It's not clear what happens if we return 0 as a
  # fall-back but it's better than returning user-specified junk
  my $draw = $c->req->params->{draw} || 0;
  $draw = 0 unless $draw =~ m/^\d+$/;

  # "start" and "length" page limits. Again, must be integers, but we don't
  # want to set defaults, because then everything would be trimmed to that
  # specified subset of samples. Instead we leave the values of $start and
  # $length undefined, and the "_do_paging" action will simply not try to page
  # the results
  my ( $start, $length );
  if ( defined $c->req->params->{start} and
       $c->req->params->{start} =~ m/^(\d+)$/ ) {
    $start = $1;
  }
  if ( defined $c->req->params->{length} and
       $c->req->params->{length} =~ m/^(\d+)$/ ) {
    $length = $1;
  }

  # these are parameters that will be handed to the actions that format the
  # data, either for display or for downloading in raw JSON format (or whatever
  # is specified by the content-type URI param)
  my $format_params = {
    filter_term     => $filter_term,
    sort_column_num => $sort_column_num,
    sort_column_dir => $sort_column_dir,
    draw            => $draw,
    start           => $start,
    length          => $length,
  };

  $c->stash( format_params => $format_params );
}

#-------------------------------------------------------------------------------

# return data for a set of samples
sub _format_sample_data : Private {
  my ( $self, $c ) = @_;

  die 'no resultset to work with'      unless defined $c->stash->{rs};
  die 'no full resultset to work with' unless defined $c->stash->{full_rs};

  # we can take advantage of DBIC here by simply stacking up the modifications
  # to the query and letting it build a final SQL query that encompasses all of
  # them
  $c->forward('_do_paging');
  $c->forward('_do_filtering');
  $c->forward('_do_sorting');

  # if the response is going to a DataTable, we need to format it differently
  # and add extra information. Either way, we simply stash the output and let
  # Catalyst::Controller::REST take care of serialising it
  if ( $c->req->params->{_dt} ) {
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

  my $start  = $c->stash->{format_params}->{start};
  my $length = $c->stash->{format_params}->{length};

  $c->log->debug( '_do_paging: checking bounds...' )
    if $c->debug;

  # DataTables tells us the range that it wants as "start/length", while DBIC
  # selects its ranges as "from - to". This is where the conversion happens

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
  my ( $self, $c ) = @_;

  my $filter_term = $c->stash->{format_params}->{filter_term};

  return if not defined $filter_term;
  return if $filter_term eq '';

  $c->log->debug( "_do_filtering: retrieving rows matching |$filter_term|" )
    if $c->debug;

  # apply the filter to the range ResultSet, so that we end up with the set
  # of filtered samples
  my $filtered_rs = $c->model->schema->filter_rs(
    $c->stash->{rs},
    $self->_filter_columns,
    $filter_term,
  );

  $c->stash( rs => $filtered_rs );
}

#-------------------------------------------------------------------------------

# sort the ResultSet
sub _do_sorting : Private {
  my ( $self, $c ) = @_;

  # defaults - if the specified sort params aren't valid, for the sake of
  # consistency we'll still get DBIC to order the dataset using these defaults
  my $sort_column_dir = '-asc';
  my $sort_column_num = 0;

  my $dir     = $c->stash->{format_params}->{sort_column_dir};
  my $col_num = $c->stash->{format_params}->{sort_column_num};

  if ( defined $dir and ( $dir eq 'asc' or $dir eq 'desc' ) ) {
    # add "-" to make the term into a valid direction for DBIC
    $sort_column_dir = "-$dir";
  }

  if ( defined $col_num and $col_num =~ m/^(\d+)$/ ) {
    $sort_column_num = $1;
  }

  my $sort_column_name = $self->returned_columns->[$sort_column_num];

  $c->log->debug( "_do_sorting: checking that we're allowed to sort on column "
                  . $sort_column_num )
    if $c->debug;

  # check that the specified column is searchable and orderable, according to
  # the DataTables script. This is enforced to prevent DataTables having to
  # try to display badly ordered data, rather than as a security measure. The
  # database will happily order the dataset on any column...
  return unless ( defined $c->req->params->{"columns[$sort_column_num][searchable]"} and
                  $c->req->params->{"columns[$sort_column_num][searchable]"} eq 'true' );
  return unless ( defined $c->req->params->{"columns[$sort_column_num][orderable]"} and
                  $c->req->params->{"columns[$sort_column_num][orderable]"}  eq 'true' );

  $c->log->debug( "_do_sorting: sorting $sort_column_dir "
                  . "on column $sort_column_num ($sort_column_name)" )
    if $c->debug;

  # we need to prefix the column name with "me", otherwise, because we're
  # joining the "sample" table to "antimicrobial_resistance", columns like
  # "sample_id" will be ambiguous and will cause errors in the RDBMS
  my $sorted_rs = $c->stash->{rs}->search_rs(
    undef,
    { order_by => { $sort_column_dir => "me.$sort_column_name" } }
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
  my $filter_term = $c->stash->{format_params}->{filter_term};

  if ( defined $filter_term and $filter_term ne '' ) {
    $c->log->debug( '_get_dt_data: counting unfiltered rows' )
      if $c->debug;
    my $count_rs = $c->model->schema->filter_rs(
      $c->stash->{full_rs},
      $self->_filter_columns,
      $filter_term,
    );
    $c->stash->{output}->{recordsFiltered} = $count_rs->count;
  }

  # build an array holding all of the rows in the paged, filtered, and sorted
  # ResultSet
  $c->forward('_munge_rs');

  # build the data structure that we need to return to DataTables on the front
  # end
  $c->stash->{output}->{draw}              = $c->stash->{format_params}->{draw};
  $c->stash->{output}->{recordsTotal}      = $c->stash->{full_rs}->count;
  $c->stash->{output}->{recordsFiltered} ||= $c->stash->{output}->{recordsTotal};
  $c->stash->{output}->{data}              = $c->stash->{samples};

  $c->log->debug( '_get_dt_data: built output' )
    if $c->debug;
}

#-------------------------------------------------------------------------------

# convert the ResultSet into a data structure that we can serialise
sub _munge_rs : Private {
  my ( $self, $c ) = @_;

  my @samples = ();
  foreach my $row ( $c->stash->{rs}->all ) {
    my $sample = [];
    push @$sample, $row->get_column($_) for @{ $self->returned_columns };

    my $amr_data = [];
    push @$amr_data, { $_->get_columns } for $row->get_amr->all;
    push @$sample, $amr_data;

    push @samples, $sample;
  }

  $c->stash( samples => \@samples );
}

#-------------------------------------------------------------------------------

# format the sample data as a simple JSON data structure
sub _get_raw_data : Private {
  my ( $self, $c ) = @_;

  $c->log->debug( '_get_raw_data: returning raw data' )
    if $c->debug;

  # TODO switch to using "_munge_rs"
  my @samples = ();
  foreach my $row ( $c->stash->{rs}->all ) {
    my %sample = map { $_ => $row->get_column($_) } @{ $self->returned_columns };
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
