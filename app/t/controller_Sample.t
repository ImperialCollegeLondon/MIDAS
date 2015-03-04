use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MIDAS';
use MIDAS::Controller::Sample;

ok( request('/sample')->is_success, 'Request should succeed' );
done_testing();
