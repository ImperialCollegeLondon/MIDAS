#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use JSON;
use Catalyst::Test 'MIDAS';
use Catalyst::Request;
use Catalyst::Request::Upload;
use HTTP::Request::Common;

BEGIN {
  $ENV{CATALYST_CONFIG_LOCAL_SUFFIX} = 'testing';
  use_ok("Test::WWW::Mechanize::Catalyst" => 'MIDAS');
}

# check the basic page contents
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/validation', 'check validation page');
$mech->title_like(qr/MIDAS.*?Validation/, 'check title');
$mech->content_contains('Validating a sample manifest', 'first section looks sensible');
$mech->content_contains('Validating a manifest locally', 'second section looks sensible');
$mech->content_contains('breadcrumb', 'found breadcrumbs');
$mech->content_lacks('Thomas Splettstoesser', 'virus image credit not found');

# upload a valid file
my $req = POST(
  'http://localhost/validate',
  'Content-Type' => 'form-data',
  'Content' => [
    'csv' => [ 't/data/validation_valid.csv' ],
  ],
);

ok my $res = request($req), 'sent upload request';
ok $res->is_success, 'response successful';
is $res->content_type, 'application/json', 'got JSON response';
my $response_data = from_json $res->decoded_content;
is $response_data->{status}, 'valid', 'upload is valid';

# and an invalid file
$req = POST(
  'http://localhost/validate',
  'Content-Type' => 'form-data',
  'Content' => [
    'csv' => [ 't/data/validation_broken.csv' ],
  ],
);

ok $res = request($req), 'sent upload request';
ok $res->is_success, 'response successful';
is $res->content_type, 'application/json', 'got JSON response';
$response_data = from_json $res->decoded_content;
is $response_data->{status}, 'invalid', 'upload is invalid';

# get the validated file
my $validated_file_url = $response_data->{validatedFile};

$req = GET($validated_file_url);
ok $res = request($req), 'sent download request';
ok $res->is_success, 'response successful';
is $res->content_type, 'text/csv', 'got CSV response';
like $res->content, qr/errors found on row 2/, 'found errors in validated file';

done_testing();

