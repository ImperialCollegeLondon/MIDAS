
package MIDAS::Base::Controller::Restful;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST' }

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

__PACKAGE__->meta->make_immutable;

1;

