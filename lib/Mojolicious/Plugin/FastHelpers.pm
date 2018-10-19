package Mojolicious::Plugin::FastHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util 'monkey_patch';

use constant DEBUG => $ENV{MOJO_FASTHELPERS_DEBUG} || 0;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;

  $self->_add_helper_classes;
  $self->_monkey_patch_add_helper($app);
}

sub _monkey_patch_add_helper {
  my ($self, $app) = @_;
  my $renderer = $app->renderer;

  # Add any helper that has been added already
  _add_helper_method($_) for sort map { (split /\./, $_)[0] } keys %{$renderer->helpers};

  state $patched = {};
  return if $patched->{ref($renderer)}++;

  # Add new helper methods when calling $app->helper(...)
  my $orig = $renderer->can('add_helper');
  monkey_patch $renderer => add_helper => sub {
    my ($renderer, $name) = (shift, shift);
    _add_helper_method($name);
    $orig->($renderer, $name, @_);
  };
}

sub _add_helper_classes {
  my $self = shift;

  for my $class (qw(Mojolicious Mojolicious::Controller)) {
    my $helper_class = "${class}::_FastHelpers";
    next if UNIVERSAL::isa($class, $helper_class);
    eval "package $helper_class;1" or die $@;

    monkey_patch $class => can => sub {
      my ($self, $name, @rest) = @_;
      return undef unless my $can = $self->SUPER::can($name, @rest);
      return undef if $can eq ($helper_class->can($name) // '');    # Hiding helper methods from can()
      return $can;
    };

    no strict 'refs';
    unshift @{"${class}::ISA"}, $helper_class;
  }
}

sub _add_helper_method {
  my $name = shift;
  return if Mojolicious::_FastHelpers->can($name);                  # No need to add it again

  monkey_patch 'Mojolicious::_FastHelpers' => $name => sub {
    my $app    = shift;
    my $helper = $app->renderer->get_helper($name);
    return $app->build_controller->$helper(@_);
  };

  monkey_patch 'Mojolicious::Controller::_FastHelpers' => $name => sub {
    return shift->helpers->$name(@_);
  };
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FastHelpers - Faster helpers for your Mojolicious application

=head1 SYNOPSIS

=head2 Lite app

  use Mojolicious::Lite;
  plugin "FastHelpers";
  app->start;

=head1 DESCRIPTION

L<Mojolicious::Plugin::FastHelpers> is a L<Mojolicious> plugin which can speed
up your helpers, by avoiding C<AUTOLOAD>.

It does this by injecting some new classes into the inheritance tree of
L<Mojolicious> and L<Mojolicious::Controller>.

This module is currently EXPERIMENTAL. There might even be some security
issues, so use it with care.

=head2 Benchmarks

There is a benchmark test bundled with this distribution, if you want to run it
yourself, but here is a quick overview:

  $ TEST_BENCHMARK=200000 prove -vl t/benchmark.t
  ok 1 - App::Normal 2.27925 wallclock secs ( 2.21 usr +  0.02 sys =  2.23 CPU) @ 89686.10/s (n=200000)
  ok 2 - Ctrl::Normal 0.720361 wallclock secs ( 0.70 usr +  0.01 sys =  0.71 CPU) @ 281690.14/s (n=200000)
  ok 3 - App::FastHelpers 1.9004 wallclock secs ( 1.86 usr +  0.01 sys =  1.87 CPU) @ 106951.87/s (n=200000)
  ok 4 - Ctrl::FastHelpers 0.353466 wallclock secs ( 0.35 usr +  0.01 sys =  0.36 CPU) @ 555555.56/s (n=200000)
  ok 5 - App::FastHelpers (1.87s) is not slower than App::Normal (2.23s)
  ok 6 - Ctrl::FastHelpers (0.36s) is not slower than Ctrl::Normal (0.71s)

                        Rate App::Normal App::FastHelpers Ctrl::Normal Ctrl::FastHelpers
  App::Normal        89686/s          --             -16%         -68%              -84%
  App::FastHelpers  106952/s         19%               --         -62%              -81%
  Ctrl::Normal      281690/s        214%             163%           --              -49%
  Ctrl::FastHelpers 555556/s        519%             419%          97%                --

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
