#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 foldmethod=marker
package Genesis::Hook::Addon::Prometheus::RuntimeConfig v1.13.0;

use strict;
use warnings;
use v5.20; # Genesis min perl version is 5.20
use Genesis qw/bail info run pushd popd mkfile_or_fail/;
use parent qw(Genesis::Hook::Addon);
use lib $ENV{GENESIS_LIB} // "$ENV{HOME}/.genesis/lib";

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->check_minimum_genesis_version('3.1.0');
  return $obj;
}

sub cmd_details {
  return
  "Generates a runtime configuration for node-exporter.\n".
  "This configuration can be used with BOSH to deploy node-exporter across all deployments.\n";
}

sub perform {
  my ($self) = @_;
  my $env = $self->env;

  $env->notify(<<EOF);
releases:
  - name: node-exporter
    version: 5.5.0
    url:     https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/download/v5.5.0/node-exporter-5.5.0.tgz
    sha1:    e013bead7ca3d0128a56dc71b1294fa0d75eea36

addons:
  - name: node_exporter
    jobs:
      - name: node_exporter
        release: node-exporter
    include:
      stemcell:
        - os: ubuntu-jammy
        - os: ubuntu-bionic
        - os: ubuntu-xenial
    properties: {}
EOF

  return 1;
}

1;
