#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON;
use File::Copy;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

# check the basic page contents
my $mech = Test::WWW::Mechanize::Catalyst->new;

# need to login first
$mech->get_ok('http://localhost/login', 'got login page');

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

# finally, check the sample HTML page
$mech->get_ok('/sample/1', 'check sample page with valid ID');
$mech->title_like(qr/MIDAS.*?Sample 1/, 'check title');
$mech->content_contains('Sample 1');

# and the sample data when retrieved as JSON
$mech->get_ok('/sample/1?content-type=application/json', 'check sample JSON');
my $json = JSON->new;
my $json_data_structure;
lives_ok { $json_data_structure = $json->decode($mech->content) }
  'no error when decoding JSON response';
is ref $json_data_structure, 'HASH', 'got data structure when decoding JSON';

# check with invalid sample IDs
$mech->get_ok('/sample/XXXXXX', 'check sample page with bad ID');
$mech->title_like(qr/MIDAS.*?Sample$/, 'title does not contain tainted ID');
$mech->content_contains('Not a valid sample ID');
$mech->content_lacks('XXXXXX');

done_testing;

