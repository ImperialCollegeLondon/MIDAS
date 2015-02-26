package MIDAS::Controller::Auth;
use Moose;
use namespace::autoclean;

use MIDAS::Form::Login;

BEGIN { extends 'CatalystX::SimpleLogin::Controller::Login'; }

=head1 NAME

MIDAS::Controller::Auth - handles user login

=head1 DESCRIPTION

A controller to handle user authentication and authorization.

#-------------------------------------------------------------------------------

=head1 ATTRIBUTES

=head2 login_form_class

Use a custom form class to render the login form.

=cut

has '+login_form_class' => (
  default => 'MIDAS::Form::Login'
);

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
