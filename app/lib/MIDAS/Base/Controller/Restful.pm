
package MIDAS::Base::Controller::Restful;

use Moose;
use namespace::autoclean;

use Text::CSV_XS;

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

MIDAS::Base::Controller::Resful - base class to set up serialisation for REST

=head1 DESCRIPTION

This is a base class for controllers implementing RESTful endpoints. It provides
methods to serialise data in CSV, which are required in order to handle AMR
data properly.

=cut

#-------------------------------------------------------------------------------

# set up Catalyst::Controller::REST. The main item here is the addition of the
# callback for "text/csv", which points to the bespoke method here

__PACKAGE__->config(
  # default   => 'text/html',
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
#- attributes ------------------------------------------------------------------
#-------------------------------------------------------------------------------

=head1 ATTRIBUTES

=cut

# an instance of Text::CSV_XS, used for rendering CSV output
has '_csv' => (
  is      => 'ro',
  lazy    => 1,
  default => sub { Text::CSV_XS->new; },
);

=head2 returned_columns

Read-only attribute that stores a reference to an array containing the list of
columns that will be returned by "_render_csv".

=cut

has 'returned_columns' => (
  is      => 'ro',
  default => sub {
    [ qw(
      sample_id
      manifest_id
      raw_data_accession
      sample_accession
      sample_description
      collected_at
      tax_id
      scientific_name
      collected_by
      source
      collection_date
      location
      host_associated
      specific_host
      host_disease_status
      host_isolation_source
      patient_location
      isolation_source
      serovar
      other_classification
      strain
      isolate
    ) ];
  }
);

#-------------------------------------------------------------------------------
#- private methods -------------------------------------------------------------
#-------------------------------------------------------------------------------

# callback to render a data structure as CSV
sub _render_csv {
  my ( $data, $controller, $c ) = @_;

  # some data, such as the summary information, can't really be serialised to
  # CSV because it's not a simple list of columns
  unless ( ref $data eq 'ARRAY' ) {
    $c->res->status(415); # Unsupported Media Type
    return 'Cannot serialise this output as text/csv; try application/json';
  }

  # use the fields that the controller says it will return
  my @keys = @{ $controller->returned_columns };

  # build a header row
  my $status = $controller->_csv->combine(@keys, 'amr');
  die 'problem generating CSV header' unless $status;

  my @output = ( $controller->_csv->string );

  # it's a bit ugly, but we just walk the array and dump each row in turn
  foreach my $row ( @$data ) {

    my @values = map { $row->{$_} } @{ $controller->returned_columns };
    push @values, _format_amr($row->{amr});

    $status = $controller->_csv->combine(@values);
    die 'problem generating CSV' unless $status;

    push @output, $controller->_csv->string;
  }

  return join "\n", @output;
}

#-------------------------------------------------------------------------------

# formats the antimicrobial resistance test results for the given row
sub _format_amr {
  my ( $amrs ) = shift;

  my @amrs = ();
  foreach my $amr ( @$amrs ) {
    my $amr_string .= $amr->{antimicrobial_name} . ';'
                   .  $amr->{susceptibility} . ';'
                   .  ( $amr->{equality} eq 'eq' ? '' : $amr->{equality} )
                   .  $amr->{mic};

    $amr_string .= ';' . $amr->{diagnostic_centre} if $amr->{diagnostic_centre};

    push @amrs, $amr_string;
  }

  return join ',', @amrs;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

