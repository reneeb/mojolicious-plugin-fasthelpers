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
