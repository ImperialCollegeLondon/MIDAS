#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'MIDAS';
all_from 'lib/MIDAS.pm';

requires 'Catalyst::Runtime' => '5.90083';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::Store::DBIC';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::View::TT';
requires 'Catalyst::Action::REST';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Authentication::Store::DBIx::Class';
requires 'CatalystX::SimpleLogin';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
