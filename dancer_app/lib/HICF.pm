
package HICF;

use Moo;
use Dancer2;
use Dancer2::Plugin::Ajax;
use Dancer2::Plugin::DBIC qw( schema resultset );
use Dancer2::Plugin::Auth::Tiny;
use URI;
use LWP::UserAgent;
use MIME::Base64::URLSafe;
use TryCatch;
use URI::Escape;

use Bio::HICF::Schema;

our $VERSION = '0.1';

#-------------------------------------------------------------------------------

hook before_template_render => sub {
  my $tokens = shift;

  # generate a state token for every request
  my $state = '';
  $state .= ['0'..'9','A'..'Z','a'..'z']->[rand 52] for 1..32;

  session state => $state;

  $tokens->{state} = $state;

  # shortcuts to the g+ client ID and the logger
  $tokens->{client_id} = config->{oauth2}->{google}->{web}->{client_id};
  $tokens->{logger}    = app->logger_engine;
};

#-------------------------------------------------------------------------------

get '/' => sub {
  # set the javascript controller for the page
  var controller => 'index';
  template 'index';
};

#-------------------------------------------------------------------------------

ajax [ 'post' ] => '/connect' => sub {

  if ( param('state') ne session('state') ) {
    warn 'state parameter does not match session state; returning 401';
    status 401; # unauthorized
    return '"Invalid state parameter"';
  }

  debug 'state parameter matches session state';

  # now we can go on to exchange the (one-time) authorization code for an
  # access token
  my $tokens;
  try {
    $tokens = _exchange_code_for_token( request->body );
  }
  catch ($e) {
    warn "error response when trying to exchange authorization code for access token: $e->{error}";
    status 401; # unauthorized
    return $e->{error};
  }

  session tokens => $tokens;

  my $gplus_id        = $tokens->{id_token}->{sub};
  my $stored_gplus_id = session('gplus_id');

  if ( $stored_gplus_id and
       $gplus_id eq $stored_gplus_id ) {
    info 'current user is already connected';
    return '"Current user is already connected"';
    # (the returned message is double quoted because it's returned to the
    # browser and interpreted as JSON. If it's not quoted, the browser's JSON
    # parser spits the dummy)
  }

  session gplus_id => $gplus_id;

  # retrieve profile information and confirm that the user is authorized to sign in
  my $profile;
  try {
    $profile = _get_profile( $tokens->{access_token} );
  }
  catch ($e) {
    warn "error response when trying to retrieve profile information: $e->{error}";
    status 500; # internal server error
    return $e->{error};
  }

  # TODO check the user's profile against the database to decide if they're
  # TODO authorized to sign in

  return '"Successfully connected user"';
};

#---------------------------------------

sub _exchange_code_for_token {
  my $code = shift;

  my $client_secret = config->{oauth2}->{google}->{web};
  my $params = {
    client_id     => $client_secret->{client_id},
    client_secret => $client_secret->{client_secret},
    redirect_uri  => 'postmessage',
    code          => $code,
    grant_type    => 'authorization_code',
    scope         => 'https://www.googleapis.com/auth/userinfo.email',
    # the scope here should match that in the HTML that builds the signin
    # button, in navbar.tt
    # (see https://developers.google.com/+/api/oauth#login-scopes for info on scopes)
  };

  my $ua = LWP::UserAgent->new;
  $ua->env_proxy;
  my $response = $ua->post( $client_secret->{token_uri}, $params );

  die { error => '"Failed to exchange code for token"' } unless $response->is_success;

  # unpack the token
  my $token = from_json $response->content;

  die { error => '"Did not receive an access token"' } unless exists $token->{access_token};

  # ACCESS TOKEN
  my $access_token = $token->{access_token};

  # do we need to refresh ?
  # (see https://github.com/google/oauth2client/blob/master/oauth2client/client.py#L1942)
  if ( not exists $token->{refresh_token} ) {
    info 'received token response with no refresh_token. Consider ' .
         're-authenticating with approval_prompt="force"';
  }

  # TODO handle token expiry

  # ID TOKEN
  my @segments = split '\.', $token->{id_token};
  my $decoded_segment = urlsafe_b64decode $segments[1];
  my $extracted_id_token = from_json $decoded_segment;

  return {
    access_token => $access_token,
    id_token => $extracted_id_token,
  };

}

#---------------------------------------

sub _get_profile {
  my $access_token = shift;

  my $ua = LWP::UserAgent->new;
  $ua->env_proxy;

  my $credentials = config->{oauth2}->{google}->{web};

  my $uri = 'https://www.googleapis.com/plus/v1/people/me';
  my $response = $ua->get( $uri, 'Authorization', "Bearer $access_token" );

  die { error => '"Failed to retrieve profile information"' }
    unless $response->is_success;

  debug 'profile: ' . $response->content;

  my $gplus_profile = from_json $response->content;
  return {
    id    => $gplus_profile->{id},
    name  => $gplus_profile->{displayname},
    email => $gplus_profile->{emails}->[0]->{value},
  };
}

#-------------------------------------------------------------------------------

ajax [ 'post' ] => '/disconnect' => sub {

  if ( param('state') ne session('state') ) {
    warn 'state parameter does not match session state; returning 401';
    status 401; # unauthorized
    return '"Invalid state parameter"';
  }

  debug 'state parameter matches session state';

  my $tokens = session('tokens');

  unless ( defined $tokens ) {
    info 'current user is not connected';
    status 401; # unauthorized
    return '"Current user is not connected"';
  }

  my $access_token = $tokens->{access_token};

  my $uri = "https://accounts.google.com/o/oauth2/revoke?token=$access_token";

  my $ua = LWP::UserAgent->new;
  $ua->env_proxy;
  my $response = $ua->get($uri);

  if ( $response->is_success ) {
    info 'successfully disconnected user';
    session->delete('gplus_id');
    return '"Successfully disconnected"';
  }
  else {
    info 'successfully disconnected user';
    status 400; # bad request
    return '"Failed to revoke token for current user"';
  }
};

#-------------------------------------------------------------------------------

get '/login' => sub {
  template 'login', { return_url => uri_escape( param('return_url') ) };
};

#-------------------------------------------------------------------------------

get '/contact' => sub {
  var controller => 'contact';

  template 'contact', {
                        title       => 'Contact us',
                        breadcrumbs => [ 'Contact us' ]
                      };
};

#-------------------------------------------------------------------------------

get '/validation' => needs login => sub {
  var controller => 'validation';

  template 'validation', {
                           title       => 'Validation',
                           breadcrumbs => [ 'Validation' ]
                         };
};

true;
