#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

BEGIN { use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS') }

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/contact', 'check contact page');
$mech->title_like(qr/MIDAS.*?Contact us/, 'check title');
$mech->content_contains('New data submissions may', 'looks sensible');
$mech->content_contains('breadcrumb', 'found breadcrumbs');
$mech->content_lacks('Thomas Splettstoesser', 'virus image credit not found');

done_testing();

