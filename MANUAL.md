# Prometheus Genesis Kit Manual 
The Prometheus Genesis Kit deploys a single-VM installation of
Prometheus, Grafana, and AlertManager. It's capable of monitoring BOSH
and Cloudfoundry.

## Requirements

[Node Exporter][1] must be installed on all BOSH VMs you would like
to monitor. Please consult the README of that repository on how to
setup the BOSH addon.


## Features

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
  CF app status + more. Requires two UAA accounts, one with the
  `cloud_controller.admin_read_only` scope, and the `doppler.firehose`
  scope. To create these accounts, here's an example:
```
uaac client add prometheus-cf \
  --name prometheus-cf \
  --secret <64 char secret> \
  --authorized_grant_types client_credentials,refresh_token \
  --authorities cloud_controller.admin_read_only

uaac client add prometheus-firehose \
  --name prometheus-firehose \
  --secret <64 char secret> \
  --authorized_grant_types client_credentials,refresh_token \
  --authorities doppler.firehose
```

  This will add the user `prometheus-cf` and `prometheus-firehose`,
  with the secrets of your choice. `prometheus-cf` will have the
  `cloud_controller.admin_read_only` scope, and the
  `prometheus-firehose` will have the `doppler.firehose` scope.

  These credentials are stored in `$GENESIS_VAULT_PATH/cf_uaa_logins`:

  *cloud_controller.admin_read_only* scope:
  * `cf_uaa_logins:cf_exporter_client_id`
  * `cf_uaa_logins:cf_exporter_client_secret`

  *doppler.firehose* scope:
  * `cf_uaa_logins:firehose_exporter_client_id`
  * `cf_uaa_logins:firehose_exporter_client_secret`


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
  deployment. Can be either a FQDN or IP address. (no default)

## Cloud Config

The Prometheus Genesis Kit requires a static IP address to be defined
in the selected network configuration (by default, `prometheus`). It
also requires a `persistent_disk_type` (of about `1024MB`) to store
graph history and Grafana DB.

[1]: https://github.com/bosh-prometheus/node-exporter-boshrelease