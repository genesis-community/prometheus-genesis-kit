# Prometheus Genesis Kit Manual

The Prometheus Genesis Kit deploys a comprehensive monitoring solution with Prometheus, Grafana, and AlertManager components. This manual covers detailed setup instructions, configuration options, and advanced features.

## Requirements

- Genesis 2.7.10 or higher
- A BOSH Director with UAA
- Node Exporter must be installed on all BOSH VMs you would like to monitor using a BOSH runtime config addon
- BOSH Exporter requires a UAA account to access BOSH director information (requires BOSH Director deployed with bosh-genesis-kit v1.1.2+)
- For monitoring Cloud Foundry: CF deployment using cf-genesis-kit v1.1.0+

## Architecture

This Genesis Kit deploys the following components on a single VM:

- **Prometheus Server**: The core metrics collection and storage engine
- **Grafana**: Web UI for dashboards and visualization
- **AlertManager**: Alert processing and notification routing
- **Exporters**: Components that collect metrics from various sources
  - BOSH Exporter: Collects metrics from BOSH
  - CF Exporter (with monitor-cf feature): Collects metrics from Cloud Foundry 
  - CredHub Exporter (with monitor-credhub feature): Collects metrics from CredHub

Prometheus is exposed via HTTPS with basic authentication. The default username is `admin` with a password stored in your Vault at `$GENESIS_VAULT_PREFIX/admin:password`.

## Features

### SSL Certificates

#### `self-signed-certs`

This feature generates self-signed certificates for HTTPS access to Prometheus, Grafana, and AlertManager.

Certificate validity periods can be customized with parameters:
- `ca_validity_period`: Validity period for the CA certificate (default: 10 years)
- `webssl_validity_period`: Validity period for web certificates (default: 1 year)

Example:
```yaml
kit:
  features:
    - self-signed-certs
params:
  ca_validity_period: 5y
  webssl_validity_period: 2y
```

#### `provided-cert`

This feature allows you to use your own SSL certificates for the deployment.

The certificates are retrieved from your Vault:
- Certificate: `$GENESIS_VAULT_PREFIX/nginx/ssl_certificate:certificate`
- Private Key: `$GENESIS_VAULT_PREFIX/nginx/ssl_certificate:key`

Example:
```yaml
kit:
  features:
    - provided-cert
```

### Monitoring Targets

#### `monitor-cf`

Connects Prometheus to the Cloud Foundry Firehose to collect application and platform metrics.

Requirements:
- CF deployment with cf-genesis-kit v1.1.0+
- UAA client with Firehose access (created by cf-genesis-kit)

Configuration parameters:
- `doppler_port`: Port that CF Doppler listens on (default: 4443)
- `doppler_url`: URL to connect to CF Doppler (default: derived from CF exodus data)
- `skip_ssl_validation`: Whether to verify HTTPS certificates (default: false)
- `use_legacy_firehose`: Use v1 Firehose API instead of v2 API (see legacy-firehose feature)

Example:
```yaml
kit:
  features:
    - monitor-cf
params:
  skip_ssl_validation: true
```

#### `legacy-firehose`

Use this feature with older CF deployments that don't support the V2 loggregator API.

Example:
```yaml
kit:
  features:
    - monitor-cf
    - legacy-firehose
```

#### `monitor-cf-bbs`

Adds running-instance metrics to the `monitor-cf` feature. cf_exporter
2.x reads running-instance counts from Diego BBS rather than the retired
CF v2 API, so without this the `cf_application_instances_running` metric
and the alerts that depend on it are unavailable.

This is opt-in because it needs the CF deployment to publish its BBS
client certificate to exodus. Enable it once the cf-genesis-kit release
in use exports `bbs_ca`, `bbs_client_cert` and `bbs_client_key`. The
feature colocates a `bosh-dns-aliases` job so the BBS internal name
resolves from the prometheus VM, which keeps the connection verified.

Requirements:
- `monitor-cf` feature (cf v2.x)
- cf-genesis-kit release that exports the bbs client material to exodus

Configuration parameters:
- `cf_bbs_api_url`: BBS API endpoint (default: https://bbs.service.cf.internal:8889)
- `cf_network`: BOSH network of the CF diego-api instances (default: derived from CF exodus)

Example:
```yaml
kit:
  features:
    - monitor-cf
    - monitor-cf-bbs
```

#### `monitor-credhub`

Enables monitoring of CredHub metrics and health.

Example:
```yaml
kit:
  features:
    - monitor-credhub
```

Configuration parameters:
- `credhub_exporter_api_url`: CredHub API URL (default: from BOSH exodus data)
- `credhub_exporter_username`: CredHub client ID (default: from BOSH exodus data)
- `credhub_exporter_password`: CredHub client secret (default: from BOSH exodus data)
- `credhub_exporter_ca_cert`: CA certificate for CredHub (default: from BOSH exodus data)
- `credhub_exporter_deployment_name`: Deployment name for metrics labels (default: derived from environment)

### Infrastructure Support

#### `ocfp` (Open Container Framework Platform)

This feature adapts the Prometheus deployment for compatibility with OpenStack and Stackit infrastructures.

Example:
```yaml
kit:
  features:
    - ocfp
params:
  ocfp_env_scale: dev  # or prod
```

## Parameters

### General Infrastructure Configuration

* `disk_type` - The `persistent_disk_type` that Prometheus should use for storage (default: `prometheus`)
* `vm_type` - The `vm_type` that Prometheus should be deployed on (default: `default`) 
* `network` - The `network` that Prometheus should be deployed on (default: `prometheus`)
* `stemcell_os` - The operating system stemcell you want to deploy on (default: `ubuntu-jammy`)
* `stemcell_version` - The specific version of the stemcell you want to deploy on (default: `latest`)
* `static_ip` - The static IP to assign to the VM (required, no default)
* `availability_zones` - The BOSH availability zones to deploy to (default: `[z1]`)

### Prometheus Related Configuration

* `prometheus_port` - The port for Nginx to use to reverse proxy to Prometheus (default: `8080`)
* `grafana_port` - The port for the Nginx to use to reverse proxy to Grafana (default: `443`)
* `alertmanager_port` - The port for the Nginx to use to reverse proxy to AlertManager (default: `8082`)
* `external_domain` - The domain used to access this Prometheus deployment (default: value of `static_ip`)

### BOSH Integration Parameters

* `bosh_exodus_path` - The Exodus data path for BOSH director information (default: `$GENESIS_ENVIRONMENT/bosh`)
* `bosh` - Alternative name for the BOSH environment (default: value of `$GENESIS_ENVIRONMENT`)

### CF Integration Parameters (when using `monitor-cf`)

* `cf_env` - The Cloud Foundry environment to monitor (default: value of `$GENESIS_ENVIRONMENT`)
* `cf_exodus_path` - The Exodus data path for CF information (default: `$GENESIS_ENVIRONMENT/cf`)
* `doppler_port` - The port that CF Doppler listens on (default: `4443`)
* `doppler_url` - URL to connect to CF Doppler (default: derived from CF exodus data)
* `skip_ssl_validation` - Whether to verify HTTPS certificates (default: `false`)
* `rlp_gateway_url` - URL for the RLP gateway for Log Stream API (default: derived from CF system domain)

### CredHub Integration Parameters (when using `monitor-credhub`)

* `credhub_exodus_path` - The Exodus data path for CredHub information (default: `$GENESIS_ENVIRONMENT/bosh`)
* Plus parameters mentioned in the monitor-credhub feature section

## Cloud Config

The Prometheus Genesis Kit requires specific configurations in your cloud config:

### Network

A static IP address must be defined in the selected network (default network name: `prometheus`).

Example:
```yaml
networks:
- name: prometheus
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    static: [10.0.0.20]
    cloud_properties:
      name: my-network
```

### Persistent Disk

A `persistent_disk_type` named `prometheus` should be defined with at least 50GB of space.

Example:
```yaml
disk_types:
- name: prometheus
  disk_size: 51200 # Size in MB
  cloud_properties:
    type: gp2
```

### VM Type

A `vm_type` for the Prometheus VM (default name: `default`).

Example:
```yaml
vm_types:
- name: default
  cloud_properties:
    instance_type: m5.large
```

## Accessing Prometheus Components

After deployment, you can access the components using the following URLs:

- **Prometheus UI**: `https://<external_domain>:<prometheus_port>`
- **Grafana Dashboards**: `https://<external_domain>:<grafana_port>`
- **AlertManager UI**: `https://<external_domain>:<alertmanager_port>`

Default credentials for Prometheus and AlertManager:
- Username: `admin`
- Password: Stored in your Vault at `$GENESIS_VAULT_PREFIX/admin:password`

Default credentials for Grafana:
- Username: `admin`
- Password: Same as above, stored in your Vault at `$GENESIS_VAULT_PREFIX/admin:password`

## Node Exporter Addon

To monitor system metrics from all BOSH-deployed VMs, you need to deploy the Node Exporter as a BOSH addon.

Generate a Node Exporter runtime config:
```
genesis do my-prometheus -- runtime-config > runtime-config.yml
```

Then apply it to your BOSH director:
```
bosh update-runtime-config runtime-config.yml
```

## Performance Tuning

### Disk Sizing

Prometheus stores metrics in a time-series database on disk. The required disk size depends on:
- Number of metrics collected
- Retention period
- Scrape interval

Recommendations:
- Small deployments (< 100 VMs): 50GB
- Medium deployments (100-500 VMs): 200GB
- Large deployments (> 500 VMs): 500GB+

### Memory Allocation

Prometheus requires sufficient memory for querying metrics. Adjust the VM type based on:
- Number of metrics
- Query complexity
- Number of concurrent users

Recommendations:
- Small deployments: 4GB RAM
- Medium deployments: 8GB RAM
- Large deployments: 16GB+ RAM

## Troubleshooting

### Common Issues

#### Metrics Not Appearing

1. Check that the Node Exporter addon is deployed to your VMs
2. Verify connectivity between Prometheus and target endpoints
3. Check scrape configuration in Prometheus
4. Examine Prometheus logs with `bosh logs prometheus/0 --only prometheus`

#### Cannot Access Web UI

1. Verify the VM is running with `bosh instances`
2. Check that your firewall allows access to the configured ports
3. Verify SSL certificates are valid
4. Check Nginx configuration and logs

#### High Disk Usage

1. Review retention period settings
2. Consider implementing a federated architecture for larger deployments
3. Use recording rules to pre-compute expensive queries

## References

- [Prometheus BOSH Release](https://github.com/cloudfoundry-community/prometheus-boshrelease)
- [Node Exporter BOSH Release](https://github.com/cloudfoundry/node-exporter-boshrelease)
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)