# Prometheus Genesis Kit Manual 
The Prometheus Genesis Kit deploys a single-VM installation of
Prometheus, Grafana, and AlertManager. It's capable of monitoring BOSH
and Cloudfoundry.

## Requirements

Genesis version 2.6.8 or higher.

[Node Exporter][1] must be installed on all BOSH VMs you would like to
monitor. Please consult the README of that repository on how to setup
the BOSH addon.

[Bosh Exporter][2] requires a UAA account to access BOSH director
information. This requires that the BOSH director was deployed with
`bosh-genesis-kit` version `1.1.2` or higher.


## Features

## SSL Certificates

* `self-signed-certs` - If you wish to have Genesis generate
  self-signed certs for you. 
* `provided-cert` - If you have SSL cert/key to provide, which is
  grabbed from Vault via path:
  `$GENESIS_VAULT_PATH/nginx/ssl_certificate:certificate` and
  `$GENESIS_VAULT_PATH/nginx/ssl_certificate:key`

## Monitoring

* `monitor-cf` - Have Prometheus connect to the CF Firehose to track
  CF app status + more. Requires that the CF installation was deployed
  with `cf-genesis-kit` version `1.1.0` or higher.

## Params

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

### Prometheus Related Configuration
* `prometheus_port` - The port for Nginx to use to reverse proxy to
  Prometheus. (default: `443`)
* `grafana_port` - The port for the Nginx to use to reverse proxy to
  Grafana. (default: `8080`)
* `alertmanager_port` - The port for the Nginx to use to reverse proxy
  to AlertManager. (default: `8082`)
* `external_domain` - The domain used to access this Prometheus
  deployment. Can be either a FQDN or IP address. (default: value of
  `static_ip`)

### `monitor-cf` Feature Configuration

* `doppler_port` - The port that CF Doppler listens on. (defaut: `4443`)
* `doppler_url` - The URL to use to connect to CF Doppler (default is extracted
  from Genesis Exodus data, which is `doppler.` + your CF system domain)

## Cloud Config

The Prometheus Genesis Kit requires a static IP address to be defined
in the selected network configuration (by default, `prometheus`). It
also requires a `persistent_disk_type` (of about `51200MB`) to store
graph history and Grafana DB.

[1]: https://github.com/bosh-prometheus/node-exporter-boshrelease
[2]: https://github.com/bosh-prometheus/prometheus-boshrelease