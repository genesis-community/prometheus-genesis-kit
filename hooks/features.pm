#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 foldmethod=marker
package Genesis::Hook::Features::Prometheus v1.13.0;

use strict;
use warnings;
use v5.20; # Genesis min perl version is 5.20

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}
use parent qw(Genesis::Hook::Features);

use Genesis qw/bail/;

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->check_minimum_genesis_version('3.1.0-rc.20');
  return $obj;
}

sub perform {
  my ($self) = @_;

  foreach my $feature (@{$self->{features}}) {
    if ($feature =~ /(self-signed-cert|legacy-firehose|monitor-cf*)/) {
      $self->add_feature($feature);
    } elsif ($feature =~ /^(monitor-*)$/) {
      if (-f $self->env->path("ops/${feature}.yml")) {
        $self->add_feature($feature);
      } else {
        bail(
          "Feature [$feature] not supported in this context.".
          " Supported features are: self-signed-cert, legacy-firehose, and the monitor-cf* family."
        );
      }
    } elsif (! $feature =~ /(self-signed-cert)/) {
      $self->add_feature('+provided-cert');
    } else {
      bail(
        "Feature [$feature] not supported in this context.".
        " Supported features are: self-signed-cert, legacy-firehose, and the monitor-cf* family."
      );
    }
  }

  return $self->done();
}

1;
