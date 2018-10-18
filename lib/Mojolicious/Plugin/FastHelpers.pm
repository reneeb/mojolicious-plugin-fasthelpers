package Mojolicious::Plugin::FastHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw(md5_sum monkey_patch);
use Mojolicious::Plugin::FastHelpers::Controller;

use constant DEBUG => $ENV{MOJO_FASTHELPERS_DEBUG} || 0;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;
  bless $app, _generate_class_with_helpers($app, $app);

  $app->controller_class(_generate_class_with_helpers($app->controller_class, $app))
    unless $app->controller_class->isa('Mojolicious::Plugin::FastHelpers::Controller');
}

sub _generate_class_with_helpers {
  my ($target, $app) = @_;
  my @helpers    = sort keys %{$app->renderer->helpers};
  my $superclass = ref $target || $target;
  my $new_class  = join '::', $superclass, '__FAST__', md5_sum(join '::', @helpers);

  # Already generated
  return $new_class if $new_class->can('new');

  warn qq/[FastHelpers] $new_class->isa("$superclass")\n/ if DEBUG;
  eval qq(package $new_class;use Mojo::Base "$superclass";1) or die $@;
  my %hidden;
  for my $name (keys %{$app->renderer->helpers}) {
    my ($method) = split /\./, $name;
    if ($new_class->can($method)) {
      warn qq/[FastHelpers] $new_class->can("$method")\n/ if DEBUG;
    }
    elsif ($new_class->isa('Mojolicious::Controller')) {
      $hidden{$name} = 1;
      monkey_patch $new_class, $method => $app->renderer->get_helper($method);
    }
    else {
      $hidden{$name} = 1;
      monkey_patch $new_class, $method => sub {
        my $app    = shift;
        my $helper = $app->renderer->get_helper($method);
        $app->build_controller->$helper(@_);
      };
    }
  }

  # Speed up $c->app() by avoiding Mojolicious::Plugin::FastHelpers::Controller->app()
  $new_class->attr('app') if $new_class->isa('Mojolicious::Controller');

  # Hide helpers
  monkey_patch $new_class, can => sub { return $hidden{$_[1]} ? undef : $_[0]->SUPER::can($_[1]) };

  return $new_class;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FastHelpers - Faster helpers for your Mojolicious application

=head1 SYNOPSIS

=head2 Lite app

  use Mojolicious::Lite;

  # Add your helpers
  helper "what.ever" => sub { return 42 };

  # Need to be called after all helpers have been added
  plugin "FastHelpers";
  app->start;

=head2 Full app

  package MyApp;
  use Mojo::Base "Mojolicious";

  sub startup {
    my $app = shift;

    # Add your helpers
    $app->helper(whatever => sub { rand });

    # Need to be called after all helpers have been added
    $app->plugin("FastHelpers");
  }

  package MyApp::Controller::Test;

  # Need to inherit from Mojolicious::Plugin::FastHelpers::Controller
  # instead of Mojolicious::Controller
  use Mojo::Base "Mojolicious::Plugin::FastHelpers::Controller";

  # Add actions as you would normally do
  sub my_action {
    my $c = shift;
    ...
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::FastHelpers> is a L<Mojolicious> plugin which can speed
up your helpers, by avoiding C<AUTOLOAD>.

This module is currently EXPERIMENTAL. There might even be some security
isseus, so use it with care.

=head2 Benchmarks

There is a benchmark test bundled with this distribution, if you want to run it
yourself, but here is a quick overview:

  $ TEST_BENCHMARK=200000 prove -vl t/benchmark.t
  ok 1 - fast_app 1.81834 wallclock secs ( 1.81 usr +  0.00 sys =  1.81 CPU) @ 110497.24/s (n=200000)
  ok 2 - fast_controller 0.0192509 wallclock secs ( 0.02 usr +  0.00 sys =  0.02 CPU) @ 10000000.00/s (n=200000)
  ok 3 - normal_app 2.02593 wallclock secs ( 2.02 usr +  0.00 sys =  2.02 CPU) @ 99009.90/s (n=200000)
  ok 4 - normal_controller 0.619834 wallclock secs ( 0.62 usr +  0.00 sys =  0.62 CPU) @ 322580.65/s (n=200000)
  ok 5 - fast_app (1.81s) is not slower than normal_app (2.02s)
  ok 6 - fast_controller (0.02s) is not slower than normal_controller (0.62s)

                          Rate normal_app fast_app normal_controller fast_controller
  normal_app           99010/s         --     -10%              -69%            -99%
  fast_app            110497/s        12%       --              -66%            -99%
  normal_controller   322581/s       226%     192%                --            -97%
  fast_controller   10000000/s     10000%    8950%             3000%              --

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
