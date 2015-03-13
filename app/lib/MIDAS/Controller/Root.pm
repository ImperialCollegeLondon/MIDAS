
package MIDAS::Controller::Root;

use Moose;
use namespace::autoclean;

use Crypt::Mac::HMAC qw(hmac_b64);

BEGIN { extends 'Catalyst::Controller' }

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

MIDAS::Controller::Root - Root Controller for MIDAS

=head1 DESCRIPTION

This controller holds various simple actions, plus the 404 and other
boilerplate actions for the site in general. The actions here shouldn't
require user sign-in.

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    template      => 'pages/index.tt',
    image_credits => 1
  );
}

#-------------------------------------------------------------------------------

=head2 contact

The contact page.

=cut

sub contact : Local Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    breadcrumbs => ['Contact us'],
    template    => 'pages/contact.tt',
    title       => 'Contact us',
  );
}

#-------------------------------------------------------------------------------

=head2 privacy

The privacy page.

=cut

sub privacy : Local Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    breadcrumbs => ['Privacy'],
    template    => 'pages/privacy.tt',
    title       => 'Privacy',
  );
}

#-------------------------------------------------------------------------------

=head2 validation

The validation

=cut

sub validation : Local Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    breadcrumbs => ['Validation'],
    template    => 'pages/validation.tt',
    title       => 'Validation',
  );
}

#-------------------------------------------------------------------------------
#- boilerplate actions ---------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

#-------------------------------------------------------------------------------

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

#-------------------------------------------------------------------------------

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
