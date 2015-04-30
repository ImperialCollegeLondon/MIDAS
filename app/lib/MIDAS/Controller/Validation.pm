use utf8;
package MIDAS::Controller::Validation;

use Moose;
use namespace::autoclean;

# use File::Path qw(make_path remove_tree);
# use File::Find::Rule;
# use File::Basename;
use Data::UUID;
use Try::Tiny;
use File::Slurp;

use Bio::Metadata::Checklist;
use Bio::Metadata::Reader;
use Bio::Metadata::Manifest;
use Bio::Metadata::Validator;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

MIDAS::Controller::Validation - Catalyst Controller to handle manifest validation

=head1 DESCRIPTION

Catalyst Controller.

=cut

#-------------------------------------------------------------------------------
#- private attributes  ---------------------------------------------------------
#-------------------------------------------------------------------------------

has '_checklist' => (
  is      => 'rw',
  # isa     => 'Bio::Metadata::Checklist',
  lazy    => 1,
  default => sub {
    my $self = shift;
    Bio::Metadata::Checklist->new( config_file => $self->{checklist_file} );
  },
);

has '_reader' => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $self = shift;
    Bio::Metadata::Reader->new( checklist => $self->_checklist );
  },
);

has '_validator' => (
  is      => 'ro',
  default => sub {
    Bio::Metadata::Validator->new;
  },
);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 validation

Displays the validation page.

=cut

sub validation : Global {
  my ( $self, $c ) = @_;

  $c->stash(
    breadcrumbs  => ['Validation'],
    jscontroller => 'validation',
    template     => 'pages/validation.tt',
    title        => 'Validation',
  );
}

#-------------------------------------------------------------------------------

=head2 validate_upload : Chained('/') PathPart('validate') Args(0)

Validates an uploaded CSV file against the HICF checklist. Returns a
stringified JSON object with two keys, C<status> and C<uploadedFile>, giving
the validation status (C<valid> or C<invalid>) and the name of the original
file:

 {
   'status:' 'valid',
   'uploadedFile:' 'original_filename.csv'
 }

If the uploaded file is invalid, the JSON object contains an additional
key, C<validatedFile>, giving a URL from which the validated file, with
error messages, may be downloaded:

 {
   'status:' 'invalid',
   'uploadedFile:' 'original_filename.csv'
   'validatedFile:' 'https://www.midasuk.org/validate/05220713-56E6-4221-83BD-AF2A7D62F832'
 }

The response will be set to status 400 (C<Bad request>) if there is no uploaded
file, 500 (C<Internal server error>) if there is a problem with handling the
uploaded file. The return status is 200 when the file is either valid or
invalid.

=cut

sub validate_upload : Chained('/') PathPart('validate') Args(0) {
  my ( $self, $c ) = @_;

  my $upload;
  unless ( $upload = $c->req->upload('csv') ) {
    $c->res->status(400); # bad request
    $c->res->body('You must upload a CSV file');
    return;
  }

  $c->log->debug('validating uploaded file')
    if $c->debug;

  # load the uploaded file into a B::M::Manifest object and validate it
  my $manifest;
  try {
    $manifest = $self->_reader->read_csv($upload->tempname);
  }
  catch {
    $c->log->error("Couldn't read uploaded file: $_");
    $c->res->status(500); # internal server error
    $c->res->body('There was a problem reading your CSV file');
    return;
  };

  my $valid;
  try {
    $valid = $self->_validator->validate( $manifest );
  }
  catch {
    $c->log->error("Couldn't validate file: $_");
    $c->res->status(500); # internal server error
    $c->res->body('There was a problem validating your CSV file');
    return;
  };

  my $response_data;

  if ( $valid ) {
    # file was valid; return a cheery "your file was valid" response and we're
    # done
    $c->log->debug( 'file was valid' )
      if $c->debug;
    $response_data = {
      status        => 'valid',
      uploadedFile  => $upload->filename,
    };
  }
  else {
    # file was invalid; write it to disk and return a URL where the client
    # can retrieve the validated file. Identify the file using a UUID
    $c->log->debug( 'file was INvalid' )
      if $c->debug;

    my $file_contents = read_file($upload->tempname, err_mode => 'quiet');
    unless ( $file_contents ) {
      $c->log->error("Couldn't read uploaded file: $!");
      $c->res->status(500); # internal server error
      $c->res->body($_);
      return;
    }

    my $uuid = Data::UUID->new->create_str;
    $c->cache->set(
      $uuid,
      {
        filename => $upload->filename,
        contents => $file_contents
      }
    );

    $c->log->debug( 'cached validated file' )
      if $c->debug;

    # return the URI for the CSV file
    $response_data = {
      status        => 'invalid',
      validatedFile => $c->uri_for('/validate', $uuid)->as_string,
      uploadedFile  => $upload->filename,
    };
  }

  # return the status information as a JSON string
  $c->stash( {
    current_view => 'JSON',
    json_data    => $response_data,
  } );
}

#-------------------------------------------------------------------------------

=head2 return_validated_file : Chained('/') PathPart('validate') Args(0)

Given a UUID, this action returns the associated validated CSV file.

=cut

sub return_validated_file : Chained('/') PathPart('validate') Args(1) {
  my ( $self, $c, $uuid ) = @_;

  # de-taint the UUID...
  unless ( $uuid =~ m/^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$/i ) {
    $c->log->error('not a valid UUID');
    $c->res->status(500); # internal server error
    $c->res->body('There was a problem reading the validated file');
    return;
  }
  # TODO convert the Bio::Metadata::Types module into a proper type library
  # TODO and get the UUID pattern from there

  my $file_hash = $c->cache->get($uuid);

  # can't do much if we didn't find the file in the cache
  unless ( defined $file_hash ) {
    $c->log->error('failed to find file in the cache');
    $c->res->status(500); # internal server error
    $c->res->body("Couldn't find validated file");
    return;
  }

  my $validated_filename = 'validated_' . $file_hash->{filename};
  my $validated_contents = $file_hash->{contents};

  unless ( $validated_contents ) {
    $c->log->error("Didn't get validated file contents from cache");
    $c->res->status(500); # internal server error
    $c->res->body('There was a problem returning your validated file');
    return;
  }

  $c->log->debug("serving validated file '$validated_filename'")
    if $c->debug;

  # return the contents of the validated file, giving the browser the actual
  # filename to save it as
  $c->res->content_type('text/csv');
  $c->res->header( 'Content-Disposition' => qq(attachment; filename="$validated_filename") );
  $c->res->body($validated_contents);
}

#-------------------------------------------------------------------------------

=encoding utf8

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
