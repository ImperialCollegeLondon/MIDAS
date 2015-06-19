
package MIDAS::Base::Controller::Restful;

use Moose;
use namespace::autoclean;

use Text::CSV_XS;

BEGIN { extends 'Catalyst::Controller::REST' }

#-------------------------------------------------------------------------------

__PACKAGE__->config(
  default   => 'text/html',
  stash_key => 'output',
  map       => {
    'text/html'          => [ 'View', 'HTML' ],
    'application/json'   => 'JSON',
    'text/yaml'          => 'YAML',
    'text/x-yaml'        => 'YAML',
    'application/x-yaml' => 'YAML',
    'text/csv'           => [ 'Callback', { serialize => \&_render_csv } ],
  }
);

#-------------------------------------------------------------------------------

# an instance of Text::CSV_XS, used for rendering CSV output
has '_csv' => (
  is      => 'ro',
  lazy    => 1,
  default => sub { Text::CSV_XS->new; },
);

#-------------------------------------------------------------------------------

# callback to render a data structure as CSV
sub _render_csv {
  my ( $data, $controller, $c ) = @_;

  my @keys;

  # which fields should be returned in the CSV?
  if ( $controller->returned_columns ) {
    # use the fields that the controller says it will return
    @keys = @{ $controller->returned_columns };
  }
  else {
    # use all fields in the dataset, and return them in sort order
    @keys = sort keys %{ $data->[0] };
  }

  # build a header row
  my $status = $controller->_csv->combine(@keys);
  die 'problem generating CSV header' unless $status;

  my @output = ( $controller->_csv->string );

  # it's a bit ugly, but we just walk the array and dump each row in turn
  foreach my $row ( @$data ) {

    my @values = map { $row->{$_} } @{ $controller->returned_columns };

    # TODO format AMR data as a string and add it to the output

    $status = $controller->_csv->combine(@values);
    die 'problem generating CSV' unless $status;

    push @output, $controller->_csv->string;
  }

  return join "\n", @output;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

