#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Copy;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# clone the test database, so that changes don't break the original
copy 't/data/user.db', 'temp_user.db';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'check basic index page');
$mech->title_is('MIDAS', 'check title');
$mech->content_like(qr/Microbial Diagnostics and.*?Surveillance \(MIDAS\)/s, 'check page contents');
$mech->content_contains('Sign in', 'default state is logged out');
$mech->content_contains('Thomas Splettstoesser', 'virus image credit found');

my @links = $mech->find_all_links( url_regex=>qr|^https?://((?!localhost).)*$| );
is( scalar @links, 8, 'found expected number of external links (8)' );

# this should work, as far as I can tell, but it always returns
# six failed links...
# $mech->allow_external(1); # maybe need this?
# $mech->links_ok( \@links, 'check all non-local links' );

@links = $mech->find_all_links( url_regex=>qr/localhost/ );
is( scalar @links, 4, 'found expected number of local links (4)' );
$mech->links_ok( \@links, 'check local links' );

$mech->get_ok('http://localhost/login', 'got login page');
$mech->content_contains('Access to MIDAS data is currently', 'login page looks sensible');
$mech->content_lacks('You are already signed in', 'check we are not yet logged in');

$mech->submit_form(
  with_fields => {
    username => 'testuser',
    password => 'password',
  }
);

$mech->get_ok('http://localhost/login', 'got login page again');
$mech->content_contains('You are already signed in', 'check we are now logged in');

done_testing();

