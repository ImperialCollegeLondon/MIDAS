#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Copy;
use JSON;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'sample';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->add_header( 'Content-Type' => 'text/html' );

# need to login first
$mech->get_ok('/login', 'got login page');

$mech->submit_form(
  form_number => 1,
  fields => {
    username => 'testuser',
    password => 'password',
  }
);

$mech->content_contains('Account management', 'signed in');
$mech->content_like(qr/HICF sample summary/,
  'redirected to summary after successful login');

# finally, check the sample HTML page
$mech->get_ok('/sample/1', 'check sample page with valid ID');
$mech->title_like(qr/MIDAS.*?Sample 1/, 'check title');
$mech->content_contains('Sample 1');

# check with invalid sample IDs
$mech->get_ok('/sample/XXXXXX', 'check sample page with bad ID');
$mech->title_like(qr/MIDAS.*?Sample$/, 'title does not contain tainted ID');
$mech->content_contains('Not a valid sample ID');
$mech->content_lacks('XXXXXX');

done_testing;

