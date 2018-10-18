use Mojo::Base -strict;
use Test::Mojo;
use Test::More;
use Mojolicious;

my $app = Mojolicious->new;
$app->controller_class(make_base_controller());
$app->plugin('FastHelpers');

like $app->controller_class, qr{MyApp::Controller::Base::__FAST__::\w+}, 'custom controller_class';

done_testing;

sub make_base_controller {
  return eval <<'HERE' || die $@;
  package MyApp::Controller::Base;
  use base 'Mojolicious::Controller';
  'MyApp::Controller::Base';
HERE
}
