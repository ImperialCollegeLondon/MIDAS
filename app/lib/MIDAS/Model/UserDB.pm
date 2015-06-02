package MIDAS::Model::UserDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'Bio::HICF::User',
    
    
);

=head1 NAME

MIDAS::Model::UserDB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<MIDAS>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Bio::HICF::User>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.65

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
