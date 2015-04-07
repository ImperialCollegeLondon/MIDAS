package MIDAS;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

# Set flags and add plugins for the application.
#
# Note that ORDERING IS IMPORTANT here as plugins are initialized in order,
# therefore you almost certainly want to keep ConfigLoader at the head of the
# list if you're using it.
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a Config::General file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/
    ConfigLoader
    Authentication
    Session
    Session::Store::File
    Session::State::Cookie
    Static::Simple
/;

with 'CatalystX::DebugFilter';

extends 'Catalyst';

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in midas.conf (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with an external configuration file acting as an override for
# local deployment.

#-------------------------------------------------------------------------------
#- configuration ---------------------------------------------------------------
#-------------------------------------------------------------------------------

__PACKAGE__->config(

  name => 'MIDAS',

  # disable deprecated behavior needed by old applications
  disable_component_resolution_regex_fallback => 1,

  # DON'T send X-Catalyst header
  enable_catalyst_header => 0,

  # default to saying we're running behind a proxy; disable in the config file
  # if that's not true, e.g. for dev/testing
  using_frontend_proxy => 1,

  #-----------------------------------------------------------------------------
  # models

  'Model::HICFDB' => {
    schema_class => 'Bio::HICF::Schema',
    connect_info => {
      dsn => 'dbi:SQLite:dbname=t/data/test.db'
    },
  },

  #-----------------------------------------------------------------------------
  # views

  'View::HTML' => {
    INCLUDE_PATH => [
      __PACKAGE__->path_to( 'root', 'templates' ),
    ],
  },

  #-----------------------------------------------------------------------------
  # controllers

  'Controller::Login' => {
    traits => ['-RenderAsTTTemplate'],
  },

  #-----------------------------------------------------------------------------
  # plugins and extensions
  
  'Plugin::ConfigLoader' => {
    file => 'midas.conf'
  },

  # look for static content in the tmp directory used by lots of grunt tasks
  # and THEN in the static content directory in the app. Necessary to allow
  # the development server to be run under LiveReload
  'Plugin::Static::Simple' => {
    include_path => [
      __PACKAGE__->config->{home} . '/../.tmp',
      __PACKAGE__->config->{root} . '/static',
    ],
  },

  'Plugin::Authentication' => {
    default_realm => 'db',
    plain => {
      credential => {
        class => 'Password',
        password_field => 'password',
        password_type => 'clear',
      },
      store => {
        class => 'Minimal',
        users => {
          alice => {
            name => 'Alice',
            password => 'alicepass',
            roles => [ qw( admin user ) ]
          },
          bob => {
            name => 'Bob',
            password => 'bobpass',
            roles => [ qw( user ) ]
          },
        }
      }
    },
    db => {
      credential => {
        class => 'Password',
        password_field => 'password',
        password_type => 'self_check',
      },
      store => {
        class => 'DBIx::Class',
        user_model => 'HICFDB::User',
        role_field => 'roles',
        # TODO implement a separate roles table ?
        # role_relation => 'roles',
      }
    }
  },

  # filter debug logs to remove passwords
  'CatalystX::DebugFilter' => {
    Request => { params => [ 'password' ] },
  }
);

#-------------------------------------------------------------------------------

# Start the application
__PACKAGE__->setup();

=encoding utf8

=head1 NAME

MIDAS - Catalyst based application

=head1 SYNOPSIS

    script/midas_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<MIDAS::Controller::Root>, L<Catalyst>

=head1 AUTHOR

John Tate

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
