package Genesis::Hook::Prometheus::PostDeploy v1.13.0;

use strict;
use warnings;
use v5.20; # Genesis min perl version is 5.20

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

use parent qw(Genesis::Hook::PostDeploy);

use Genesis qw/info/;
use JSON::PP;

# Initialize the hook
sub init {
	my ($class, %ops) = @_;
	my $self = $class->SUPER::init(%ops);
	return $self;
}

# Main hook execution
sub perform {
	my ($self) = @_;
	my $env_name = $self->env->name;
	my $call_path = $self->env->get_call_path_with_env;

	# Base class has deploy_successful method to check if GENESIS_DEPLOY_RC == 0
	if ($self->deploy_successful) {
		info(
			"\n".
			"#M{%s} Prometheus deployed!\n\n".
			"For details about the deployment, run\n".
			"  #G{%s info}\n\n".
			"To open the Prometheus page:\n".
			"  #G{%s do open prometheus}\ni\n".
			"To open the Grafana page:\n".
			"  #G{%s do open graphana}\n\n".
			"To visit the AlertManager page:\n".
			"  #G{%s do open alertmanager}\n\n".
			"To generate a node exporter runtime config:\n".
			"  #G{%s do runtime-config}\n\n",
			$env_name, ($call_path) x 5
		);
	}

	# Mark the hook as completed successfully
	return $self->done();
}

1; # End of module
# vim: set ts=2 sw=2 sts=2 foldmethod=marker
