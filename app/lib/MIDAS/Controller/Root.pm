
package MIDAS::Controller::Root;

use Moose;
use namespace::autoclean;

use TryCatch;
use Crypt::Mac::HMAC qw(hmac_b64);

BEGIN { extends 'Catalyst::Controller' }

# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
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

  $c->stash( template      => 'pages/index.tt',
             image_credits => 1 );
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

sub validate_hmac : Global {
  my ( $self, $c ) = @_;

  $c->log->debug( 'validate_hmac: looking for an HMAC in the Authorization header' )
    if $c->debug;

  # first, we must have an Authorization header
  my $auth_header = $c->req->header('Authorization');

  if ( not defined $auth_header ) {
    $c->log->error( 'validate_hmac: no authorization header' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Must supply HMAC via "Authorization" header');
    $c->detach;
    return;
  }

  # next, the header should look like:
  # Authorization: hmac <username>:[digest]
  unless ( $auth_header =~ m/^hmac (\w+)\:(.*?)$/ ) {
    $c->log->error( 'validate_hmac: malformed authorization header' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Must supply HMAC via "Authorization" header');
    $c->detach;
    return;
  }

  my $username         = $1;
  my $submitted_digest = $2;

  # finally, the user must exist in the database
  my $user = $c->model('HICFDB::User')->find($username);

  unless ( defined $user ) {
    $c->log->error( 'validate_hmac: no such user' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Unauthorized');
    $c->detach;
    return;
  }

  # the digest is calculated as
  # b64encode( hmac( 'sha256', '<API key>', '<VERB>+<URI>' ))

  my $method  = $c->req->method;
  my $uri     = $c->req->uri;
  my $api_key = $user->api_key;

  # this shouldn't happen in production, since we'll give every user an API key
  # when we set up their account, but at least for testing it will stop some
  # ugly error messages
  unless ( defined $api_key ) {
    $c->log->warn( 'validate_hmac: no API key for user' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Unauthorized');
    $c->detach;
    return;
  }

  # just to tidy things up still more...
  my $calculated_digest;
  try {
    $calculated_digest = hmac_b64( 'SHA256', $api_key, "${method}+${uri}" );
  } catch ($e) {
    $c->log->error( 'validate_hmac: exception when generating HMAC' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Unauthorized');
    $c->detach;
    return;
  }

  # and, finally, check the user's digest against our own
  unless ( $submitted_digest eq $calculated_digest ) {
    $c->log->error( 'validate_hmac: submitted digest does not match calculated digest' )
      if $c->debug;
    $c->res->status(401); # Unauthorized
    $c->res->body('Unauthorized');
    $c->detach;
    return;
  }

  $c->log->debug( 'validate_hmac: found a valid digest; serving URL' )
    if $c->debug;

  # flag this request as having a valid HMAC, so that we can avoid validating
  # twice with RESTful actions
  $c->stash( hmac_validated => 1 );
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
#- private actions -------------------------------------------------------------
#-------------------------------------------------------------------------------

# none yet

#-------------------------------------------------------------------------------

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
