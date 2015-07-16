#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use HTTP::Request::Common;
use File::Copy;
use JSON;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'rest';
}

use Catalyst::Test 'MIDAS';

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

# omit Auth header entirely
my $res = request( GET '/account',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 when auth header omitted';

# bad API key
$res = request( GET '/account',
  Authorization => 'testuser:11111111111111111111111111111111',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 with incorrect API key';

# bad "Authorization" header
$res = request( GET '/account',
  Authorization => 'testuser#JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 with malformed header';

# valid "Authorization" header and valid key
$res = request( GET '/samples',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

done_testing;

