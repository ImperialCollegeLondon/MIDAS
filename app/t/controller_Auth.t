use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MIDAS';
use MIDAS::Controller::Auth;

ok( request('/auth')->is_success, 'Request should succeed' );
done_testing();
