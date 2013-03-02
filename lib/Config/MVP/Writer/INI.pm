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
  isa        => enum([qw( none all config )]),
  default    => 'config',
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
  elsif( $spacing eq 'config' ){
    # put a blank line around any section with a config
    @strings = map { /\n.+/ ? "\n$_\n" : $_ } @strings;
  }

  my $ini = join '', @strings;

  # don't need to start with a newline
  $ini =~ s/\A\n+//;
  # one newline at the end is sufficient
  $ini =~ s/\n{2,}\z//;

  return $ini;
}

sub _ini_section {
  my ($self, $section) = @_;

  $section = [ $section ]
    unless ref($section) eq 'ARRAY';

  my ($name, $package, $config) = @$section;
  $package ||= $name;

  if( $self->can_rewrite_package ){
    $package = $self->rewrite_package($package);
  }

  # FIXME: this handles the bundle prefix but not the whole moniker (class suffix)
  my $ini = "[$package" . ($name =~ /(^.+?\/)?$package$/ ? '' : " / $name") . "]\n";

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
      push @lines,
        map { sprintf "%-*s = %s\n", $len, $k, $_ }
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

=head1 WARNING

This code is very much in an alpha state and the API is likely to change.
As always, suggestions, bug reports, patches, and pull requests are welcome.

=method ini_string

This takes an array ref of array refs,
each one being a C<Config::MVP> style section specification:

  [
    [ $name, $package, \%config ],
  ]

and returns a string.

=for :stopwords TODO

=head1 TODO

=for :list
* Documentation
* A lot more tests

=cut
