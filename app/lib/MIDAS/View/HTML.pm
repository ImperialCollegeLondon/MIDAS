package MIDAS::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt',
  ENCODING           => 'utf-8',
  WRAPPER            => 'wrapper.tt',
  render_die         => 1,
);

=head1 NAME

MIDAS::View::HTML - TT View for MIDAS

=head1 DESCRIPTION

TT View for MIDAS.

=head1 SEE ALSO

L<MIDAS>

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
