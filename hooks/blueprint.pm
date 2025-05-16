#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 et:
package Genesis::Hook::Blueprint::Prometheus v1.13.0;

use strict;
use warnings;
use v5.20;

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}
use parent qw(Genesis::Hook::Blueprint);

use Genesis qw/bail new_enough/;

sub init {
	my $class = shift;
	my $obj = $class->SUPER::init(@_);
	$obj->{files} = [];
	$obj->check_minimum_genesis_version('3.1.0-rc.20');
	return $obj;
}

sub perform {
	my ($blueprint) = @_; # $blueprint is '$self'

	$blueprint->add_files(qw(
    "manifests/prometheus.yml"
    "manifests/releases/postgres.yml"
    "manifests/releases/prometheus.yml"
    "manifests/releases/bpm.yml"
	));

my $exodus_path = $self->env->exodus_base();
my $exodus_path =~ s/prometheus/cf/;
my $cf_version = $self->vault->get($exodus_path.":kit_version");

# Features pre-check: Check for ops features
my (@features,$iaas,$db,$abort,$warn) = ();
for my $feature ($blueprint->features) {
  if ($feature =~ /^(monitor-cf)$/ {
      if ($cf_version && !new_enough($cf_version, "2.0.0-rc0")) {
        $blueprint->add_files( "manifests/monitor-cf-v2.yml" );
        bail(
          "legacy-firehose is not available for cf v2.x deployments"
        ) if $self->want_feature('legacy-firehose');
      } else {
        $blueprint->add_files( "manifests/monitor-cf.yml" )
        if $self->want_feature('legacy-firehose') {
          $blueprint->add_files( "manifests/legacy-firehose.yml" )
        }
      }
  } elsif ($feature =~ /^(monitor-*)$/) {
    $blueprint->add_files("manifests/${feature}.yml");
  } elsif ($feature =~ /^(legacy-firehose)$/) {
    bail(
      "legacy-firehose feature only applicable if monitor-cf feature is active"
    ) unless $blueprint->want_feature('monitor-cf');
  } elsif ( -f $blueprint->env->path("ops/${feature}.yml")) {
    $blueprint->add_files("ops/${feature}.yml");
  } elsif ($feature =~ /^(ocfp)$/) {
    $blueprint->add_files(
      "ocfp/meta.yml"
      "ocfp/ocfp.yml"
    );
  } else {
    bail(
      "The #c{%s} feature is invalid. See MANUAL.md for list of valid features.",
      $feature
    )
  }
}

1;

