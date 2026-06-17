package Genesis::Hook::Addon::Prometheus::RuntimeConfig v2.1.0;

use v5.20;
use warnings; # Genesis min perl version is 5.20
use Genesis qw/bail info run pushd popd mkfile_or_fail/;
use Genesis::UI qw/prompt_for_boolean/;
# Only needed for development
BEGIN {push @INC, $ENV{GENESIS_LIB} ? $ENV{GENESIS_LIB} : $ENV{HOME}.'./.genesis/lib'}

use parent qw(Genesis::Hook::Addon);
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

  if (!$self->was_deployed()) {
    bail("",
      "\n#R{[ERROR]} No deployment found.\n".
      "\tPlease run deploy on this environment before running any addons.\n");
  }

  my $config_name = sprintf(
    "%s.%s.%s",
    $self->env->name,
    $self->env->type,
    "node-exporter"
  );

  my $config = "  releases:\n".
               "  - name: node-exporter\n".
               "    version: 5.7.0\n".
               "    url:     https://github.com/cloudfoundry/node-exporter-boshrelease/releases/download/v5.7.0/node-exporter-5.7.0.tgz\n".
               "    sha1:    8416c4914f251743c94a00eeae56e8f727801f47\n".
               "  addons:\n".
               "  - name: node_exporter\n".
               "    jobs:\n".
               "      - name: node_exporter\n".
               "        release: node-exporter\n".
               "        properties: {}\n".
               "    include:\n".
               "      stemcell:\n".
               "        - os: ubuntu-jammy\n".
               "        - os: ubuntu-bionic\n".
               "        - os: ubuntu-xenial\n";

  info($config);
    if (prompt_for_boolean(
      "Do you want to save this runtime-config as '$config_name'? [y|n]", 1
    )) {
      $self->env->bosh->upload_config($config,'runtime',$config_name);
    } else {
      info("Runtime config not uploaded.");
    }
  
  return $self->done();
}

sub was_deployed {
  my ($self) = @_;
  $self->env->deployments->current_state eq "deployed";
}

1;
# vim: set ts=2 sw=2 sts=2 noet fdm=marker foldlevel=1:
