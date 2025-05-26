#!/usr/bin/env perl
# # vim: set ts=2 sw=2 sts=2 et:
package Genesis::Hook::Info::Prometheus v1.13.0; # ...::[KIT] v[KIT_VERSION]

use strict;
use warnings;
use v5.20; # Genesis supports min perl v5.20.

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

# Parent class inheritance
use parent qw(Genesis::Hook);

# Import required functions
use Genesis qw/bail info/;

sub init {
  my ($class, %ops) = @_;
  my $obj = $class->SUPER::init(%ops);
  $obj->check_minimum_genesis_version('3.1.0-rc.20');
  return $obj;
}

sub perform {
  my ($self) = @_;

  # Get BOSH environment info from exodus data
  my $bosh_environment = $self->env->exodus_lookup('url') || 'https://127.0.0.1:25555';
  my $bosh_ca_cert = $self->env->exodus_lookup('ca_cert');
  my $bosh_client = $self->env->exodus_lookup('admin_username');
  my $bosh_client_secret = $self->env->exodus_lookup('admin_password');

  # Display BOSH environment
  info("BOSH env");
  my ($out, $rc, $err) = run("bosh -A env --tty | sed -e 's/^/  /'");
  info($out);

  # Display access instructions
  my $call_with_env = $self->env->get_call_path_with_env();

  my $prometheus_url = $self->env->exodus_lookup('prometheus_url');
  bail(
    "Prometheus URL not found in exodus data. Please check your environment."
  ) unless $prometheus_url;
  my $grafana_url = $self->env->exodus_lookup('grafana_url');
  bail(
    "Grafana URL not found in exodus data. Please check your environment."
  ) unless $grafana_url;
  my $alertmanager_url = $self->env->exodus_lookup('alertmanager_url');
  bail(
    "AlertManager URL not found in exodus data. Please check your environment."
  ) unless $alertmanager_url;
  my $prometheus_user = $self->env->exodus_lookup('prometheus_user');
  bail(
    "Prometheus user not found in exodus data. Please check your environment."
  ) unless $prometheus_user;
  my $prometheus_password = $self->env->exodus_lookup('prometheus_password');
  bail(
    "Prometheus password not found in exodus data. Please check your environment."
  ) unless $prometheus_password;

  info(join("\n",
      "\n#B{Prometheus Information}" ,
      "\nPrometheus endpoint information" ,
      "\t#C{https://$prometheus_url}" ,
      "\nGrafana endpoint information" ,
      "\t#C{https://$grafana_url}" ,
      "\nAlertManager endpoint information" ,
      "\t#C{https://$alertmanager_url}" ,
      "\nHTTP auth credentials" ,
      "\tusername: #M{$prometheus_user}" ,
      "\tpassword: #G{$prometheus_password}" ,
      ""
    ));

  return $self->done();
}

1;

