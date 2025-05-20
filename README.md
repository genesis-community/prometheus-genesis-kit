# Prometheus Genesis Kit

This Genesis Kit deploys a production-ready Prometheus monitoring system, including Prometheus, Grafana, and AlertManager components on a single VM for a smaller footprint. It's designed to monitor BOSH deployments and services like Cloud Foundry.

## Overview

The Prometheus Genesis Kit uses the [Prometheus BOSH Release](https://github.com/cloudfoundry-community/prometheus-boshrelease) to deploy a comprehensive monitoring solution with the following components:

- **Prometheus** - Time series database and monitoring system
- **Grafana** - Visualization and dashboarding platform
- **AlertManager** - Alert handling and routing system

By default, this kit deploys all components on a single VM for ease of management and reduced footprint. As your monitoring needs grow, you may need to scale out to increase I/O throughput. For optimal performance, use SSD-backed storage for the persistent disk pool in your Cloud Config.

## Architecture

This kit creates a single-VM deployment with these colocated components:

- Prometheus server for metrics collection and storage
- Grafana for metrics visualization
- AlertManager for alert management
- BOSH Exporter for collecting BOSH metrics
- Nginx for secure access to dashboards

Each component is exposed via HTTPS with basic authentication. The kit configures proper integration between all components, with Grafana pre-configured to connect to Prometheus and loaded with useful dashboards.

## Prerequisites

- Genesis 2.7.10 or higher
- BOSH Director with UAA
- [Node Exporter](https://github.com/bosh-prometheus/node-exporter-boshrelease) should be deployed as a BOSH addon to collect system metrics from all VMs
- For monitoring Cloud Foundry: A CF deployment created with cf-genesis-kit v1.1.0 or higher
- For monitoring BOSH: A BOSH director deployed with bosh-genesis-kit v1.1.2 or higher

## Quick Start

To use this kit, you don't even need to clone this repository! Just run the following (using Genesis v2):

```bash
# Create a prometheus-deployments repo using the latest version of the prometheus kit
genesis init --kit prometheus

# Create a prometheus-deployments repo using v1.0.0 of the prometheus kit
genesis init --kit prometheus/1.0.0

# Create a my-prometheus-configs repo using the latest version of the prometheus kit
genesis init --kit prometheus -d my-prometheus-configs
```

Once created, refer to the deployment repository README for information on provisioning and deploying new environments.

## Features

### Core Features

* `self-signed-certs` - Generate and use self-signed certificates for the deployment
* `provided-cert` - Use your own provided SSL certificates (from Vault)

### Monitoring Targets

* `monitor-cf` - Connect to Cloud Foundry Firehose to monitor CF application metrics
* `monitor-cf-v2` - Connect to Cloud Foundry v2 using Loggregator API
* `legacy-firehose` - Use the legacy firehose API for CF deployments (use with `monitor-cf`)
* `monitor-credhub` - Monitor CredHub metrics and health

### Infrastructure Support

* `ocfp` - OpenStack/Stackit compatibility layer for Open Container Framework Platform deployments

## Supported IaaS Providers

This Genesis Kit supports deployment to multiple infrastructure providers:

- **AWS** - Amazon Web Services
- **GCP** - Google Cloud Platform
- **Azure** - Microsoft Azure
- **vSphere** - VMware vSphere
- **OpenStack** - OpenStack platforms
- **Stackit** - Stackit IaaS (based on OpenStack)

For IaaS-specific deployment instructions, see the corresponding documentation in the `docs/` directory.

## Deployment

After initializing your deployment repository, create an environment file for your target deployment. For example, `my-prometheus.yml`:

```yaml
---
kit:
  name:    prometheus
  version: latest
  features:
    - self-signed-cert
    - monitor-cf

params:
  static_ip: 10.0.0.20
  external_domain: prometheus.example.com
```

Then deploy with:

```bash
genesis deploy my-prometheus
```

## Common Operations

Access the various UIs:

```bash
# Open Prometheus UI
genesis do my-prometheus -- open prometheus

# Open Grafana UI
genesis do my-prometheus -- open grafana

# Open AlertManager UI
genesis do my-prometheus -- open alertmanager
```

Generate a runtime config for node exporter:

```bash
genesis do my-prometheus -- runtime-config > runtime-config.yml
bosh update-runtime-config runtime-config.yml
```

Check deployment status:

```bash
genesis check my-prometheus
```

## Example Deployment Scenarios

For more detailed examples, please refer to the `examples/` directory:

- `examples/basic.yml` - Simple Prometheus deployment
- `examples/monitor-cf.yml` - Prometheus with Cloud Foundry monitoring
- `examples/monitor-credhub.yml` - Prometheus with CredHub monitoring
- `examples/stackit-example.yml` - Example for Stackit IaaS deployments

## Further Reading

- [MANUAL.md](MANUAL.md) - Detailed information on features, parameters, and configuration
- [docs/](docs/) - Additional documentation for specific use cases and IaaS providers
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)

## Troubleshooting

For common issues and solutions, please refer to the `docs/troubleshooting.md` document.

## License

This Genesis Kit is released under the MIT license.

[1]: https://github.com/cloudfoundry-community/prometheus-boshrelease
[2]: https://github.com/bosh-prometheus/node-exporter-boshrelease
[3]: MANUAL.md