# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;

package Config::MVP::Writer::INI;
# ABSTRACT: Build an INI file for Config::MVP

use List::AllUtils ();

sub string {
  my ($self, $plugins, $opts) = @_;
  $opts ||= {};

  my @lines;
  # TODO: attribute or argument?
  my @plugins = @$plugins;

  # for specified bundles just show [@Bundle] instead of each plugin
  my %bundles = map { ($_ => 0) } @{ $opts->{bundles} || [] };

  PLUGIN: foreach my $plugin ( @plugins ){
    my ($name, $moniker, $config) = @$plugin;

    my $len = List::AllUtils::max(map { length } keys %$config);

    # FIXME: abstract this
    # reverse RewritePrefix
    #$moniker =~ s/Dist::Zilla::(Plugin(Bundle)?)::/$2 ? '@' : ''/e
      #or $moniker = "=$moniker";

    # just list the bundle not each individual plugin
    foreach my $bundle ( keys %bundles ){
      if( $name =~ /\@${bundle}\b/ ){
        push @lines, '', "[\@${bundle}]", ''
          unless $bundles{ $bundle }++;
        next PLUGIN;
      }
    }

    push @lines, "[$moniker" . ($name =~ /\/$moniker$/ ? '' : " / $name") . "]";
    next unless scalar keys %$config;

    # insert blank line above [name]
    splice @lines, -1, 0, ''
      unless $lines[-2] eq '';

    #while( my ($k, $v) = each %$config ){
    foreach my $k ( sort keys %$config ){
      my $v = $config->{ $k };
      push @lines,
        map { sprintf "%-*s = %s", $len, $k, $_ }
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
    push @lines, '';
  }

  my $prefix = $opts->{prefix} || '';

  return join("\n", map { length($_) ? $prefix . $_ : '' } @lines) . "\n";
}

1;

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
