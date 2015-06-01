#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON;
use HTTP::Request::Common;
use File::Copy;

use Catalyst::Test 'MIDAS';

BEGIN { $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing'; }

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/data.db', 'temp_data.db';

# omit Auth header entirely
my $res = request( GET '/account',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 when auth header omitted';

$res = request( GET '/account',
  Authorization => 'testuser:11111111111111111111111111111111',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 with incorrect API key';

$res = request( GET '/account',
  Authorization => 'testuser#JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 with malformed header';

$res = request( GET '/account',
  Authorization => 'testuser:11111111111111111111111111111111',
  Content_Type => 'application/json',
);
is $res->status_line, '401 Unauthorized', 'got 401 with incorrect API key';

$res = request(
  GET '/samples',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

done_testing;

