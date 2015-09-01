#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Copy;
use JSON;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'antimicrobials';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->add_header( 'Content-Type' => 'text/html' );

# check that we need to login to access the list
$mech->get_ok('/antimicrobials', 'got antimicrobials list');
$mech->content_contains('Sign in', "can't see list without signing in");

# go ahead and login
$mech->submit_form(
  form_number => 1,
  fields => {
    username => 'testuser',
    password => 'password',
  }
);

# should get handed the file now
is $mech->content_type, 'text/plain', 'got plain text response';
$mech->content_contains('# antimicrobial compound names', 'found header');
$mech->content_contains('am1', 'found compound 1');
$mech->content_contains('am2', 'found compound 2');

# check link
$mech->get_ok('/summary', 'got summary page');
$mech->content_contains('You can download the list', 'found link');
$mech->follow_link(url_regex => qr/antimicrobials/);

$mech->content_contains('# antimicrobial compound names', 'found header');
$mech->content_contains('am1', 'found compound 1');
$mech->content_contains('am2', 'found compound 2');

done_testing;

