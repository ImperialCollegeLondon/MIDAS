
package HICF;

use Dancer2;

our $VERSION = '0.1';

set port => 8000;

get '/' => sub {
  var controller => 'index';
  template 'index';
};

get '/contact' => sub {
  var controller => 'contact';

  template 'contact', { 
                        title       => 'Contact us', 
                        breadcrumbs => [ 'Contact us' ] 
                      };
};

true;
