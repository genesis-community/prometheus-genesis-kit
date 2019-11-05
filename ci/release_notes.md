# Release Changes

- Prometheus updated to 26.0.1 from 25.0.0
- Postgres updated to 38 from 37
- Node Exporter updated to 4.2.0 from 4.1.0

# Fixes

- The BOSH dynamic scrape config now looks for the `web` job for Concourse,
	instead of the `atc` job. This makes it work for Concourse 5+, but now it
	won't match versions earlier than that.
- The scrape config for Concourse now scrapes metrics from the `/` path instead
	of the `/metrics` path, as this is where Concourse exposes Prometheus
	metrics.

# Upgrading

This release bumps the version of Postgres from 11.3 to 11.4. To facilitate a
clean upgrade, please upgrade to kit version 1.4.0 before upgrading to
this version.

# Components

| Release                | Version | Release Date |
| ---------------------- | ------- |----------|
| prometheus-boshrelease | [26.0.1](https://github.com/bosh-prometheus/prometheus-boshrelease/releases/tag/v26.0.1) | Oct 30, 2019 |
| postgres-release       | [38](https://github.com/cloudfoundry/postgres-release/releases/tag/v38) | Jun 21, 2019 |
| node-exporter          | [4.2.0](https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/tag/v4.2.0) | Aug 29, 2019 |

