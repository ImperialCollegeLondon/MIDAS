#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Path qw( make_path remove_tree );
use File::Slurp;
use HTTP::Request::Common;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/testing.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'audit';
}

use Catalyst::Test 'MIDAS';

# the DSN here has to match that specified in "testing_audit.conf"
use Test::DBIx::Class {
  connect_info => [ 'dbi:SQLite:dbname=testing.db', '', '' ],
}, qw( :resultsets );

# load the pre-requisite data
fixtures_ok 'main', 'installed fixtures';

my $tmp_dir = '/tmp/__midas_audit_logs';
remove_tree( $tmp_dir );
make_path( $tmp_dir );

my $log_file = "$tmp_dir/midas.log";

# check there's no log file before we start
ok ! -f $log_file, 'no audit log at start';

# make a valid request and make sure there's a log file afterwards
my @request_params = (
  GET '/samples',
  Authorization => 'testuser:2566ZD3k4SVdJfGkdXJQUj6B4aPoq2Rf',
  Content_Type  => 'application/json',
);
my $res = request(@request_params);
is $res->status_line, '200 OK', 'got 200 with valid user and API key';

ok -f $log_file, 'found audit log';

my @log_file_contents = read_file $log_file;

is scalar @log_file_contents, 1, 'found one line in log file';
like $log_file_contents[0], qr|testuser;testuser\@sanger\.ac\.uk;REST;127\.0\.0\.1;GET;http://localhost/samples|, 'log file looks correct';

# add lots of log messages; should trigger a logrotate, leaving 6 rows in rotated
# file and 5 in active log
request(@request_params) foreach ( 1 .. 10 );

my @log_files = read_dir $tmp_dir;
is scalar @log_files, 2, 'found active and rotated logs';

@log_file_contents = read_file "$tmp_dir/$log_files[0]";
is scalar @log_file_contents, 5, 'found 5 rows in active log';

@log_file_contents = read_file "$tmp_dir/$log_files[1]";
is scalar @log_file_contents, 6, 'found 6 rows in rotated log';

$DB::single = 1;

done_testing;

remove_tree( $tmp_dir );

