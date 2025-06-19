package Genesis::Hook::Addon::Prometheus::Open;

use v5.20;
use warnings; # Genesis min perl version is 5.20
use Genesis qw/bail info run pushd popd mkfile_or_fail/;
# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'./.genesis/lib'}

use parent qw(Genesis::Hook::Addon);
use File::Basename qw/basename/;

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->check_minimum_genesis_version('3.1.0');
  return $obj;
}

sub cmd_details {
  return
  "Provides utilities for accessing and configuring Prometheus. Supports the following options:\n".
  "[[  #y{list}                >>List out all supported addons.\n".
  "[[  #y{open prometheus}    >>[shortcut: vp] open the Prometheus Web UI (macOS & Linux only)\n".
  "[[  #y{open grafana}       >>[shortcut: vg] open the Grafana dashboard (macOS & Linux only)\n".
  "[[  #y{open alertmanager}  >>[shortcut: va] open the AlertManager dashboard (macOS & Linux only)\n";
}

sub perform {
  my ($self) = @_;
  my $env = $self->env;
  my $vault = "secret/" . $ENV{GENESIS_VAULT_PREFIX};
  my $target = $ENV{GENESIS_ENVIRONMENT};

  # Get the first argument
  my $command = $self->{args}[0] || 'list';

  if ($command eq 'list') {
    $self->list();
  }
  elsif ($command eq 'prometheus' || $command eq 'vp') {
    $self->open_prometheus();
  }
  elsif ($command eq 'grafana' || $command eq 'vg') {
    $self->open_grafana();
  }
  elsif ($command eq 'alertmanager' || $command eq 'va') {
    $self->open_alertmanager();
  }
  else {
    $env->notify("Unrecognized Prometheus Genesis Kit addon.");
    $self->list();
    return 0;
  }

  return $self->done();
}

# Helper methods
sub list {
  my ($self) = @_;
  my $env = $self->env;

  $env->notify("The following addons are defined:");
  $env->notify("");
  $env->notify("  list                List out all supported addons.");
  $env->notify("  open prometheus    [shortcut: vp] open the Prometheus Web UI (macOS & Linux only)");
  $env->notify("  open grafana       [shortcut: vg] open the Grafana dashboard (macOS & Linux only)");
  $env->notify("  open alertmanager  [shortcut: va] open the AlertManager dashboard (macOS & Linux only)");
  $env->notify("");
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

sub open_prometheus {
  my ($self) = @_;
  my $env = $self->env;
  my $vault = "secret/" . $ENV{GENESIS_VAULT_PREFIX};

  my $cmd = $self->get_command_for_os();
  unless ($cmd && `command -v $cmd 2>/dev/null`) {
    $env->notify("The 'open-prometheus' addon script only works on macOS and Linux, currently.");
    return 0;
  }

  my $url = $env->exodus_lookup("prometheus_url");
  my $password = $self->vault->get("$vault/admin:password");

  system($cmd, "https://admin:$password\@$url");
  return 1;
}

sub open_alertmanager {
  my ($self) = @_;
  my $env = $self->env;
  my $vault = "secret/" . $ENV{GENESIS_VAULT_PREFIX};

  my $cmd = $self->get_command_for_os();
  unless ($cmd && `command -v $cmd 2>/dev/null`) {
    $env->notify("The 'open-alertmanager' addon script only works on macOS and Linux, currently.");
    return 0;
  }

  my $url = $env->exodus_lookup("alertmanager_url");
  my $password = $self->vault->get("$vault/admin:password");

  system($cmd, "https://admin:$password\@$url");
  return 1;
}

sub open_grafana {
  my ($self) = @_;
  my $env = $self->env;
  my $vault = "secret/" . $ENV{GENESIS_VAULT_PREFIX};

  my $cmd = $self->get_command_for_os();
  unless ($cmd && `command -v $cmd 2>/dev/null`) {
    $env->notify("The 'open-grafana' addon script only works on macOS and Linux, currently.");
    return 0;
  }

  my $url = $env->exodus_lookup("grafana_url");
  my $password = $self->vault->get("$vault/admin:password");

  $env->notify("Here's the credentials you'll need to sign in: ");
  $env->notify("");
  $env->notify("  username: admin");
  $env->notify("  password: $password");
  $env->notify("");

  system($cmd, "https://$url");
  return 1;
}

1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
