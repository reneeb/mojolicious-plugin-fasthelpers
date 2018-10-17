package Mojolicious::Plugin::FastHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw(md5_sum monkey_patch);

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;
  my @helpers = sort keys %{$app->renderer->helpers};

  my $app_class = join '::', ref($app), FastHelpers => md5_sum(join '::', @helpers);
  $self->_make_class($app, $app_class, ref($app), \@helpers) unless $app_class->can('new');
  bless $app, $app_class;

  my $controller_class = join '::', 'Mojolicious::Controller::FastHelpers', md5_sum(join '::', @helpers);
  $self->_make_class($app, $controller_class, $app->controller_class, \@helpers) unless $controller_class->can('new');
  $app->controller_class($controller_class);
}

sub _make_class {
  my ($self, $app, $class, $isa, $helpers) = @_;

  eval <<"HERE";
  package $class;
  use Mojo::Base "$isa";
  1;
HERE

  for my $name (@$helpers) {
    my ($method) = split /\./, $name;
    if ($class->isa('Mojolicious::Controller')) {
      monkey_patch $class, $method => $app->renderer->get_helper($method);
    }
    else {
      monkey_patch $class, $method => sub {
        my $app    = shift;
        my $helper = $app->renderer->get_helper($method);
        $app->build_controller->$helper(@_);
      };
    }
  }
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FastHelpers - Faster helpers for your Mojolicious application

=head1 SYNOPSIS

  use Mojolicious::Lite;

  # Add your helpers
  helper "what.ever" => sub { return 42 };

  # Need to be called after all helpers have been added
  plugin "FastHelpers";
  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::FastHelpers> is a L<Mojolicious> plugin which can speed
up your helpers, by avoiding C<AUTOLOAD>.

=head1 METHODS

=head2 register

Will create new classes for your application and
L<Mojolicious/controller_class>, and monkey patch in all the helpers.

=head1 AUTHOR

Jan Henning Thorsen

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicious>

=cut
