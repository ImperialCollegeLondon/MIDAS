#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Path qw(remove_tree make_path);
use File::Touch;
use File::Find::Rule;

BEGIN {
  $ENV{MIDAS_CONFIG}                 = 't/data/validation.conf';
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'uploads';
  use_ok 'Test::WWW::Mechanize::Catalyst' => 'MIDAS';
}

# set up some test data
my $tmp_dir = '/tmp/__MIDAS_TESTING';
my $dir_path1 = "$tmp_dir/11111111-1234-1234-1234-1234567890ab";
my $dir_path2 = "$tmp_dir/22222222-1234-1234-1234-1234567890ab";

remove_tree($tmp_dir);
make_path($dir_path1, $dir_path2);

# touch one set of files with an mtime of an hour ago, another set with
# mtime of 60 seconds ago
my $toucher = File::Touch->new( time => ( time() - 3600 ) );
$toucher->touch( "$dir_path1/upload", "$dir_path1/metadata" );
$toucher = File::Touch->new( time => ( time() - 60 ) );
$toucher->touch( "$dir_path2/upload", "$dir_path2/metadata" );

my @files = File::Find::Rule->in($tmp_dir);
is scalar @files, 7, 'found 7 files in (and including) tmp dir';

my $ua = Test::WWW::Mechanize::Catalyst->new;
$ua->get_ok('http://localhost/?schedule_trigger=clear_uploads', 'trigger request works');

# the config specifies that uploads older than 5 minutes (300s) should be
# removed. Make sure that happened
@files = File::Find::Rule->in($tmp_dir);
is scalar @files, 5, 'found 5 files/directories in tmp dir';
isnt grep ( m[11111111.*?/upload], @files ), 1, 'correct upload file removed';

done_testing();

# tidy up
remove_tree($tmp_dir);

