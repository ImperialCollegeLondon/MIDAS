
package HICF;

use Dancer2;

our $VERSION = '0.1';

set port => 8000;

get '/' => sub {
  var controller => 'index';
  template 'index';
};

get '/validation'  => \&_validation;
get '/validation/' => \&_validation;

sub _validation {
  var controller => 'validation';

  template 'validation', {
                        title       => 'Validation',
                        breadcrumbs => [ 'Validation' ]
                      };
}

get '/contact'  => \&_contact;
get '/contact/' => \&_contact;

sub _contact {
  var controller => 'contact';

  template 'contact', {
                        title       => 'Contact us',
                        breadcrumbs => [ 'Contact us' ]
                      };
}

true;
