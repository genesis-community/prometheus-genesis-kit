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
	$obj->check_minimum_genesis_version('3.1.0-rc.20');
	return $obj;
}

sub perform {
	my ($blueprint) = @_;
	my $env = $blueprint->env;

	$blueprint->add_files(
		"manifests/prometheus.yml",
		"manifests/releases/postgres.yml",
		"manifests/releases/prometheus.yml",
		"manifests/releases/bpm.yml"
	);

	my $cf_exodus_path =
		$env->lookup('cf_env',$env->name).
		"/".
		$env->lookup('cf_type','cf');

	my $cf_v2 = new_enough(
		$env->exodus_lookup('kit_version','1.0.0',$cf_exodus_path),
		"2.0.0-rc0"
	);

	my (@ops_files) = ();
	for my $feature ($blueprint->features) {
		if ($feature =~ /^(monitor-cf)$/) {
			$blueprint->add_files(
				$cf_v2
					? "manifests/monitor-cf-v2.yml"
					:	"manifests/monitor-cf.yml"
			);
			if ($blueprint->want_feature('legacy-firehose')) {
				bail(
					"legacy-firehose is not available for cf v2.x deployments"
				) if $cf_v2;
				$blueprint->add_files("manifests/legacy-firehose.yml");
			}

		} elsif ($feature =~ /^(monitor-*)$/) {
			bail(
				"The feature #c{%s} is not valid for the Prometheus blueprint.",
				$feature
			) unless -f $env->kit->path("manifests/${feature}.yml");
			$blueprint->add_files("manifests/${feature}.yml");

		} elsif ($feature =~ /^(legacy-firehose)$/) {
			bail(
				"legacy-firehose feature only applicable if monitor-cf feature is active"
			) unless $blueprint->want_feature('monitor-cf');

		} elsif ($feature =~ /^(ocfp|self-signed-cert|\+provided-cert)$/) {
			# Handled elsewhere, so skip

		} elsif ( -f $env->path("ops/${feature}.yml")) {
			# Ops files are added to the blueprint at the end
			push @ops_files, "ops/${feature}.yml";
		} else {
			bail(
				"The #c{%s} feature is invalid. See MANUAL.md for list of valid features.",
				$feature
			);
		}
	}

	if ($blueprint->want_feature('ocfp')) {
		# OCFP wants to be added after the other features because it modifies them
		$blueprint->add_files(
			"ocfp/meta.yml",
			"ocfp/ocfp.yml"
		);

		# Add IaaS-specific files if needed
		my $iaas = $blueprint->iaas;
		if ($iaas eq 'stackit') {
			# If we need any stackit-specific overrides in the future, we can add them here
			# $blueprint->add_files("ocfp/stackit.yml");
		}
	}

	# Add the ops files at the end so they can override any previous files
	$blueprint->add_files(@ops_files);

	return $blueprint->done();
}

1;
