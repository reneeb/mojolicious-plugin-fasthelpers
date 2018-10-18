package Mojolicious::Plugin::FastHelpers::Controller;
use Mojo::Base 'Mojolicious::Controller';

require Mojolicious::Plugin::FastHelpers;

sub app {
  my $self = shift;
  $self->Mojolicious::Plugin::FastHelpers::_apply_helpers_from_app(@_) if @_;
  $self->SUPER::app(@_);
}

sub new {
  my $self = shift->SUPER::new(@_);
  $self->Mojolicious::Plugin::FastHelpers::_apply_helpers_from_app($self->{app}) if $self->{app};
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
