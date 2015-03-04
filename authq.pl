#!/usr/bin/env perl

# helper script to add HMAC authentication headers to requests
# jt6 20150304 WTSI

use strict;
use warnings;

use Getopt::Long;
use Crypt::Mac::HMAC qw(hmac_b64);
use LWP::UserAgent;
use HTTP::Request;

my ( $username, $api_key );
my $method = 'GET';
my $content_type = 'application/json';

# get the required parameters from the command line and validate
GetOptions(
  'username=s'    => \$username,
  'apikey|k=s'    => \$api_key,
  'method=s'      => \$method,
  'contenttype=s' => \$content_type,
);

my $uri = shift;

die 'ERROR: not a valid username'
  unless defined $username and $username =~ m/^\w+$/;

die 'ERROR: not a valid method (must be either GET or POST)'
  unless $method =~ m/^(GET|POST)$/;

die 'ERROR: must supply a URI'
  unless defined $uri;

# calculate the message authentication code
my $hmac = hmac_b64( 'SHA256', $api_key, "$method+$uri" );

# build the request
my $req = HTTP::Request->new(
            $method,
            $uri,
            [ 'Authorization' => "hmac $username:$hmac",
              'Accept'        => $content_type ]
            # specify the required response content type using the "Accept" header
          );

# submit the request
my $ua = LWP::UserAgent->new;
$ua->env_proxy;

my $res = $ua->request($req);

if ( $res->is_success ) {
  print $res->decoded_content;
}
else {
  die 'ERROR: ' . $res->status_line;
}

