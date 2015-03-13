#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS') }

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/login', 'got login page');
$mech->content_contains('Access to MIDAS data is currently', 'login page looks sensible');
$mech->content_lacks('You are already signed in', 'check we are not yet logged in');

my $login_error_message = 'Wrong username or password';
$mech->get_ok('http://localhost/login?username=jtate', 'login with only username');

TODO: {
  # TODO find a way to stop the form being submitted without a password, ideally
  # TODO in the perl rather than having to resort to javascript
  local $TODO = 'omitting password redirects to index rather than showing error message';
  $mech->content_contains($login_error_message, 'using just username produces error message');
}

$mech->get_ok('http://localhost/login?username=badusername&password=wrongpassword', 'login with bad username');
$mech->content_contains($login_error_message, 'bad username produces same error message');
$mech->get_ok('http://localhost/login?username=jtate&password=wrongpassword', 'login with bad password');
$mech->content_contains($login_error_message, 'bad password produces same error message');

$mech->get_ok('http://localhost/login', 'got login page again');

$mech->submit_form(
  with_fields => {
    username => 'testuser',
    password => 'password',
  }
);

$mech->content_like(qr/Microbial Diagnostics and.*?Surveillance \(MIDAS\)/s,
  'redirected to index after successful login');
$mech->content_contains('Signed in as', 'signed in');
$mech->content_contains('testuser', 'signed in as "testuser"');

$mech->get_ok('http://localhost/login', 'got login page again');
$mech->content_contains('You are already signed in', 'check we are now logged in');

$mech->get_ok('http://localhost/logout', 'logout succeeds');
$mech->content_lacks('You are already signed in', 'check we are now logged out');

done_testing();

