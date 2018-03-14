Prometheus Genesis Kit
======================

This is a Genesis Kit for the [Prometheus Boshrelease][1]. It deploys
a single-VM prometheus deployment, with all jobs colocated on the single
VM, for a smaller footprint. As more metrics are consumed/monitored, and
additional services are added, this node will likely need to scale out
to increase its I/O throughput first. If possible, use SSD-backed storage
for its persistent disk pool in your Cloud Config.

Generally, you will have one prometheus VM per environment being deployed/monitored,
each prometheus would then monitor the BOSH deployments + services of that environment.

Additionally, you will want to ensure that the [node_exporter][3] is included in your
BOSH Runtime Config as an add-on, so that all BOSH VMs report their system health metrics
back to Prometheus.

Quick Start
-----------

To use it, you don't even need to clone this repository!  Just run
the following (using Genesis v2):

```
# create a prometheus-deployments repo using the latest version of the prometheus kit
genesis init --kit prometheus

# create a prometheus-deployments repo using v1.0.0 of the prometheus kit
genesis init --kit prometheus/1.0.0

# create a my-prometheus-configs repo using the latest version of the prometheus kit
genesis init --kit prometheus -d my-shield-configs
```

Subkits
-------

Subkits are provided to monitor commonly deployed things alongside Genesis. These
are configurable via the following subkits:

- **cf** - Enables the monitoring of a Cloud Foundry environment. Metrics are pulled
  from the Cloud Controller API, as well as via the CF Firehose. It is set up to easily
  integrate monitoring into a CF deployed using the [cf-genesis-kit][3]. Additionally,
  this subkit will enable a route-registration with Cloud Foundry, so that you may
  access your Grafana dashboard at `monitoring.<system_domain>`, and your Prometheus
  alerts dashboard at `alerts.<system_domain>`.
- **bosh** - Enables the monitoring of a BOSH director, its jobs/deployments, and enables
  the auto-configuration of what VMs are to be scraped, as well as VM/IP associations,
  to match data up with other exporters. It is set up to easily monitor a BOSH deployed
  with the [bosh-genesis-kit][4]
- **postgres** - Enables the monitoring of a single postgres server (can have multiple databases
  on the single server though). Usually this will be set up to monitor your Cloud Foundry's
  CC/UAA/Diego/Router databases.
- **elasticsearch** - Enables the monitoring of an ElasticSearch Cluster, such as that deployed
  via the [logsearch-genesis-kit][5].
- **rabbitmq** - Enables the monitoring of a RabbitMQ cluster, such as that deployed via
  the [cf-rabbitmq-genesis-kit][6].

Params
------

#### Base

- **params.prometheus_disk_pool** - used to define the persistent disk pool that the Vault VMs will
  be given. This pool must exist in the Cloud Config of the BOSH director that deploys
  Vault. This defaults to `prometheus`. It is highly advised that you make this on fast/SSD
  backed storage.
- **params.prometheus_vm_type** - used to define the Cloud Config VM type that the Vault VM
  will be given. This VM type must exist in the Cloud config of the BOSH director that
  deploys Vault. This defaults to `small`.
- **params.prometheus_network** - used to define the Cloud Config network that the Vault
  VM will be located on. This network must exist in the Cloud Config of the BOSH director
  that deploys Vault. It defaults to `prometheus`, but typically this can be located
  on a shared-infrastructure network.
- **params.availability_zones** - defines the availability zones that VMs will be placed into.
  Defaults to a list of just `z1` (since there's only one Prometheus VM).

#### cf

Default values for the `cf` subkit's params are set up to work nicely with those of the
[cf-genesis-kit][3].

- **params.cf_system_domain** - The system domain of the monitored Cloud Foundry. Used to
  pull information out of the Cloud Controller API. It is also used as the domain suffix
  for the `monitoring` and `alerts` routes set up to access Grafana/Prometheus.
- **params.cf_admin_user** - The admin username used to connect to the Cloud Controller.
  This should be a user with admin access to the Cloud Foundry being monitored. Defaults
  to `admin`.
- **params.cf_admin_password** - A vault path containing the above admin user's password.
  For example: `secret/us/west/prod/cf/admin_user:password`
- **params.cf_doppler_port** - Depending on your infrastructure, you may be advertising
  your Cloud Foundry's doppler endpoint on port `443`, or port `4443`, or something else
  entirely. This allows you to override the default of `443`.
- **params.cf_firehose_client** - This must be the name of a UAA client with the `doppler.firehose`
  scope (defaults to `firehose`)
- **params.cf_firehose_client_secret** - A vault path which contains the client secret for the
  above UAA client. For example: `secret/us/west/prod/cf/uaa/client_secrets:firehose`
- **params.cf_deployment** - The name of the BOSH deployment of the Cloud Foundry
  being monitored. This is used to discover how to communicate with NATS in order
  to register the `monitoring` and `alerts` domains for Grafana/Prometheus. By
  default, uses the current environment name concatenated with `cf`. For example,
  in the `us-west-prod` environment, this would be `us-west-prod-cf`.

#### bosh

Default values for the `bosh` subkit's params are set up to work nicely with those of
the [bosh-genesis-kit][4].

- **params.bosh_host** - The IP of the BOSH director to be monitored
- **params.bosh_port** - The port of the BOSH director to be monitored (defaults to `25555`).
- **params.bosh_user** - The username with which to authenticate to the BOSH director (defaults to `admin`).
- **params.bosh_password** - A vault path which contains the password of the above BOSH user. For example:
  `secret/us/west/bosh/users/admin:password`.
- **params.bosh_ca_cert** - A vault path which contains the CA certificate for the CA that signed the BOSH
  monitored director's SSL certificate. For example: `secret/us/west/prod/bosh/ssl/ca:certificate`.

#### blackbox
- **params.monitored_endpoints** - A list of URLs that Prometheus should monitor
  with its [blackbox_exporter][2]. These will show up in the `Probe: HTTPS Summary` dashboard
- **params.skip_ssl_verify** - Defines whether the Promtheus exporters skip SSL cert
  validation when connecting to the various monitored components they watch. Off by default
  (certs are checked). Enable this if you have self-signed certs in your deployment.

#### postgres

Default values of the `postgres` subkit are set up to work nicely with the database instance
provided in the [cf-genesis-kit][3] deployment.

- **params.pg_host** - The IP of the monitored Postgres instance
- **params.pg_port** - The port that the monitored Postgres is listening on (defaults to 5432)
- **params.pg_sslmode** - Determines whether SSL is used or not when connecint go the monitored
  postgres (default is 'disabled')
- **params.pg_user** - The user to connect to the monitored Postgres instance with (defaults to `shield).
- **params.pg_password** - A vault path which contains the password for the above PG user. For example:
  `secret/us/west/cf/postgres:shield_password`

#### elasticsearch

- **params.elasticsearch_uri** - The URL for the monitored ElasticSearch cluster's master node

#### rabbitmq

Default values of the `rabbitmq` subkit are set up to work well with the [cf-rabbitmq-genesis-kit][6].

- **params.rabbitmq_url** - The URL for the monitored RabbitMQ cluster (e.g. `rabbitmq.system.bosh-lite.com`)
- **params.rabbitmq_user** - The username used to connect to the monitored RabbitMQ cluster
  ( defaults to `admin`)
- **params.rabbitmq_password** - A vault path which contains the password for the above
  RabbitMQ user. For example: `secret/us/west/cf-rabbitmq/rabbitmq/client_secrets:admin`
- **params.rabbitmq_include_queues** - A regex of queues to explicitly include in monitoring
- **params.rabbitmq_exclude_queues** - A regex of queues to explicitly exclude in monitoring

Cloud Config
------------

By default, Promethesu uses the following VM types/networks/disk pools from your
Cloud Config. Feel free to override them in your environment, if you would
rather they use entities already existing in your Cloud Foundry:

```
params:
  prometheus_network:   prometheus
  prometheus_disk_pool: prometheus # should be at least 50GB of fast (SSD) storage
  prometheus_vm_type:   small      # VMs should have at least 1 CPU, and 1GB of memory,
                                   # but will quickly scale up, the more you monitor
```


[1]: https://github.com/cloudfoundry-community/prometheus-boshrelease
[2]: https://github.com/prometheus/blackbox_exporter
[3]: https://github.com/genesis-community/cf-genesis-kit
[4]: https://github.com/genesis-community/bosh-genesis-kit
[5]: https://github.com/genesis-community/logsearch-genesis-kit
[6]: https://github.com/genesis-community/cf-rabbitmq-genesis-kit
