
package MIDAS::Controller::Manifest;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MIDAS::Base::Controller::Restful' }

=head1 NAME

MIDAS::Controller::Manifest - Catalyst Controller to handle manifest data

=head1 DESCRIPTION

Catalyst Controller.

=cut

#-------------------------------------------------------------------------------

=head1 METHODS

=head2 manifests : Chained('/') Args(0) Does('NeedsAuth') ActionClass('REST::ForBrowsers')

Returns information for all manifests.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub manifests : Chained('/')
                Args(0)
                Does('NeedsAuth')
                ActionClass('REST::ForBrowsers') {
  my ( $self, $c ) = @_;
  $c->stash( manifests  => $c->model('HICFDB::Manifest')->all_manifests );
}

#---------------------------------------

sub manifests_GET {
  my ( $self, $c ) = @_;

  my $samples = [];

  while ( my $sample = $samples->next ) {
    push @$samples,
    {
      sample_id   => $sample->sample_id,
      manifest_id => $sample->manifest_id,
      created     => $sample->created_at
    };
  }

  $self->status_ok(
    $c,
    entity => $samples
  );

}

#---------------------------------------

sub manifests_GET_html {
  my ( $self, $c ) = @_;
  $c->stash( template => 'pages/samples.tt' );
}

#-------------------------------------------------------------------------------

=head2 manifest : Chained('/') Args(1) Does('NeedsAuth') ActionClass('REST::ForBrowsers')

Returns sample information. Captures a single argument, the ID of the sample.

Requires login (for requests from a browser) or HMAC authentication (for
REST calls).

=cut

sub manifest : Chained('/')
             Args(1)
             Does('NeedsAuth')
             ActionClass('REST::ForBrowsers') {}

#---------------------------------------

before manifest => sub {
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

sub manifest_GET_html {
  my ( $self, $c, $id ) = @_;

  $c->log->debug( "sample_GET_html: request for sample '$id' came from a browser" )
    if $c->debug;

  $c->stash( template => 'pages/sample.tt' );
}

#---------------------------------------

# return sample data to a non-browser client

sub manifest_GET {
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
