
package MIDAS::Controller::Manifest;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MIDAS::Base::Controller::Restful' }

=head1 NAME

MIDAS::Controller::Manifest - Catalyst Controller to handle manifest data

=head1 DESCRIPTION

Catalyst Controller.

=cut

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 manifests : Chained('/') Args(0) Does('NeedsAuth') ActionClass('REST::ForBrowsers')

Returns information for all manifests.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub manifests : Chained('/')
                Args(0)
                Does('NeedsAuth')
                ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;

  $c->stash( manifests => [ $c->model('HICFDB::Manifest')->all ] );
}

#---------------------------------------

sub manifests_GET {
  my ( $self, $c ) = @_;

  my $manifests = [];

  foreach my $manifest ( @{ $c->stash->{manifests} } ) {
    push @$manifests,
    {
      manifest_id => $manifest->manifest_id,
      created     => $manifest->created_at
    };
  }

  $self->status_ok(
    $c,
    entity => $manifests
  );
}

#---------------------------------------

sub manifests_GET_html {
  my ( $self, $c ) = @_;
  $c->stash( template => 'pages/manifests.tt' );
}

#-------------------------------------------------------------------------------

=head2 manifest : Chained('/') Args(1) Does('NeedsAuth') ActionClass('REST::ForBrowsers')

Returns sample information. Captures a single argument, the ID of the sample.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub manifest : Chained('/')
               Args(1)
               Does('NeedsAuth')
               ActionClass('REST::ForBrowsers') {}

#---------------------------------------

before manifest => sub {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "before manifest AUTHENTICATED; retrieving sample data for '$id'" )
    if $c->debug;

  # at this point the user is authenticated, either via login or session if the
  # request came from a browser, or via an HMAC in the "Authorization" header

  my $manifest = $c->model('HICFDB::Manifest')
                   ->find( { manifest_id => $id } );

  if ( defined $manifest ) {
    $c->log->debug( 'before manifest: stashing manifest row' )
      if $c->debug;
    $c->stash( id       => $id,
               manifest => $manifest );
  }
  else {
    $c->log->warn( 'before manifest: no such manifest; stashing error message' )
      if $c->debug;
    $c->stash( id    => $id,
               error => 'no such manifest' );
  }
};

#---------------------------------------

# return sample data to a browser

sub manifest_GET_html {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "manifest_GET_html: request for manifest '$id' came from a browser" )
    if $c->debug;

  $c->stash( template => 'pages/manifest.tt' );
}

#---------------------------------------

# return sample data to a non-browser client

sub manifest_GET {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "manifest_GET: request for manifest '$id' did not come from a browser" )
    if $c->debug;

  if ( defined $c->stash->{manifest} ) {
    $self->status_ok(
      $c,
      entity => $c->stash->{manifest}->get_fields
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
