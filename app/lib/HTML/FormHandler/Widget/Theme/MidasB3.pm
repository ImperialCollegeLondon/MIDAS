package HTML::FormHandler::Widget::Theme::MidasB3;

use Moose::Role;

with 'HTML::FormHandler::Widget::Theme::Bootstrap3';

sub build_update_subfields {
  print STDERR "***************************************** build_update_subfields\n";

  return {
    username => {
      label_class => [ 'col-sm-2' ],
      wrapper_class => [ 'col-sm-8' ],
    },
    password => {
      label_class => [ 'col-sm-2' ],
      wrapper_class => [ 'col-sm-8' ],
    },
    remember => {
      element_class => [ 'col-sm-offset-2' ],
      wrapper_class => [ 'col-sm-8' ],
    },
    submit => {
      label_class => [ 'col-sm-offset-2', 'col-sm-10' ],
      wrapper_class => [ 'col-sm-8' ],
    },
  };
}

1;

