#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Catalyst::Test 'MIDAS';

ok( request('/')->is_success, 'root page succeeds' );
ok( request('/contact')->is_success, 'contact page succeeds' );
ok( request('/validation')->is_success, 'validation page succeeds' );
ok( request('/validation/')->is_success, 'validation page succeeds with trailing slash' );
ok( request('/privacy')->is_success, 'privacy page succeeds' );
ok( request('/login')->is_success, 'login page succeeds' );
ok( request('/api')->is_success, 'API page succeeds' );
ok( action_notfound('/nosuchpage'), 'non-existent page not found');

my $content = get('/nosuchpage');
like( $content, qr/We couldn't find the page that you were looking for/, '404 page looks sensible' );

done_testing();

