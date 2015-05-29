use utf8;
package MIDAS::ActionRole::NeedsAuth;

# ABSTRACT: ActionRole to enforce authentication for both browsers and REST API users

use Moose::Role;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

use DateTime;
use Try::Tiny;
use File::Write::Rotate;

=head1 NAME

MIDAS::ActionRole::NeedsAuth - enforce authentication for browser and REST API users

=head1 SYNOPSIS

 sub secret : Path Does('NeedsAuth') {
   my ( $self, $c ) = @_;

   $c->res->body( 'something secret' );
 }

=head1 DESCRIPTION

This is a Catalyst L<Catalyst::Manual::Actions#ACTION-ROLES|ActionRole> that
provides a decorator, "C<NeedsAuth>", to enforce authentication for actions
that return privileged information.

If the request comes from a browser, the user will be redirected to the login
page, unless they're already logged in.

If the request is programmatic, i.e. it's a request on the RESTful API, the
request must have the C<Authentication> header and that header must supply a
valid HMAC.  See L<MIDAS::Root::validate_hmac>.

=cut

#-------------------------------------------------------------------------------
#- private attributes ----------------------------------------------------------
#-------------------------------------------------------------------------------

# in order to avoid doing authentication twice for REST requests, keep track
# of the request object
has '_previous_request' => (
  is      => 'rw',
  isa     => 'Object',
  default => sub { bless {}, 'Object' },
);

# store a reference to the configuration for the audit log writer. This is
# set when we're processing a request, at which point we can pull the config
# out of the context object, $c.
has '_audit_log_config' => (
  is      => 'rw',
  isa     => 'HashRef',
  default => sub { {} },
);

# I can't find a way to make parameters from the config available in this
# "default" method. They're not accessible via $self and we don't have $c at
# this point. The workaround is to set an attribute on the role every time we
# need to write a log message, so that we can then lazily instantiate the log
# writer.
has '_audit_logger' => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    my $al   = $self->_audit_log_config;
    return File::Write::Rotate->new(%$al);
  },
);

#-------------------------------------------------------------------------------
#- public actions --------------------------------------------------------------
#-------------------------------------------------------------------------------

=head1 ACTIONS

=head2 execute

An 'around' modifier for the C<execute> method. For browser-based requests
where the user is not already logged in, we redirect to the login action and
let it take care of authenticating the browser and forwarding on to the
requested action. For non-browser-based requests we check the C<Authorization>
header and validate the username/API key found there. If the API key is valid,
we forward to the requested action.

For REST requests, this method ends up being called twice (see
L<_handle_rest_request>) so the methods that get called here need to check
their state before running a second time.

The determination of whether this request comes from a browser is done by the
L<Catalyst::TraitFor::Request::REST::ForBrowsers> request trait.

=cut

# this is a big, ugly method, but breaking it into smaller ones just means a
# lot of faffing about with return values and checking everything multiple
# times, so that we can properly detach from the request if there's an error

around execute => sub {
  my $orig = shift;
  my $self = shift;
  my ( $controller, $c, @args ) = @_;

  if ( $self->_previous_request == $c->req ) {
    $c->log->debug( 'around execute: already authenticated this request' )
      if $c->debug;
    return $self->$orig(@_);
  }

  $c->log->debug( 'around execute: action needs authentication' )
    if $c->debug;

  # make sure it's not possible to sign in if sign-ins are turned off in the
  # config. Just unceremoniously dump the request.
  if ( $c->config->{disable_signin} ) {
    $c->log->debug( 'around execute: authenticated through the browser' )
      if $c->debug;
    $c->res->status(403); # Forbidden
    $c->res->body('Sign-ins are disabled');
    $c->detach;
    return;
  }

  # we can be authenticated in two ways, via the browser or by checking the API
  # key against the database. In the first case we end up with a
  # Catalyst::Authentication::User object, accessible as $c->user. In the
  # second case we end up with a Bio::HICF::User::Result::User, essentially a
  # row from the "user" table. We need to generate a message for the audit log
  # in both of those situations:
  my ( $log_name, $log_email, $log_req_type );

  # if Catalyst has supplied a user, we're already authenticated through the
  # browser
  if ( $c->user ) {
    $c->log->debug( 'around execute: authenticated through the browser' )
      if $c->debug;

    # user details come from $c->user...
    $log_name     = $c->user->get('username');
    $log_email    = $c->user->get('email');
    $log_req_type = 'browser';
  }
  else {
    $c->log->debug( 'around execute: not authenticated; authenticating...' )
      if $c->debug;

    # handle browser requests and REST requests differently
    if ( $c->req->looks_like_browser ) {

      $c->log->debug( 'around execute: browser user requires login; redirect to login form' )
        if $c->debug;

      my $message = ( $self->attributes->{LoginRedirectMessage}[0] )
                  ? $self->attributes->{LoginRedirectMessage}[0]
                  : 'You need to login to view this page';

      # hand off to the controller that we get from CatalystX::SimpleLogin
      $c->controller('Login')->login_redirect( $c, $message, @args );
      $c->detach;
      return;
    }
    else {
      # request is from a non-browser client

      # (AJAX requests would also end up here, except that they come with a
      # session ID courtesy of the browser, so Catalyst sets up $c->user, which
      # we check before trying to authenticate)

      $c->log->debug( 'around execute: REST client requires "Authorization" header; checking' )
        if $c->debug;

      my $auth_header = $c->req->header('Authorization');

      if ( not defined $auth_header ) {
        $c->log->error( 'around execute: no authorization header' )
          if $c->debug;
        $c->res->status(401); # Unauthorized
        $c->res->body('Must supply username and API key in the "Authorization" header');
        $c->detach;
        return;
      }

      # there should be an authorization header which looks like:
      # Authorization: <username>:<api_key>
      unless ( $auth_header =~ m/^([^:]+):([A-Za-z0-9]+)$/ ) {
        $c->log->error( 'around execute: malformed authorization header' )
          if $c->debug;
        $c->res->status(401); # Unauthorized
        $c->res->body('Malformed "Authorization" header; must be "username:api_key"');
        $c->detach;
        return;
      }

      my $username = $1;
      my $api_key  = $2;

      # look up the user and confirm the API key matches
      my $user = $c->model('UserDB::User')->find($username);

      unless ( defined $user ) {
        $c->log->error( 'around execute: no such user' )
          if $c->debug;
        $c->res->status(401); # Unauthorized
        $c->res->body('Bad username/API key');
        $c->detach;
        return;
      }

      unless ( $user->check_api_key($api_key) ) {
        $c->log->error( "around execute: API key does not match user's key" )
          if $c->debug;
        $c->res->status(401); # Unauthorized
        $c->res->body('Bad username/API key');
        $c->detach;
        return;
      }

      # user details come from Bio::HICF::User::Result::User...
      $log_name     = $user->username;
      $log_email    = $user->email;
      $log_req_type = 'REST';
    }
  }

  # at this point we are authenticated, either through the browser or via
  # the Authorization header

  # write details of this request to the audit log
  $self->_log_request($c, $log_name, $log_email, $log_req_type);

  $self->_previous_request($c->req);

  # continue on to the original action
  return $self->$orig(@_);
};

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

=head2 _log_request($c, @user_details)

Write an audit log entry for the request. The fields are:

=over

=item username

=item email address

=item request method, either C<browser> or C<REST>

=item user IP address

=item HTTP method, e.g. GET or POST

=item requested URI

=back

=cut

sub _log_request {
  my ( $self, $c, @user_details ) = @_;

  # decorate the user details with extra useful information
  my $log_string = DateTime->now . ' ';

  $log_string .= join ';', @user_details,
                           $c->req->address,
                           $c->req->method,
                           $c->req->uri;

  $c->log->debug( "_log_request: |$log_string|"  )
    if $c->debug;

  # pull the log writer config out of the context object and store it for use
  # by the "default" method that instantiates the log writer. Really ugly.
  $self->_audit_log_config($c->config->{audit_log});

  try {
    $self->_audit_logger->write("$log_string\n");
  }
  catch {
    $c->log->error( "failed to write log message: $_" );
    $c->log->error( "unwritten log entry: $log_string" );
  };
}

#-------------------------------------------------------------------------------

=encoding utf8

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

