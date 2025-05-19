#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 foldmethod=marker
package Genesis::Hook::Prometheus::PostDeploy v1.13.0;

use strict;
use warnings;
use v5.20; # Genesis min perl version is 5.20
use Genesis qw/info/;
use parent qw(Genesis::Hook);
use lib $ENV{GENESIS_LIB} // "$ENV{HOME}/.genesis/lib";
use JSON::PP;

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

use parent qw(Genesis::Hook::PostDeploy);

# Initialize the hook
sub init {
  my ($class, %ops) = @_;
  my $self = $class->SUPER::init(%ops);
  return $self;
}

# Main hook execution
sub perform {
  my ($self) = @_;

  # Base class has deploy_successful method to check if GENESIS_DEPLOY_RC == 0
  if ($self->deploy_successful) {
    info(
      "\n#M{$ENV{GENESIS_ENVIRONMENT}} Prometheus deployed!\n".
      "\nFor details about the deployment, run\n".
      "\t#G{$ENV{GENESIS_CALL_ENV} info}\n".
      "\nTo open the Prometheus page:]\n".
      "\t#G{$ENV{GENESIS_CALL_ENV} do -- open prometheus}\n".
      "\nTo open the Grafana page:\n".
      "\t#G{$ENV{GENESIS_CALL_ENV} do -- open graphana}\n".
      "\nTo visit the AlertManager page:\n".
      "\t#G{$ENV{GENESIS_CALL_ENV} do -- open alertmanager}\n".
      "\nTo generate a node exporter runtime config:\n".
      "\t#G{$ENV{GENESIS_CALL_ENV} do -- runtime-config}\n".
    );
  }

  # Call parent class methods if needed
  $self->SUPER::perform() if $self->can('SUPER::perform');

  # Mark the hook as completed successfully
  return $self->done(1);
}

1; # End of module

=head1 NAME

Genesis::Hook::PostDeploy::Prometheus - Post-deployment hook for Prometheus Genesis Kit

=head1 DESCRIPTION

This module implements the post-deployment hook for the Prometheus Genesis Kit.
It displays helpful information to the user after a successful deployment.

=head1 METHODS

=head2 init(%options)

Initializes the hook with the given options.

=head2 perform()

Executes the post-deploy hook, displaying helpful information if the deployment was successful.

=head1 AUTHOR

Genesis Framework

=cut
