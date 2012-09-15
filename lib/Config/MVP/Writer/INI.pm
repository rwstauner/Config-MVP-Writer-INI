# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Config::MVP::Writer::INI;
# ABSTRACT: Build an INI file for Config::MVP

use Moose;
use Moose::Util::TypeConstraints;
use List::AllUtils ();

sub ini_string {
  my ($self, $sections) = @_;

  # TODO: @$sections = $self->_simplify_bundles(@$sections) if configured

  my @strings = map { $self->_ini_section($_) } @$sections;

    # put a blank line around any section with a config
    @strings = map { /\n.+/ ? "\n$_\n" : $_ } @strings;

  my $ini = join '', @strings;

  return $ini;
}

sub _ini_section {
  my ($self, $section) = @_;

  my ($name, $moniker, $config) = @$section;

  # FIXME: this handles the bundle prefix but not the whole moniker (class suffix)
  #my $ini = "[$moniker" . ($name =~ /(^.+?\/)?$moniker$/ ? '' : " / $name") . "]\n";
  my $ini = "[$moniker" . ($name =~ /\/$moniker$/ ? '' : " / $name") . "]\n";

  $ini .= $self->_ini_section_config($config);

  return $ini;
}

    # TODO: rewrite_heading:
    # reverse RewritePrefix
    #$moniker =~ s/Dist::Zilla::(Plugin(Bundle)?)::/$2 ? '@' : ''/e
      #or $moniker = "=$moniker";

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

    #while( my ($k, $v) = each %$config ){
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

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
