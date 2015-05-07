
package MIDAS::Controller::Account;

use Moose;
use namespace::autoclean;

use Try::Tiny;

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

=head2 account : Chained('/') PathPart('account') Does('~NeedsAuth') CaptureArgs(0)

Stub for chains related to user accounts.

Enforces authentication by 'doing' C<NeedsLogin>.

=cut

sub account : Chained('/')
              PathPart('account')
              Does('~NeedsAuth')
              CaptureArgs(0) { }

#-------------------------------------------------------------------------------

=head2 account_page : Chained('account') PathPart('') Args(0)

Page showing forms for resetting password and API key.

=cut

sub account_page : Chained('account')
                   PathPart('')
                   Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    breadcrumbs => ['Account'],
    jscontroller => 'account',
    template     => 'pages/reset.tt',
    title        => 'Account management'
  );
}

#-------------------------------------------------------------------------------

=head2 reset_password : Chained('account') PathPart('resetpassword') Args(0)

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
  } catch {
    $c->stash( json_data => { error => 'We could not set your new password' } );
    $c->res->status(500); # Internal server error
    return;
  };

  $c->log->debug( 'Account::reset_password: successfully changed password' )
    if $c->debug;

  # store updated user information
  $c->persist_user;

  $c->stash( json_data => { message => 'Your password has been changed' } );
}

#-------------------------------------------------------------------------------

=head2 reset_key : Chained('account') PathPart('resetkey') Args(0)

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
  } catch {
    $c->stash( json_data => { error => 'We could not reset your API key' } );
    $c->res->status(500); # Internal server error
    return;
  };

  $c->log->debug( 'Account::reset_key: successfully changed API key' )
    if $c->debug;

  # store updated user information
  $c->persist_user;

  $c->stash(
    json_data => { message => 'Your API key has been reset', key => $new_key }
  );
}

#-------------------------------------------------------------------------------

=head2 end : ActionClass('RenderView')

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

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
