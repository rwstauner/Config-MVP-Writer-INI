use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Test::Routine;
use Test::Routine::Util;
with 'IniTests';

run_me(basic => {
  args => {
    rewrite_package => sub { $_[0] =~ /Mod::(.+)/ ? $1 : $_[0] },
  },
  sections => [
    # name, package, payload
    [Name => 'Mod::Package' => {}],
    [Ducky => Rubber => {
      feathers => 'yellow',
      orange => ['feet', 'beak'],
    }],
    [Pizza => 'Mod::Pizza' => ],
    [Donkey => 'Mod::Donuts' => ],
    [CokeBear => 'Mod::CokeBear' => {':version' => '1.002023'}],
    [MASH => MASH => {':rum' => 'cookies', section => 8}],
    [SomethingElse => {with => 'a config'}],
    [AllTheSame => ],
    'EvenMore::TheSame' =>
    'Mod::NoArray' =>
    [EndWithConfig => EWC => {foo => [qw( bar baz )]}],
  ],
  expected_ini => <<INI,
[Package / Name]

[Rubber / Ducky]
feathers = yellow
orange   = feet
orange   = beak

[Pizza]
[Donuts / Donkey]

[CokeBear]
:version = 1.002023

[MASH]
:rum    = cookies
section = 8

[SomethingElse]
with = a config

[AllTheSame]
[EvenMore::TheSame]
[NoArray / Mod::NoArray]

[EWC / EndWithConfig]
foo = bar
foo = baz
INI
});

run_me('no payloads; ends with single newline' => {
  sections => [qw(Foo Bar)],
  expected_ini => "[Foo]\n[Bar]\n",
});

done_testing;
