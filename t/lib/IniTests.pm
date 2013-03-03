use strict;
use warnings;

package # no_index
  IniTests;

use Test::More 0.96;
use Test::Differences;
use Test::Routine;

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

has ini_string => (
  is          => 'lazy',
  isa         => 'Str',
  init_arg    => undef,
  default     => sub {
    my ($self) = @_;
    $self->writer->ini_string($self->sections);
  },
);

has writer => (
  is          => 'lazy',
  isa         => 'Config::MVP::Writer::INI',
  default     => sub {
    Config::MVP::Writer::INI->new($_[0]->args);
  },
);

has expected_ini => (
  is          => 'ro',
  isa         => 'Str',
);

test string_eq => sub {
  my ($self) = @_;

  eq_or_diff
    $self->ini_string,
    $self->expected_ini,
    'ini string formatted as expected';
};

1;
