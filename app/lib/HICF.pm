
package HICF;

use Dancer2;

our $VERSION = '0.1';

get '/' => sub {
  var controller => 'index';
  template 'index';
};

get '/contact' => sub {
  var controller => 'contact';
  template 'contact', { title => 'Contact us' };
};

true;
