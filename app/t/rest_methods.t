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

# all samples
my $res = request( GET '/samples',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got all samples';

my $json = JSON->new;
my $json_data_structure;

lives_ok { $json_data_structure = $json->decode($res->content) }
  'no error when decoding JSON response';
is ref $json_data_structure, 'ARRAY', 'got data structure when decoding JSON';

is scalar @$json_data_structure, 1, 'got 1 element in array';

# single sample
$res = request( GET '/sample/1',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

lives_ok { $json_data_structure = $json->decode($res->content) }
  'no error when decoding JSON response';
is ref $json_data_structure, 'HASH', 'got data structure when decoding JSON';

is $json_data_structure->{sample_accession}, 'ERS111111', 'JSON looks sensible';

# TODO add tests for more methods

done_testing;

