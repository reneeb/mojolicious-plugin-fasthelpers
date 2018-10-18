package Mojolicious::Plugin::FastHelpers::Controller;
use Mojo::Base 'Mojolicious::Controller';

require Mojolicious::Plugin::FastHelpers;

our %FF;    # Consider this internal

sub app {
  my $self = shift;

  if (@_) {
    my $key = join '::', ref $self, $_[0];
    bless $self, $FF{$key} ||= Mojolicious::Plugin::FastHelpers::_generate_class_with_helpers($self, $_[0]);
  }

  $self->SUPER::app(@_);
}

sub new {
  my $self = shift->SUPER::new(@_);

  if ($self->{app}) {
    my $key = join '::', ref $self, $self->{app};
    bless $self, $FF{$key} ||= Mojolicious::Plugin::FastHelpers::_generate_class_with_helpers($self, $self->{app});
  }

  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::FastHelpers::Controller - Base class for fast controllers

=head1 SYNOPSIS

See L<Mojolicious::Plugin::FastHelpers/SYNOPSIS>.

=head1 DESCRIPTION

L<Mojolicious::Plugin::FastHelpers::Controller> is a substitute for
L<Mojolicious::Controller>, if you want your controllers to be fast.

=head1 METHODS

=head2 app

  $app = $self->app;
  $self = $self->app(Mojolicious->new);

Overrides L<Mojolicious::Controller/app> and applies the helpers from the
C<$app> as native methods.

=head2 new

  $self = Mojolicious::Plugin::FastHelpers::Controller->new(app => $app, ...);
  $self = Mojolicious::Plugin::FastHelpers::Controller->new({app => $app, ...});

See L</app>

=head1 SEE ALSO

L<Mojolicious::Plugin::FastHelpers>.

=cut
