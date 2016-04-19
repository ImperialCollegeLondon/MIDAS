#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use HTTP::Request::Common;
use File::Copy;
use JSON;
use Text::CSV_XS;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'rest';
}

use Catalyst::Test 'MIDAS';

# clone the test databases, so that changes don't break the originals
copy 't/data/user.db', 'temp_user.db';
copy 't/data/multiple_samples.db', 'temp_data.db';

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

is scalar @$json_data_structure, 11, 'got 11 elements in array';

# single sample
$res = request( GET '/sample/1',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'application/json',
);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

lives_ok { $json_data_structure = $json->decode($res->content) }
  'no error when decoding JSON response';
is ref $json_data_structure, 'HASH', 'got data structure when decoding JSON';

is $json_data_structure->{sample_accession}, 'ERS111101', 'JSON looks sensible';

# bulk search
$res = request( POST '/search',
  Authorization => 'testuser:JSVVZjKQEUQGGnnKe1nS367BbMJESjJe',
  Content_Type => 'form-data',
  Content => [
    query => [ 't/data/search.csv', 'search.csv', 'Content-type' => 'text/csv' ],
  ],
);

# parse the returned CSV and make sure it's sensible
my $csv = Text::CSV_XS->new;

my $parsed = 0;
my $human  = 0;
my @data;
foreach my $row ( split m/\n/, $res->content ) {
  my $success = $csv->parse($row);
  next unless $success;
  $parsed++;
  $human++ if ( $csv->fields )[8] eq 'Homo sapiens';
}

is $parsed, 5, 'parsed 5 lines from result CSV';
is $human, 4, 'all rows have human data';

# TODO add tests for more methods

done_testing;

