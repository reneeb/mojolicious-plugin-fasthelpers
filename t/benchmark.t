use Mojo::Base -strict;
use Test::More;
use Benchmark qw(cmpthese timeit timestr :hireswallclock);
use Mojolicious;

plan skip_all => 'TEST_BENCHMARK=10000' unless my $n_times = $ENV{TEST_BENCHMARK};

my %tests = (fast_app => app(), normal_app => app());
my %res;

$tests{fast_app}->plugin('FastHelpers');
$tests{fast_controller}   = $tests{fast_app}->build_controller;
$tests{normal_controller} = $tests{normal_app}->build_controller;

for my $name (sort keys %tests) {
  my $obj = $tests{$name};
  my $res = 0;
  $res{$name} = timeit $n_times, sub { $res += $obj->dummy };
  is $res, 42 * $n_times, sprintf '%s %s', $name, timestr $res{$name};
}

compare(qw(fast_app normal_app));
compare(qw(fast_controller normal_controller));
cmpthese(\%res) if $ENV{HARNESS_IS_VERBOSE};

done_testing;

sub app {
  my $app = Mojolicious->new;
  $app->helper(dummy => sub {42});
  $app;
}

sub compare {
  my ($an, $bn) = @_;
  return diag "Cannot compare $an and $bn" unless my $ao = $res{$an} and my $bo = $res{$bn};
  ok $ao->cpu_a <= $bo->cpu_a, sprintf '%s (%ss) is not slower than %s (%ss)', $an, $ao->cpu_a, $bn, $bo->cpu_a;
}
