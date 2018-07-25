Prometheus Genesis Kit
=================

This is a Genesis Kit for the [Prometheus Boshrelease][1]. It deploys
a single-VM prometheus deployment, with all jobs colocated on the
single VM, for a smaller footprint. As more metrics are
consumed/monitored, and additional services are added, this node will
likely need to scale out to increase its I/O throughput first. If
possible, use SSD-backed storage for its persistent disk pool in your
Cloud Config.

Generally, you will have one prometheus VM per environment being
deployed/monitored, each prometheus would then monitor the BOSH
deployments + services of that environment.

Additionally, you will want to ensure that the [node_exporter][2] is
included in your BOSH Runtime Config as an add-on, so that all BOSH
VMs report their system health metrics back to Prometheus.

Quick Start
-----------

To use it, you don't even need to clone this repository! Just run the
following (using Genesis v2):

```
# create a prometheus-deployments repo using the latest version of the prometheus kit
genesis init --kit prometheus

# create a prometheus-deployments repo using v1.0.0 of the prometheus kit
genesis init --kit prometheus/1.0.0

# create a my-prometheus-configs repo using the latest version of the prometheus kit
genesis init --kit prometheus -d my-prometheus-configs
```

Once created, refer to the deployment repository README for
information on provisioning and deploying new environments.

Features
-------

## SSL Certificates

* `self-signed-certs` - If you wish to have Genesis generate
  self-signed certs for you. 
* `provided-cert` - If you have SSL cert/key to provide, which is
  grabbed from Vault via path:
  `$GENESIS_VAULT_PATH/nginx/ssl_certificate:certificate` and
  `$GENESIS_VAULT_PATH/nginx/ssl_certificate:key`

## Authentication

* `http-auth` - By default, only Grafana supports authentication via
  the web UI. This feature adds HTTP Basic Authentication to
  AlertManager and Prometheus with automatically generated
  credentials.

## Monitoring

* `monitor-cf` - Have Prometheus connect to the CF Firehose to track
  CF app status + more. Requires two UAA accounts (more info in
  [MANUAL.md][3])

Params
------

### General Infrastructure Configuration
* `disk_type` - The `persistent_disk_type` that Prometheus should use
  for storage. (default: `prometheus`)
* `vm_type`- The `vm_type` that Prometheus should be deployed on.
  (default: `default`) 
* `network` - The `network` that Prometheus should be deployed on.
  (default: `prometheus`)
* `stemcell_os` - The operating system stemcell you want to deploy on.
  (default: `ubuntu-trusty`)
* `stemcell_version` - The specific version of the stemcell you want
  to deploy on. (default: `latest`)
* `static_ip` - The static IP to assign to the VM. (no default)

### Minio Related Configuration
* `prometheus_port` - The port for Nginx to use to reverse proxy to
  Prometheus. (default: `443`)
* `grafana_port` - The port for the Nginx to use to reverse proxy to
  Grafana. (default: `8080`)
* `alertmanager_port` - The port for the Nginx to use to reverse proxy
  to AlertManager. (default: `8082`)
* `external_domain` - The domain used to access this Prometheus
  deployment. Can be either a FQDN or IP address. (no default)


Cloud Config
------------

The Prometheus Genesis Kit requires a static IP address to be defined
in the selected network configuration (by default, `prometheus`). It
also requires a `persistent_disk_type` (of about `1024MB`) to store
graph history and Grafana DB.


[1]: https://github.com/cloudfoundry-community/prometheus-boshrelease
[2]: https://github.com/bosh-prometheus/node-exporter-boshrelease
[3]: MANUAL.md