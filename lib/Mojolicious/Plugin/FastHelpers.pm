package Mojolicious::Plugin::FastHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Util qw(md5_sum monkey_patch);
use Mojolicious::Plugin::FastHelpers::Controller;

use constant DEBUG => $ENV{MOJO_FASTHELPERS_DEBUG} || 0;

our $VERSION = '0.01';

sub register {
  my ($self, $app, $config) = @_;
  _apply_helpers_from_app($app, $app);
  $app->controller_class('Mojolicious::Plugin::FastHelpers::Controller');
}

sub _apply_helpers_from_app {
  my ($target, $app) = @_;
  my @helpers    = sort keys %{$app->renderer->helpers};
  my $superclass = ref $target || $target;
  my $new_class  = join '::', $superclass, '__FAST__', md5_sum(join '::', @helpers);

  unless ($new_class->can('new')) {
    warn qq/[FastHelpers] $new_class->isa("$superclass")\n/ if DEBUG;
    eval qq(package $new_class;use Mojo::Base "$superclass";1) or die $@;
    _monkey_patch_class($new_class, $app);
  }

  bless $target, $new_class;
}

sub _monkey_patch_class {
  my ($target, $app) = @_;

  for my $name (keys %{$app->renderer->helpers}) {
    my ($method) = split /\./, $name;
    if ($target->can($method)) {
      warn qq/[FastHelpers] $target->can("$method")\n/ if DEBUG;
    }
    elsif ($target->isa('Mojolicious::Controller')) {
      monkey_patch $target, $method => $app->renderer->get_helper($method);
    }
    else {
      monkey_patch $target, $method => sub {
        my $app    = shift;
        my $helper = $app->renderer->get_helper($method);
        $app->build_controller->$helper(@_);
      };
    }
  }

  # Speed up $c->app() by avoiding Mojolicious::Plugin::FastHelpers::Controller->app()
  $target->attr('app') if $target->isa('Mojolicious::Controller');
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
