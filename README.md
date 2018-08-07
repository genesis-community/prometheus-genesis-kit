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

## Monitoring

* `monitor-cf` - Have Prometheus connect to the CF Firehose to track
  CF app status + more. More info on setup can be found in [MANUAL.md][3])


[1]: https://github.com/cloudfoundry-community/prometheus-boshrelease
[2]: https://github.com/bosh-prometheus/node-exporter-boshrelease
[3]: MANUAL.md