#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

# use a specific "local" configuration which specifically enables the sign-in
# button and Piwik. This test should be run in conjunction with
# t/pages/config_disabled.t, which specifically disables both of those features
# and checks that that's really happened

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'enabled';
  use_ok 'Test::WWW::Mechanize::Catalyst' => 'MIDAS';
}

my $ua = Test::WWW::Mechanize::Catalyst->new;
$ua->get_ok( '/', 'index page works' );
$ua->content_lacks( 'btn btn-default btn-sm disabled', 'sign-in is enabled' );
$ua->content_contains( '/zxtm/piwik2.js', 'piwik is enabled' );

done_testing();

