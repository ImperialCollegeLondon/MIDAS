#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use JSON;
use HTTP::Request::Common;

use Catalyst::Test 'MIDAS';

BEGIN { $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing'; }

# the DSN here has to match that specified in "midas_testing.conf"
use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=testing.db', '', '' ],
}, qw( :resultsets );

# load the pre-requisite data and THEN turn on foreign keys
fixtures_ok 'main', 'installed fixtures';

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
  Authorization => 'testuser#2566ZD3k4SVdJfGkdXJQUj6B4aPoq2Rf',
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
  Authorization => 'testuser:2566ZD3k4SVdJfGkdXJQUj6B4aPoq2Rf',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

done_testing;

