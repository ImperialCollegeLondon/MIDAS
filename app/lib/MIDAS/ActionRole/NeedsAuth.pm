
package MIDAS::ActionRole::NeedsAuth;

# ABSTRACT: ActionRole to enforce authentication for both browsers and REST API users

use Moose::Role;
use namespace::autoclean;

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

=head1 METHODS

=head2 execute

An 'around' modifier for the C<execute> method. For browser-based requests
where the user is not already logged in, we redirect to the login action and
let it take care of authenticating the browser and forwarding on to the
requested action. For non-browser-based requests we forward to an action that
tries to authenticate the request using C<Authentication> header and forward
to the requested action.

The determination of whether this request comes from a browser is done by the
L<Catalyst::TraitFor::Request::REST::ForBrowsers> request trait.

=cut

around execute => sub {
  my $orig = shift;
  my $self = shift;
  my ( $controller, $c, @args ) = @_;

  $c->log->debug( 'around execute: action needs authentication' )
    if $c->debug;

  # require user login for browsers
  if ( $c->req->looks_like_browser ) {

    if ( not $c->user ) {
      my $message = ( $self->attributes->{LoginRedirectMessage}[0] )
                  ? $self->attributes->{LoginRedirectMessage}[0]
                  : 'You need to login to view this page';

      # hand off to the controller that we get from CatalystX::SimpleLogin
      $c->log->debug( 'around execute: browser user required login; redirect to login form' )
        if $c->debug;
      $c->controller('Login')->login_redirect( $c, $message, @args );
      $c->detach;
    }

  }
  # require HMAC authentication for non-browsers, i.e. via REST
  else {
    $c->log->debug( 'around execute: non-browser user requires HMAC; checking...' )
      if $c->debug;

    # if this request comes from a RESTful controller, the action is specified
    # with a stub method to define the path, e.g.
    #
    #   sub sample :Path ActionClass('REST') {}
    #
    # and a concrete method for each HTTP verb, e.g.
    #
    #   sub sample_GET {
    #     ...
    #   }
    #
    # In that case the "around" modifier gets fired twice, once for the stub
    # and once for the concrete method. In order to avoid validating twice, we
    # check the stash for a flag that gets set when the HMAC validation is
    # successful
    if ( not $c->stash->{hmac_validated} ) {
      $c->log->debug( "around execute: haven't validated HMAC yet..." )
        if $c->debug;
      $c->forward('/validate_hmac');
    }
  }

  # this only applies to HMAC-authenticated requests. If the validation fails,
  # the user gets a '401 Unauthorized' response and the request flow never gets
  # back here. If the validation succeeds, we end up back here, so we need to
  # continue on to the original action
  return $self->$orig(@_);
};

#-------------------------------------------------------------------------------

1;

