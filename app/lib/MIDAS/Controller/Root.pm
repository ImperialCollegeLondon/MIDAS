package MIDAS::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=encoding utf-8

=head1 NAME

MIDAS::Controller::Root - Root Controller for MIDAS

=head1 DESCRIPTION

[enter your description here]

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index : Path Args(0) {
  my ( $self, $c ) = @_;

  $c->stash( template => 'pages/index.tt' );
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
#- protected actions -----------------------------------------------------------
#-------------------------------------------------------------------------------

sub secret : Local Does('NeedsLogin') {
  my ( $self, $c ) = @_;

  $c->stash( template => 'pages/secret.tt' );
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
