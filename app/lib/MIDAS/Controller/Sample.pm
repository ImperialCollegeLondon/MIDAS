
package MIDAS::Controller::Sample;

use Moose;
use namespace::autoclean;

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
              Args(0)
              Does('~NeedsAuth')
              ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->stash(
    template => 'pages/samples.tt',
    samples  => $c->model->schema->get_all_samples
  );
}

#---------------------------------------

sub samples_GET {
  my ( $self, $c ) = @_;

  my $samples = [];

  foreach my $sample ( $c->stash->{samples}->all ) {
    push @$samples,
    {
      sample_id       => $sample->sample_id,
      manifest_id     => $sample->manifest_id,
      scientific_name => $sample->scientific_name,
      tax_id          => $sample->tax_id,
      source          => $sample->collected_at,
      collection_date => $sample->collection_date . '',
      # (force stringification of DateTime objects by concatenating the empty string)
    };
  }

  $self->status_ok(
    $c,
    entity => $samples
  );

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

# sub samples_by_organism : Chained('/')
#                           Args(1)
#                           Does('~NeedsAuth')
#                           ActionClass('REST::ForBrowsers') {
#   my ( $self, $c, $sci_name ) = @_;
#
#
#   $c->stash( samples => $c->model->schema->get_samples_by_sci_name($sci_name);
# }

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

=encoding utf8

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
