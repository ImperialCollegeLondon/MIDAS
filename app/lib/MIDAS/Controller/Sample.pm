
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

  my $samples_rs = $c->model('HICFDB::Sample')->search(
    {},
    {
      join     => [qw( geolocation location_description )],
      prefetch => [qw( geolocation location_description )]
    }
  );

  $c->stash( samples => $samples_rs );
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
      location        => $sample->location_description->description,
      collection_date => $sample->collection_date . '',
      # (force stringification of DateTime objects by concatenating the empty string)
      source          => $sample->collected_at,
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
    template     => 'pages/samples.tt',
    title        => 'Samples',
    jscontroller => 'samples'
  );
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
             ActionClass('REST::ForBrowsers') {}

#---------------------------------------

before sample => sub {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "before sample: AUTHENTICATED; retrieving sample data for '$id'" )
    if $c->debug;

  # at this point the user is authenticated, either via login or session if the
  # request came from a browser, or via an HMAC in the "Authorization" header

  my $sample = $c->model('HICFDB::Sample')
                 ->find( { sample_id => $id } );

  if ( defined $sample ) {
    $c->log->debug( 'before sample: stashing sample row' )
      if $c->debug;
    $c->stash( id     => $id,
               sample => $sample );
  }
  else {
    $c->log->warn( 'before sample: no such sample; stashing error message' )
      if $c->debug;
    $c->stash( id    => $id,
               error => 'no such sample' );
  }
};

#---------------------------------------

# return sample data to a browser

sub sample_GET_html {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "sample_GET_html: request for sample '$id' came from a browser" )
    if $c->debug;

  $c->stash( template => 'pages/sample.tt' );
}

#---------------------------------------

# return sample data to a non-browser client

sub sample_GET {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "sample_GET: request for sample '$id' did not come from a browser" )
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
