package MIDAS::Controller::Sample;
use Moose;
use namespace::autoclean;

use TryCatch;

BEGIN { extends 'Catalyst::Controller::REST' }

=head1 NAME

MIDAS::Controller::Sample - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=cut

#-------------------------------------------------------------------------------

__PACKAGE__->config(
  default => 'text/html',
  map     => {
    'text/html'          => [ 'View', 'HTML' ],
    'application/json'   => 'JSON',
    'text/yaml'          => 'YAML',
    'text/x-yaml'        => 'YAML',
    'application/x-yaml' => 'YAML',
  }
);

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 begin

=cut

# sub begin : Private {
#   my ( $self, $c ) = @_;
#
#   # at this point we're unauthenticated
#
#   $c->log->debug( 'begin: in begin method' )
#     if $c->debug;
# }

#-------------------------------------------------------------------------------

# sub auto : Private {
#   my ( $self, $c ) = @_;
#
#   # at this point we're unauthenticated
#
#   $c->log->debug( 'auto: in auto method' )
#     if $c->debug;
#
#   return 1;
# }

#-------------------------------------------------------------------------------

=head2 sample : Path Args(1) Does('NeedsAuth') ActionClass('REST::ForBrowsers')

Returns sample information. Captures a single argument, the ID of the sample.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub sample : Path
             Args(1)
             Does('NeedsAuth')
             ActionClass('REST::ForBrowsers') {}

#---------------------------------------

before sample => sub {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "before sample: AUTHENTICATED; retrieving sample data for '$id'" )
    if $c->debug;

  # at this point the user is authenticated, either via login or session if the
  # request came from a browser, or via an HMAC in the "Authorization" header

  my $sample = $c->model('HICFDB::Sample')
                 ->find( { sample_id => $id } );


  if ( defined $sample ) {
    $c->log->debug( 'before sample: stashing sample row' )
      if $c->debug;
    $c->stash( id     => $id,
               sample => $sample );
  }
  else {
    $c->log->warn( 'before sample: no such sample; stashing error message' )
      if $c->debug;
    $c->stash( id    => $id,
               error => 'no such sample' );
  }
};

#---------------------------------------

# return sample data to a browser

sub sample_GET_html {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "sample_GET_html: request for sample '$id' came from a browser" )
    if $c->debug;

  $c->stash( template => 'pages/sample.tt' );
}

#---------------------------------------

# return sample data to a non-browser client

sub sample_GET {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "sample_GET: request for sample '$id' did not come from a browser" )
    if $c->debug;

  if ( defined $c->stash->{sample} ) {
    $self->status_ok(
      $c,
      entity => $c->stash->{sample}->get_fields
    );
  }
  else {
    $self->status_not_found(
      $c,
      message => $c->stash->{error}
    );
  }

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
