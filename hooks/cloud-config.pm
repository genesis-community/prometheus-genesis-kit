#!/usr/bin/env perl
# vim: set ts=2 sw=2 sts=2 foldmethod=marker
package Genesis::Hook::CloudConfig::Prometheus v1.13.0;

use strict;
use warnings;
use v5.20;

# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'/.genesis/lib'}

use parent qw(Genesis::Hook::CloudConfig);

use Genesis::Hook::CloudConfig::Helpers qw/gigabytes megabytes/;

use Genesis qw//;
use JSON::PP;

sub init {
  my $class = shift;
  my $obj = $class->SUPER::init(@_);
  $obj->check_minimum_genesis_version('3.1.0-rc.4');
  return $obj;
}

sub perform {
  my ($self) = @_;
  return 1 if $self->completed;

  my $config = $self->build_cloud_config({
      'networks' => [
        $self->network_definition('prometheus', strategy => 'ocfp',
          dynamic_subnets => {
            allocation => {
              size => 0,
              statics => 0,
            },
            cloud_properties_for_iaas => {
              openstack => {
                'net_id' => $self->network_reference('id'), # TODO: $self->subnet_reference('net_id'),
                'security_groups' => ['default'] #$self->subnet_reference('sgs', 'get_security_groups'),
              },
              stackit => {
                'net_id' => $self->network_reference('id'), # Use same endpoint as openstack
                'security_groups' => ['default']
              },
            },
          },
        )
      ],
      'vm_types' => [
        $self->vm_type_definition('prometheus',
          cloud_properties_for_iaas => {
            openstack => {
              'instance_type' => $self->for_scale({
                  dev => 'm1.2',
                  prod => 'm1.3'
                }, 'm1.2'),
              'boot_from_volume' => $self->TRUE,
              'root_disk' => {
                'size' => 32 # in gigabytes
              },
            },
            stackit => {
              'instance_type' => $self->for_scale({
                  dev => 'm1.2',
                  prod => 'm1.3'
                }, 'm1.2'),
              'boot_from_volume' => $self->TRUE,
              'root_disk' => {
                'size' => 32 # in gigabytes
              },
            },
          },
        ),
      ],
      'disk_types' => [
        $self->disk_type_definition('prometheus',
          common => {
            disk_size => $self->for_scale({ # add $self->for_feature('internal-blobstore')
                dev => gigabytes(128),
                prod => gigabytes(256)
              }, gigabytes(128)),
          },
          cloud_properties_for_iaas => {
            openstack => {
              'type' => 'storage_premium_perf6',
            },
            stackit => {
              'type' => 'storage_premium_perf6', # Use same storage type as openstack
            },
          },
        ),
      ],
    });

  $self->done($config);
}

1;
