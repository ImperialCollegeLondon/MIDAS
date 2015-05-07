#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# the DSN here has to match that specified in "midas_testing.conf"
use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=testing.db', '', '' ],
}, qw( :resultsets );

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

is( User->count, 1, 'one user before beginning testing' );

my $json = JSON->new;
my $mech = Test::WWW::Mechanize::Catalyst->new;
my $user = Schema->resultset('User')->find('testuser');

ok( $user->check_password('password'), 'password is "password"');

$mech->get_ok('http://localhost/logout', 'logout before starting testing');
$mech->get_ok('http://localhost/account', 'request to account page succeeds...');
$mech->content_contains('Access to MIDAS data is currently', 'account page redirects to login form');

$mech->submit_form(
  form_name => 'signin-form',
  fields => {
    username => 'testuser',
    password => 'password',
  }
);

$mech->content_contains('Account management', 'redirected to account page after login');
$mech->title_like(qr/MIDAS.*?Account management/, 'check title');

my $form = {};
$mech->post('http://localhost/account/resetpassword', $form);
is($mech->status, 400, '400 error with no passwords');

my $response_data;
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';

ok(exists $response_data->{error}, 'found error message in response');
is($response_data->{error}, 'You must enter all three passwords', 'error message is as expected');

$form = {
  oldpass => 'password',
  newpass1 => 'newpassword',
};
$mech->post('http://localhost/account/resetpassword', $form);
is($mech->status, 400, '400 error with no duplicate new password');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{error}, 'You must enter all three passwords', 'error message is as expected');

$form = {
  oldpass => 'password',
  newpass1 => 'newpassword',
  newpass2 => 'different',
};
$mech->post('http://localhost/account/resetpassword', $form);
is($mech->status, 400, '400 error with non-matching duplicate passwords');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{error}, 'New passwords did not match', 'error message is as expected');

ok( $user->check_password('password'), 'password still unchanged');

$form = {
  oldpass => 'password',
  newpass1 => 'newpassword',
  newpass2 => 'newpassword',
};
$mech->post_ok('http://localhost/account/resetpassword', $form, 'POST succeeds with valid passwords');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{message}, 'Your password has been changed', 'message is as expected');

# make sure we're not getting cached values from the User object
$user = undef;
$user = Schema->resultset('User')->find('testuser');
ok( $user->check_password('newpassword'), 'password changed');

is( User->count, 1, 'still one user after testing' );

my $old_key_hash = $user->api_key;

$mech->post('http://localhost/account/resetkey', {});

is($mech->status, 400, '400 error with no password');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{error}, 'You must enter your current password', 'error message is as expected');

$form = {
  password => 'badpassword'
};
$mech->post('http://localhost/account/resetkey', $form);
is($mech->status, 400, '400 error with bad password');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{error}, 'Invalid password. Please try again', 'error message is as expected');

$form = {
  password => 'newpassword'
};
$mech->post_ok('http://localhost/account/resetkey', $form, 'successful POST with valid password');
lives_ok { $response_data = $json->decode($mech->content) } 'got JSON content from response';
is($response_data->{message}, 'Your API key has been reset', 'message is as expected');

$user = undef;
$user = Schema->resultset('User')->find('testuser');
my $new_key_hash = $user->api_key;
ok( $new_key_hash ne $old_key_hash, 'key has been changed');

my $new_key = $response_data->{key};
like( $new_key, qr/^[A-Za-z0-9]{32}/, 'new key looks sensible');
ok $user->check_api_key($response_data->{key}), 'new key checks out against hash in DB';

$DB::single = 1;

done_testing();

