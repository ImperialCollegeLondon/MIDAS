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

$mech->get_ok('http://localhost/api', 'visit api page');
$mech->content_contains('The MIDAS website includes a RESTful API',
  'contents looks good');

$mech->title_like(qr/MIDAS.*?API/, 'title looks good');
$mech->content_lacks('Thomas Splettstoesser', 'virus image credit not found');

done_testing;

