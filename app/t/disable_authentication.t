#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 9;
use File::Copy;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'disable_auth';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test database, so that changes don't break the original
copy 't/data/data.db', 'temp_data.db';
copy 't/data/user.db', 'temp_user.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->add_header( 'Content-Type' => 'text/html' );

$mech->get_ok('http://localhost/', 'got index page');
$mech->content_lacks('Sign in', 'no sign in button');

$mech->get_ok('http://localhost/login', 'got login page');
$mech->content_contains('Sign in disabled', 'login page disabled');

$mech->get_ok('http://localhost/account', 'got password reset page');
$mech->content_contains('Accounts are disabled', 'password reset page disabled');

$mech->get_ok('http://localhost/summary', 'got summary page');
$mech->content_contains('HICF sample summary', 'summary page loads without authentication');

# done_testing;

