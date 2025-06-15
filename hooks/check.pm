# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
package Genesis::Hook::Check::Prometheus; # version of the bosh kit

use v5.20;
use warnings; # Genesis supports min perl v5.20.

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

# Parent class inheritance
use parent qw(Genesis::Hook::Check);

# Import required functions
use Genesis;

sub init {
  my ($class, %ops) = @_;
  my $obj = $class->SUPER::init(%ops);
  $obj->check_minimum_genesis_version('3.1.0-rc.20');
  return $obj;
}

sub perform {
  my ($self) = @_;
	my $ok = 1;

	# Cloud Config checks
	$ok = 0 unless $self->check_cloud_config();

	# Environment Parameter checks
	$ok = 0 unless $self->check_environment_parameters();

  return $self->done($ok);
}

sub check_cloud_config {
	my ($self) = @_;

	$self->start_check('cloud-config');

	return $self->check_result('cloud-config', 'skipped', "OCFP env manages its own cloud-config") if $self->is_ocfp;
	return $self->check_result('cloud-config', 'failed', "no cloud config found") unless $self->env->has_config('cloud');

	# TODO: Add checking for classic (non-ocfp) kits
	return $self->check_result('cloud-config');
}

sub check_environment_parameters {
	my ($self) = @_;

	$self->start_check('environment');
	$self->has_entry('environment','exodus','prometheus_user', deployment => 'bosh');
	$self->has_entry('environment','exodus','prometheus_password', deployment => 'bosh');
	return $self->check_result('environment')

}

1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
