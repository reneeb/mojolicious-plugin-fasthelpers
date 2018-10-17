use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious;
use Mojolicious::Controller;
use Mojo::Util 'monkey_patch';

monkey_patch 'Mojolicious'             => AUTOLOAD => sub { die 'Should never come to this' };
monkey_patch 'Mojolicious::Controller' => AUTOLOAD => sub { die 'Should never come to this' };

my $app = Mojolicious->new;
$app->helper('answer'    => sub {42});
$app->helper('what.ever' => sub {shift});
$app->plugin('FastHelpers');
like ref($app), qr/^Mojolicious::FastHelpers::\w{32}/, 'manipulated app';
like $app->controller_class, qr/^Mojolicious::Controller::FastHelpers::\w{32}/, 'manipulated controller_class';
is $app->answer, 42, 'answer';
isa_ok $app->what->ever, $app->controller_class, 'got what.ever';

my $same_helpers = Mojolicious->new;
$same_helpers->helper('what.ever' => sub {shift});
$same_helpers->helper('answer'    => sub {42});
$same_helpers->plugin('FastHelpers');
isa_ok ref($same_helpers), ref($app), 'same app class';
is $same_helpers->controller_class, $app->controller_class, 'same controller_class';

my $not_same_helpers = Mojolicious->new;
$not_same_helpers->helper('what.ever' => sub {shift});
$not_same_helpers->helper('what.not'  => sub {41});
$not_same_helpers->helper('answer'    => sub {42});
$not_same_helpers->plugin('FastHelpers');
isnt ref($not_same_helpers), ref($app), 'not same controller_class';
isnt $not_same_helpers->controller_class, $app->controller_class, 'not same controller_class';

done_testing;
