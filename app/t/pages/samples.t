#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON;
use File::Copy;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->add_header( 'Content-Type' => 'text/html' );

# check that we need to login first
$mech->get_ok('http://localhost/samples', 'visit samples page');
$mech->content_contains('Access to MIDAS data is currently restricted',
  'redirected to sign in page');

$mech->submit_form(
  form_number => 1,
  fields => {
    username => 'testuser',
    password => 'password',
  }
);

# were we redirected to the samples page ?
$mech->content_contains('HICF samples', 'redirected to samples page');

$mech->title_like(qr/MIDAS.*?Samples/, 'title looks good');
$mech->content_contains('samples-table', 'found samples table');
$mech->content_lacks('Thomas Splettstoesser', 'virus image credit not found');

done_testing;

