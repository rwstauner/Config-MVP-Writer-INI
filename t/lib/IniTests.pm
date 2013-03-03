use strict;
use warnings;

package # no_index
  IniTests;

use Test::More 0.96;
use Test::Differences;
use Test::Routine;
use MooseX::AttributeShortcuts;

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
  predicate   => 1,
);

test newlines => sub {
  my ($self) = @_;

  like   $self->ini_string, qr/\A[^\n]/,   'no newline at beginning';
  unlike $self->ini_string, qr/\n{3,}/,    'no more than two sequential newlines';
  like   $self->ini_string, qr/[^\n]\n\z/, 'single newline at end';
};

test string_eq => sub {
  my ($self) = @_;

  plan skip_all => 'expected_ini required'
    unless $self->has_expected_ini;

  eq_or_diff
    $self->ini_string,
    $self->expected_ini,
    'ini string formatted as expected';
};

1;
