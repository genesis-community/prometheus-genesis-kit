#!/usr/bin/env perl
# # vim: set ts=2 sw=2 sts=2 et:
package Genesis::Hook::New::Prometheus v1.13.0;

use strict;
use warnings;
use v5.20; # Genesis supports min perl v5.20.

BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}
use parent qw(Genesis::Hook);

use Genesis;
use Genesis::UI qw(prompt_for_boolean);

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->{features} = [];
  return $obj;
}

sub perform {
  my ($self) = @_;
  my $env = $self->env;

  # Identify network
  my $network = $self->_identify_network();

  # Get static IP
  my $ip = $self->_get_static_ip($network);

  # Handle SSL certificate configuration
  my $ssl_cert_feature = $self->_configure_ssl();
  push @{$self->{features}}, $ssl_cert_feature if $ssl_cert_feature eq "self-signed-cert";

  # Optional external domain
  my $external_domain = $self->_get_external_domain();

  # Configure exporters
  $self->_configure_exporters();

  # Create environment file
  $self->_create_environment_file($ip, $external_domain);

  # Offer environment editor
  $self->_offer_environment_editor();

  return $self->done();
}

sub _identify_network {
  my ($self) = @_;

  my ($out, $rc) = run({ stderr => 0 }, 'ccq -e \'.networks[] | .name | select(. == "prometheus")\' >/dev/null 2>&1');

  if ($rc == 0) {
    return 'prometheus';
  }

  ($out, $rc) = run('ccq \'.networks | sort_by(.name)| .[] | .name | "-o \\(.)"\'');
  my @network_options = split(/\s+/, $out);

  my $network;
  prompt_for('network', 'select',
    'What network do you want to use for this Prometheus deployment?',
    @network_options, \$network);

  return $network;
}

sub _get_static_ip {
  my ($self, $network) = @_;

  # Get default IP from network
  my ($default_ip, $rc) = run(
    'ccq \'.networks[] | select(.name == $nw) | .subnets[] | select(has("static")) | .static[] \' --arg nw "' . $network . '" | head -n1 | sed -e \'s/\\(^\\|[^0-9]\\)\\(\\([0-9]\\{1,3\\}\\.\\)\\{3\\}[0-9]\\{1,3\\}\\) *$/\\2/\''
  );
  chomp($default_ip);

  my $default = "";
  if ($default_ip =~ /^([0-9]{1,3}(\.|$)){4}$/) {
    $default = "--default $default_ip";
  }

  my $ip;
  prompt_for('ip', 'line',
    'What static IP do you want to deploy this Prometheus server on?',
    '--validation ip ' . $default, \$ip);

  return $ip;
}

sub _configure_ssl {
  my ($self) = @_;

  describe("",
    "Prometheus will be running on HTTPS, and as such, needs an SSL cert/key.");

  my $ssl_cert_feature;
  prompt_for('ssl_cert_feature', 'select',
    "Do you have an SSL certificate for Prometheus, or do you need a self-signed cert?",
    '-o "[provided-cert] I have my own certificate for Prometheus"',
    '-o "[self-signed-cert] Please have Genesis create a self-signed certificate for Prometheus"',
    \$ssl_cert_feature);

  if ($ssl_cert_feature eq "provided-cert") {
    my $vault_prefix = $ENV{GENESIS_VAULT_PREFIX};

    my $certificate;
    prompt_for("$vault_prefix/nginx/ssl_certificate:certificate", 'secret-block',
      "What is the SSL certificate for Prometheus?", \$certificate);

    my $key;
    prompt_for("$vault_prefix/nginx/ssl_certificate:key", 'secret-block',
      "What is the SSL key for Prometheus?", \$key);
  }

  return $ssl_cert_feature;
}

sub _get_external_domain {
  my ($self) = @_;

  describe("",
    "If you'd like to access Prometheus via a domain name, please enter it now. If you",
    "do not have one, and would prefer to access Prometheus via the static IP, leave ",
    "this field empty.");

  my $external_domain;
  prompt_for('external_domain', 'line', '--default \'\'',
    'What is the domain you want to use to access Prometheus?', \$external_domain);

  return $external_domain;
}

sub _configure_exporters {
  my ($self) = @_;

  describe("",
    "By default, Prometheus will monitor VM metrics and your BOSH environment. If you",
    "want more detail, you can select from supported exporters below to gain insight",
    "into software-specific metrics. Some exporters may require additional configuration.");

  foreach my $exporter ('cf', 'credhub') {
    my $monitor_exporter;
    prompt_for_boolean(
      "Would you like to monitor your '#G{$exporter}' environment?",
      1, \$monitor_exporter);

    if ($monitor_exporter) {
      push @{$self->{features}}, "monitor-$exporter";
    }

    # Additional exporter-specific configuration would go here
  }
}

sub _create_environment_file {
  my ($self, $ip, $external_domain) = @_;

  my $env_file = "$ENV{GENESIS_ROOT}/$ENV{GENESIS_ENVIRONMENT}.yml";
  open my $fh, ">>", $env_file or die "Cannot open $env_file for writing: $!";

  print $fh "kit:\n";
  print $fh "  name:    $ENV{GENESIS_KIT_NAME}\n";
  print $fh "  version: $ENV{GENESIS_KIT_VERSION}\n";
  print $fh "  features:\n";
  print $fh "    - ((append))\n";

  foreach my $feature (@{$self->{features}}) {
    print $fh "    - $feature\n";
  }

  # Generate and add the genesis_config_block
  my ($out, $rc) = run('genesis_config_block');
  print $fh $out;

  print $fh "params:\n";
  print $fh "  static_ip: $ip\n";

  # Add external_domain if provided
  if ($external_domain) {
    print $fh "  external_domain: $external_domain\n";
  }

  close $fh;
}

sub _offer_environment_editor {
  my ($self) = @_;
  run({ interactive => 1 }, 'offer_environment_editor');
}

1;
