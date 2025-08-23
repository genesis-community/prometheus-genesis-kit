package Genesis::Hook::Addon::Prometheus::Open v1.12.1;
use v5.20;
use warnings; # Genesis min perl version is 5.20

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

use parent qw(Genesis::Hook::Addon);

use Genesis qw/bail info run pushd popd mkfile_or_fail/;
use File::Basename qw/basename/;

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->check_minimum_genesis_version('3.1.0');
  return $obj;
}

sub cmd_details {
  return
  "Provides web utilities for accessing and configuring Prometheus (macOS & Linux only). Supports the following options:\n".
  "[[  #y{list}                >>List out all supported addons.\n".
  "[[  #y{open prometheus}    >>[shortcut: vp] open the Prometheus Web UI\n".
  "[[  #y{open grafana}       >>[shortcut: vg] open the Grafana dashboard\n".
  "[[  #y{open alertmanager}  >>[shortcut: va] open the AlertManager dashboard\n";
}

sub perform {
  my ($self) = @_;
  my $env = $self->env;
  my $app = $self->get_app_name();
	my $url = $self->get_url_for($app);
	my ($user, $pass, $embed) = $self->get_auth_for($app);
	my $cmd = $self->get_command_for_os();

	bail(
    "The #G{%s} command only works on macOS and Linux, currently.  You may open the web app manually by visiting:\n".
		"  #Bu{https://%s}\n\n".
		"Present the following credentials if prompted:\n".
		"  username: #{%s}\n".
		"  password: #G{%s}\n\n",
		$0, $url, $user, $pass
	) unless $cmd && `command -v $cmd 2>/dev/null`;

	if ($embed) {
		system($cmd, "https://$user:$pass\@$url");
	} else {
		notice(
			"Enter the following credentials to access the #C{%s} dashboard once it opens:\n".
			"  username: %s\n".
			"  password: %s\n\n",
			$app, $user, $pass
		);
		system($cmd, "https://$url");
	}
  $self->done(1);
}

sub get_app_name {
	my ($self) = @_;
	my $app = shift @{$self->args};
	my %shortcuts = (
		vp => 'prometheus',
		vg => 'grafana',
		va => 'alertmanager'
	);
	return $shortcuts{$app} // (grep {$_ = $app} values %shortcuts)[0];
}

sub get_url_for {
	my ($self, $app) = @_;
	return $self->env->exodus_lookup("${app}_url") // bail(
		"Could not find URL for the '%s' web app.", $app
	);
}

sub get_auth_for {
	my ($self, $app) = @_;
	my $user = $self->env->exodus_lookup("admin_user");
	my $pass = $self->env->exodus_lookup("admin_password");
	bail(
		"Could not find admin credentials for the '%s' web app.", $app
	) unless $user && $pass;
	return ($user, $pass, $app ne 'grafana');
}

sub get_command_for_os {
  my ($self) = @_;
  my $uname = `uname`;
  chomp($uname);

  if ($uname eq "Linux") {
    return "xdg-open";
  }
  elsif ($uname eq "Darwin") {
    return "open";
  }
  else {
    return undef;
  }
}

1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
