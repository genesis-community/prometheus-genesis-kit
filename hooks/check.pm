#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 et:
package Genesis::Hook::Check::Prometheus v1.13.0; # version of the bosh kit

use strict;
use warnings;
use v5.20; # Genesis supports min perl v5.20.

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

# Parent class inheritance
use parent qw(Genesis::Hook);

# Import required functions
use Genesis qw/bail info warning error in_array new_enough/;

sub init {
  my ($class, %ops) = @_;
  my $obj = $class->SUPER::init(%ops);
  $obj->{ok} = 1; # Start assuming all checks will pass
	$obj->{files} = [];
	$obj->check_minimum_genesis_version('3.1.0-rc.20');
  return $obj;
}

sub perform {
  my ($self) = @_;
  my $exodus_path = $env->lookup("genesis.exodus_base");
  my $cf_exodus_path =~ s/prometheus/bosh/;
  my $prometheus_user = $self->vault->get($cf_exodus_path.":prometheus_user");
  # Check bosh exodus exports prometheus uaa user.
  if ($prometheus_user) {
    $self->env->notify(success => "prometheus bosh uaa user exists. [#G{OK}]");
  } else {
    $self->env->notify(
      error => "prometheus bosh uaa user does not exist! [#R{FAILED}]".
      "Add the `promtheus-integration` fetaure to bosh redeploy first."
    );
    $self->{ok} = 0;
  }
  # Return the final result
  if ($self->{ok}) {
    $self->env->notify(success => "environment files [#G{OK}]");
  } else {
    $self->env->notify(error => "environment files [#R{FAILED}]");
  }

  return $self->done($self->{ok});
}

1;
