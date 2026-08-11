package Genesis::Hook::Blueprint::Prometheus v3.0.0;

use v5.20;
use warnings;

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
	my ($self) = @_;
	my $env = $self->env;

	$self->add_files(
		"manifests/prometheus.yml",
		"manifests/releases/postgres.yml",
		"manifests/releases/prometheus.yml",
		"manifests/releases/bpm.yml"
	);

	my $cf_exodus_path =
		$env->lookup('cf_env',$env->name).
		"/".
		$env->lookup('cf_type','cf');


	my $cf_version = $env->exodus_lookup('kit_version','1.0.0',$cf_exodus_path);
	my $cf_v2 = new_enough(($cf_version)[0], "2.0.0-rc0");

	my (@ops_files) = ();
	for my $feature ($self->features) {
		if ($feature =~ /^(monitor-cf)$/) {
			$self->add_files(
				$cf_v2
					? "manifests/monitor-cf-v2.yml"
					:	"manifests/monitor-cf.yml"
			);
			# BBS metrics are opt-in: cf_exporter reaches Diego BBS for
			# running-instance counts, which needs the cf kit to export
			# the bbs client cert to exodus first.
			if ($cf_v2 && $self->want_feature('monitor-cf-bbs')) {
				$self->add_files(
					"manifests/monitor-cf-bbs.yml",
					"manifests/releases/bosh-dns-aliases.yml"
				);
			}
			if ($self->want_feature('legacy-firehose')) {
				bail(
					"legacy-firehose is not available for cf v2.x deployments"
				) if $cf_v2;
				$self->add_files("manifests/legacy-firehose.yml");
			}

		} elsif ($feature =~ /^(monitor-cf-bbs)$/) {
			# Wired by the monitor-cf feature above; only valid with it.
			bail(
				"monitor-cf-bbs requires the monitor-cf feature"
			) unless $self->want_feature('monitor-cf');

		} elsif ($feature =~ /^(monitor-*)$/) {
			bail(
				"The feature #c{%s} is not valid for the Prometheus blueprint.",
				$feature
			) unless -f $env->kit->path("manifests/${feature}.yml");
			$self->add_files("manifests/${feature}.yml");

		} elsif ($feature =~ /^(legacy-firehose)$/) {
			bail(
				"legacy-firehose feature only applicable if monitor-cf feature is active"
			) unless $self->want_feature('monitor-cf');

		} elsif ($feature =~ /^(ocfp|self-signed-cert|\+provided-cert)$/) {
			# Handled elsewhere, so skip

		} elsif ( -f $env->path("ops/${feature}.yml")) {
			# Ops files are added to the blueprint at the end
			push @ops_files, $env->path("ops/${feature}.yml");
		} else {
			bail(
				"The #c{%s} feature is invalid. See MANUAL.md for list of valid features.",
				$feature
			);
		}
	}

	if ($self->want_feature('ocfp')) {
		# OCFP wants to be added after the other features because it modifies them
		$self->add_files(
			"ocfp/meta.yml",
			"ocfp/ocfp.yml"
		);

		# Add IaaS-specific files if needed
		my $iaas = $self->iaas;
		$self->add_files_if_exists(
			"ocfp/$iaas/base.yml"
		)
	}

	# Add the ops files at the end so they can override any previous files
	$self->add_files(@ops_files);

	return $self->done();
}

1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
