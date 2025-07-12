package Genesis::Hook::CloudConfig::Prometheus;

use v5.20;
use warnings;

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
                'security_groups' => $self->network_reference('sgs', 'get_sgs_by_names', 'ocfp', 'default')
              },
              aws => {
                'subnet' => $self->subnet_reference('id'),
              },
            },
          },
        )
      ],
      'vm_extensions' => [
        $self->vm_extension_definition('prometheus-lb' => {
            aws => {
              'lb_target_groups' => ['ocfp-ocf-prometheus-lb-tg'],
            },
          },
        ),
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
            aws => {
              'instance_type' => $self->for_scale({
                  dev => 'm6i.large',
                  prod => 'r6i.xlarge'
                }, 'm6i.large'),
              'ephemeral_disk' => {
                'size' => $self->for_scale({
                  dev => 32768,
                  prod => 65536
                }, 32768),
                'type' => 'gp3',
                'encrypted' => $self->TRUE,
              },
              'metadata_options' => {
                'http_tokens' => 'required',
              },
            },
          },
        ),
      ],
      'disk_types' => [
        $self->disk_type_definition('prometheus',
          common => {
            disk_size => $self->for_scale({ # add $self->for_feature('internal-blobstore')
                dev => 131072,
                prod => 263144
              }, 131072),
          },
          cloud_properties_for_iaas => {
            openstack => {
              'type' => 'storage_premium_perf6',
            },
            stackit => {
              'type' => 'storage_premium_perf6', # Use same storage type as openstack
            },
            aws => {
              'type' => 'gp3',
              'encrypted' => $self->TRUE,
            },
          },
        ),
      ],
    });

  $self->done($config);

	return 1;

}

sub get_sgs_by_names {
        my ($self, $subnet_data, $ref, @names) = @_;
        my @ids = map {$subnet_data->{$ref}{$_}{id}} @names;
        # TODO: Error checking
        return \@ids
}
1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
