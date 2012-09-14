use strict;
use warnings;
use Test::More 0.96;
use Test::Routine;
use Test::Routine::Util;

use Config::MVP::Writer::INI ();

has args => (
  is          => 'ro',
  isa         => 'HashRef',
  default     => sub { +{} },
);

has sections => (
  is          => 'ro',
  isa         => 'ArrayRef',
);

has expected_ini => (
  is          => 'ro',
  isa         => 'Str',
);

test ini_format => sub {
  my ($self) = @_;

  #my $writer = Config::MVP::Writer::INI->new($self->args);
  #my $ini = $writer->write_string($self->sections);
  my $string = Config::MVP::Writer::INI->string($self->sections);

  is $string, $self->expected_ini, 'ini string formatted as expected';
};

run_me({
  sections => [
    # name, class-suffix, config
    [Moniker => Name => {}],
    [Ducky => Rubber => {
      feathers => 'yellow',
      orange => ['feet', 'beak'],
    }],
    [Pizza => Pizza => ],
  ],
  expected_ini => <<INI,
[Name / Moniker]

[Rubber / Ducky]
feathers = yellow
orange   = feet
orange   = beak

[Pizza / Pizza]
INI
});

done_testing;
