use strict;
use warnings;
use Test::More;


use Catalyst::Test 'MIDAS';
use MIDAS::Controller::Sample;

ok( request('/samples')->is_success, 'samples request succeeded' );
done_testing();
