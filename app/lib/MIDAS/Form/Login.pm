package MIDAS::Form::Login;

use HTML::FormHandler::Moose;
use namespace::autoclean;

extends 'CatalystX::SimpleLogin::Form::Login';

with 'HTML::FormHandler::Widget::Theme::MidasB3';

1;

