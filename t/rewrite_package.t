use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use Test::Routine::Util;

sub test_rewrite {
  my ($desc, $sub, $exp) = @_;

  $exp =~ s/^  //mg;

  run_tests($desc => IniTests => {
    args => {
      rewrite_package => $sub,
    },
    sections => [
      [ The => Resolution => {} ],
      [ Orphans => Caves => ],
      [ Miss => 'Miss::California' ],
    ],
    expected_ini => $exp,
  });
}

test_rewrite 'first arg $_[0]' => sub { $_[0] =~ /::/ ? $_[0] : "+$_[0]" }, <<INI;
  [+Resolution / The]
  [+Caves / Orphans]
  [Miss::California / Miss]
INI

test_rewrite 'modification of $_' => sub { s/.+:://; $_ }, <<INI;
  [Resolution / The]
  [Caves / Orphans]
  [California / Miss]
INI

test_rewrite 'naughty modification of $_[0]' => sub { $_[0] =~ s/^([A-Z])/$1_/; $_[0] }, <<INI;
  [R_esolution / The]
  [C_aves / Orphans]
  [M_iss::California / Miss]
INI

done_testing;
