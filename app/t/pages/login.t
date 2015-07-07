#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Copy;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test database, so that changes don't break the original
copy 't/data/user.db', 'temp_user.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->add_header( 'Content-Type' => 'text/html' );

$mech->get_ok('http://localhost/login', 'got login page');
$mech->content_contains('Access to MIDAS data is currently', 'login page looks sensible');
$mech->content_lacks('You are already signed in', 'check we are not yet logged in');

my $login_error_message = 'Wrong username or password';
$mech->get_ok('http://localhost/login?username=testuser', 'login with only username');

TODO: {
  # TODO find a way to stop the form being submitted without a password, ideally
  # TODO in the perl rather than having to resort to javascript
  local $TODO = 'omitting password redirects to index rather than showing error message';
  $mech->content_contains($login_error_message, 'using just username produces error message');
}

$mech->get_ok('http://localhost/login?username=badusername&password=wrongpassword', 'login with bad username');
$mech->content_contains($login_error_message, 'bad username produces same error message');
$mech->get_ok('http://localhost/login?username=testuser&password=wrongpassword', 'login with bad password');
$mech->content_contains($login_error_message, 'bad password produces same error message');

$mech->get_ok('http://localhost/login', 'got login page again');

$mech->submit_form(
  form_number => 1,
  fields => {
    username => 'testuser',
    password => 'password',
  }
);

$mech->content_contains('HICF sample summary', 'got summary page');
$mech->content_contains('Account management', 'signed in');

$mech->get_ok('http://localhost/login', 'got login page again');
$mech->content_contains('You are already signed in', 'check we are now logged in');

$mech->get_ok('http://localhost/logout', 'logout succeeds');
$mech->content_lacks('You are already signed in', 'check we are now logged out');

done_testing;

