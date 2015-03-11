
package MIDAS::Controller::Account;

use Moose;
use namespace::autoclean;

use TryCatch;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

MIDAS::Controller::User - Catalyst Controller to handle various user
account-related actions

=head1 DESCRIPTION

This is a L<Catalyst::Controller> to handle actions related to user accounts,
such as password reset, etc.

=cut

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 account

Stub for chains related to user accounts.

Enforces authentication by 'doing' C<NeedsLogin>.

=cut

sub account : Chained('/')
              PathPart('account')
              CaptureArgs(0)
              Does('NeedsLogin') { }

#-------------------------------------------------------------------------------

=head2 account

Page showing forms for resetting password and API key.

=cut

sub account_page : Chained('account')
                   PathPart('')
                   Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    jscontroller => 'account',
    template     => 'pages/reset.tt',
    title        => 'Account management'
  );
}

#-------------------------------------------------------------------------------

=head2 reset_password

Reset the password to the given value for the currently signed-in user.

=cut

sub reset_password : Chained('account')
                     PathPart('resetpassword')
                     Args(0) {
  my ( $self, $c ) = @_;

  # this action is only going to return JSON
  $c->stash( current_view => 'JSON' );

  $c->log->debug( 'Account::reset_password: resetting password...' )
    if $c->debug;

  my $old_pass  = $c->req->param('oldpass');
  my $new_pass1 = $c->req->param('newpass1');
  my $new_pass2 = $c->req->param('newpass2');

  unless ( defined $old_pass  and $old_pass  ne '' and
           defined $new_pass1 and $new_pass1 ne '' and
           defined $new_pass2 and $new_pass2 ne '' ) {
    $c->stash( json_data => { error => 'You must enter all three passwords' } );
    $c->res->status(400); # Bad request
    return;
  }

  $c->log->debug( 'Account::reset_password: got all passwords' )
    if $c->debug;

  my $user = $c->user->get_object;

  unless ( $user->check_password($old_pass) ) {
    $c->stash( json_data => { error => 'Invalid password. Please try again' } );
    $c->res->status(400); # Bad request
    return;
  }

  $c->log->debug( 'Account::reset_password: old password is valid' )
    if $c->debug;

  unless ( $new_pass1 eq $new_pass2 ) {
    $c->stash( json_data => { error => 'New passwords did not match' } );
    $c->res->status(400); # Bad request
    return;
  }

  $c->log->debug( 'Account::reset_password: new passwords match' )
    if $c->debug;

  unless ( length $new_pass1 > 7 ) {
    $c->stash( json_data => { error => 'New password must be at least 8 characters long' } );
    $c->res->status(400); # Bad request
    return;
  }

  try {
    $user->set_passphrase($new_pass1);
  } catch ($e) {
    $c->stash( json_data => { error => 'We could not set your new password' } );
    $c->res->status(500); # Internal server error
    return;
  }

  $c->log->debug( 'Account::reset_password: successfully changed password' )
    if $c->debug;

  $c->stash( json_data => { message => 'Your password has been changed' } );
}

#-------------------------------------------------------------------------------

=head2 reset_key

Reset the API key (generate a new one) for the currently signed-in user.

=cut

sub reset_key : Chained('account')
                PathPart('resetkey')
                Args(0) {
  my ( $self, $c ) = @_;

  # this action is only going to return JSON
  $c->stash( current_view => 'JSON' );

  $c->log->debug( 'Account::reset_key resetting API key...' )
    if $c->debug;

  my $user = $c->user->get_object;

  my $password = $c->req->param('password');

  unless ( defined $password and $password ne '' ) {
    $c->stash( json_data => { error => 'You must enter your current password' } );
    $c->res->status(400); # Bad request
    return;
  }

  $c->log->debug( 'Account::reset_key: got password' )
    if $c->debug;

  unless ( $user->check_password($password) ) {
    $c->stash( json_data => { error => 'Invalid password. Please try again' } );
    $c->res->status(400); # Bad request
    return;
  }

  $c->log->debug( 'Account::reset_key: password is valid' )
    if $c->debug;

  my $new_key;
  try {
    $new_key = $user->reset_api_key;
  } catch ($e) {
    $c->stash( json_data => { error => 'We could not reset your API key' } );
    $c->res->status(500); # Internal server error
    return;
  }

  $c->log->debug( 'Account::reset_key: successfully changed API key' )
    if $c->debug;

  $c->stash(
    json_data => { message => 'Your API key has been reset', key => $new_key }
  );
}

#-------------------------------------------------------------------------------

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

#-------------------------------------------------------------------------------
#- private actions -------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 validate_hmac

Retrieves an HMAC from the C<Authorization> header of a RESTful request and
validates it.

=cut

sub validate_hmac : Private {
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

=encoding utf8

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
