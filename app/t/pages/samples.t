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

# check the basic page contents
my $mech = Test::WWW::Mechanize::Catalyst->new;

# need to login first
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

# and now check the samples page
$mech->get_ok('http://localhost/samples', 'check validation page');
$mech->get_ok('/samples', 'check validation page');
$mech->title_like(qr/MIDAS.*?Samples/, 'check title');
$mech->content_contains('HICF samples');

TODO: {
  local $TODO = 'need to add breadcrumbs';
  $mech->content_contains('breadcrumb', 'found breadcrumbs');
}

$mech->content_lacks('Thomas Splettstoesser', 'virus image credit not found');

is( $mech->scrape_text_by_id('samples'), 'Sample ID Manifest ID Scientific name NCBI tax ID Collection date Source 1 4162F712-1DD2-11B2-B17E-C09EFE1DC403 9606 1428658943 CAMBRIDGE', '"samples" table looks right');
my @rows = $mech->scrape_text_by_attr('scope', 'row');
is( scalar @rows, 2, 'got header and one sample row' );
done_testing;

