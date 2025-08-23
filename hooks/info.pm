package Genesis::Hook::Info::Prometheus v1.12.1;

use v5.20; # Genesis min perl version is 5.20
use warnings;

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

use parent qw(Genesis::Hook);

use Genesis qw/bail info run warning/;

# init - Initialize the hook {{{
sub init {
  my ($class, %ops) = @_;
  my $obj = $class->SUPER::init(%ops);
  $obj->check_minimum_genesis_version('3.1.0-rc.20');
  return $obj;
}

# }}}

# perform - Main hook execution {{{
sub perform {
  my ($self) = @_;

  # Get BOSH environment info from exodus data
  my $bosh_environment = $self->env->exodus_lookup('url') || 'https://127.0.0.1:25555';
  my $bosh_ca_cert = $self->env->exodus_lookup('ca_cert');
  my $bosh_client = $self->env->exodus_lookup('admin_username');
  my $bosh_client_secret = $self->env->exodus_lookup('admin_password');

  # Display BOSH environment
  info("BOSH env");
  my ($out, $rc, $err) = $self->bosh->execute({interactive => 0},"bosh", "-A", "env", "--tty");
  info($out);

  # Display access instructions
  my $call_with_env = $self->env->get_call_path_with_env();

	# Gather the necessary information from Exodus
	my %info = map {($_, $self->exodus_data->{$_}//undef)} qw(
		prometheus_url
		grafana_url
		alertmanager_url
		admin_user
		admin_password
	);

	my @missing_exodus_fields = grep {!defined($info{$_})} keys %info;
	warning(
		"\nMissing the following data from the last deploy:\n%s\n\n".
		"Please redeploy in order to generate the necessary information.\n",
		join("\n", map { "[[  - >>$_" } @missing_exodus_fields)
	) if @missing_exodus_fields;

	info(
		"#Bu{Prometheus Information}\n\n".
		"Prometheus endpoint information\n".
		"[[  >>#C{https://%s}\n\n".
		"Grafana endpoint information\n".
		"[[  >>#C{https://%s}\n\n".
		"AlertManager endpoint information\n".
		"[[  >>#C{https://%s}\n\n".
		"HTTP auth credentials (for all above endpoints)\n".
		"[[  >>username: #M{%s}\n".
		"[[  >>password: #G{%s}\n\n",
		$info{prometheus_url}   // '}#Ri{<unknown>',
		$info{grafana_url}      // '}#Ri{<unknown>',
		$info{alertmanager_url} // '}#Ri{<unknown>',
		$info{admin_user}       // '}#Ri{<unknown>',
		$info{admin_password}   // '}#Ri{<unknown>',
	);

  return $self->done();
}

# }}}

1; # End of module
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:

# # vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
