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

  # Change method to attr for extra speed
  Mojolicious::Controller->attr(helpers => sub { $_[0]->app->renderer->get_helper('')->($_[0]) });
}

sub _add_helper_method {
  my $name = shift;
  return if Mojolicious::_FastHelpers->can($name);    # No need to add it again

  monkey_patch 'Mojolicious::_FastHelpers' => $name => sub {
    my $app = shift;
    Carp::croak qq/Can't locate object method "$name" via package "@{[ref $app]}"/
      unless my $helper = $app->renderer->get_helper($name);
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
  ok 1 - App::Normal 2.1569 wallclock secs ( 2.13 usr +  0.01 sys =  2.14 CPU) @ 93457.94/s (n=200000)
  ok 2 - Ctrl::Normal 0.772035 wallclock secs ( 0.75 usr +  0.00 sys =  0.75 CPU) @ 266666.67/s (n=200000)
  ok 3 - App::FastHelpers 1.63732 wallclock secs ( 1.62 usr +  0.01 sys =  1.63 CPU) @ 122699.39/s (n=200000)
  ok 4 - Ctrl::FastHelpers 0.131679 wallclock secs ( 0.13 usr +  0.00 sys =  0.13 CPU) @ 1538461.54/s (n=200000)
  ok 5 - App::FastHelpers (1.63s) is not slower than App::Normal (2.14s)
  ok 6 - Ctrl::FastHelpers (0.13s) is not slower than Ctrl::Normal (0.75s)

                         Rate App::Normal App::FastHelpers Ctrl::Normal Ctrl::FastHelpers
  App::Normal         93458/s          --             -24%         -65%              -94%
  App::FastHelpers   122699/s         31%               --         -54%              -92%
  Ctrl::Normal       266667/s        185%             117%           --              -83%
  Ctrl::FastHelpers 1538462/s       1546%            1154%         477%                --

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
