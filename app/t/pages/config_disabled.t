#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# use a specific "local" configuration which disables the sign-in button and
# omits the Piwik script tag

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'disabled';
  use_ok 'Test::WWW::Mechanize::Catalyst' => 'MIDAS';
}

my $ua = Test::WWW::Mechanize::Catalyst->new;
$ua->get_ok( '/', 'index page works' );
$ua->content_contains( 'btn btn-default btn-sm disabled', 'sign-in is disabled' );
$ua->content_lacks( '/zxtm/piwik2.js', 'piwik is disabled' );

done_testing();

