# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Config::MVP::Writer::INI;
# ABSTRACT: Build an INI file for Config::MVP

use Moose;
use Moose::Util::TypeConstraints;
use List::AllUtils ();

has spacing => (
  is         => 'ro',
  isa        => enum([qw( none all payload )]),
  default    => 'payload',
);

=for comment
has simplify_bundles => (
  is         => 'ro',
  isa        => union([qw( ArrayRef Bool )]),
);
=cut

has _rewrite_package => (
  is         => 'ro',
  isa        => 'CodeRef',
  traits     => ['Code'],
  init_arg   => 'rewrite_package',
  predicate  => 'can_rewrite_package',
  handles    => {
    rewrite_package => 'execute',
  },
);

sub ini_string {
  my ($self, $sections) = @_;

  # TODO: @$sections = $self->_simplify_bundles(@$sections) if configured

  my @strings = map { $self->_ini_section($_) } @$sections;

  my $spacing = $self->spacing;

  if( $spacing eq 'all' ){
    # put a blank line after each section
    @strings = map { "$_\n" } @strings;
  }
  elsif( $spacing eq 'payload' ){
    # put a blank line around any section with a payload
    @strings = map { /\n.+/ ? "\n$_\n" : $_ } @strings;
  }

  my $ini = join '', @strings;

  # don't need to start with a newline
  $ini =~ s/\A\n+//;
  # don't need more than two together (single blank line)
  $ini =~ s/(?<=\n\n)\n+//g;
  # one newline at the end is sufficient
  $ini =~ s/\n*\z/\n/;

  return $ini;
}

sub _ini_section {
  my ($self, $section) = @_;

  # break the reference, make one if we don't have one
  $section = ref($section) eq 'ARRAY' ? [@$section] : [$section];

  my $config  = ref($section->[-1]) eq 'HASH' ? pop @$section : {};
  my $name    = shift @$section;
  my $package = shift @$section || $name;

  if( $self->can_rewrite_package ){
    # copy the value and offer it as $_
    local $_ = $package;
    # only use if something was returned
    $package = $self->rewrite_package($_) || $package;
  }

  # FIXME: this handles the bundle prefix but not the whole moniker (class suffix)
  # NOTE: I forgot what this ^^ means
  my $ini = "[$package" . ($name =~ m{^([^/]+/)*\Q$package\E$} ? '' : " / $name") . "]\n";

  $ini .= $self->_ini_section_config($config);

  return $ini;
}

    # TODO: rewrite_package
    # reverse RewritePrefix
    #$package =~ s/Dist::Zilla::(Plugin(Bundle)?)::/$2 ? '@' : ''/e
      #or $package = "=$package";

sub _simplify_bundles {
  my ($self, @sections) = @_;

  my @simplified;
  # for specified bundles just show [@Bundle] instead of each plugin
  #my %bundles = map { ($_ => 0) } @{ $opts->{bundles} || [] };
  my %bundles;

  foreach my $section ( @sections ){
    my ($name) = @$section;
    # just list the bundle not each individual plugin
    foreach my $bundle ( keys %bundles ){
      if( $name =~ /\@${bundle}\b/ ){
        push @simplified, '@' . $bundle
          unless $bundles{ $bundle }++;
        next;
      }
      else {
        push @simplified, $section;
      }
    }
  }

  return @simplified;
}

sub _ini_section_config {
  my ($self, $config) = @_;

  return ''
    unless $config && scalar keys %$config;

  my @lines;
  my $len = List::AllUtils::max(map { length } keys %$config);

    foreach my $k ( sort keys %$config ){
      my $v = $config->{ $k };
      $v = '' if !defined $v;
      push @lines,
        # don't end a line with "=\x20" (when the value is '')
        map { sprintf "%-*s =%s\n", $len, $k, (length($_) ? ' ' . $_ : '') }
          # one k=v line per array item
          ref $v eq 'ARRAY'
            ? @$v
            # if there are newlines, assume 1 k=v per line
            : $v =~ /\n/
              # but skip blanks
              ? grep { $_ } split /\n/, $v
              # just one plain k=v line
              : $v
    }

  return join '', @lines;
}

no Moose;
no Moose::Util::TypeConstraints;
__PACKAGE__->meta->make_immutable;
1;

=for test_synopsis
my @sections;

=head1 SYNOPSIS

  my $ini = Config::MVP::Writer::INI->new->ini_string(\@sections);

=head1 DESCRIPTION

This class takes a collection of L<Config::MVP> style data structures
and writes them to a string in INI format.

One usage example would be to create a roughly equivalent INI file
from the output of a plugin bundle (L<Dist::Zilla>, L<Pod::Weaver>, etc.).

The author makes no claim that this would actually be useful to anyone.

=head1 WARNING

This code is very much in an alpha state and the API is likely to change.
As always, suggestions, bug reports, patches, and pull requests are welcome.

=attr rewrite_package

This attribute is a coderef that will be used to munge the package name
of each section.  The package will be passed as the only argument
(and also available as C<$_>) and should return the translation.
If nothing is returned the original package will be used.

This can be used to flavor the INI for a particular application.
For example:

  rewrite_package => sub { s/^MyApp::Plugin::/-/r; }

will transform an array ref of

  [ Stinky => 'MyApp::Plugin::Nickname' => {real_name => "Dexter"} ]

into an INI string of

  [-Nickname / Stinky]
  real_name = Dexter

=attr spacing

Defines the spacing between sections.
Must be one of the following:

=for :list
= payload
(Default) Put blank lines around sections with a payload
= all
Put a blank line between all sections
= none
No blank lines

=method ini_string

This takes an array ref of array refs,
each one being a C<Config::MVP> style section specification:

  [
    [ $name, $package, \%payload ],
  ]

and returns a string.

For convenience a few specification shortcuts are recognized:

  $name                => [ $name, $name, {} ]
  [ $name ]            => [ $name, $name, {} ]
  [ $name, $package ]  => [ $name, $package, {} ]
  [ $name, \%payload ] => [ $name, $name, \%payload ]

=for :stopwords TODO

=head1 TODO

=for :list
* Documentation
* More tests
* Allow payload to be an arrayref for explicit ordering

=cut
