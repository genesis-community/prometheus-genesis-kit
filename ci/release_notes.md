# Updates

* Updated prometheus-boshrelease to 24.1.0
* Updated postgres-release to 36

# Parameters

* A new parameter, `use_legacy_firehose`, was added to the monitor-cf feature.
	This defaults to true. If set to false, prometheus will use the v2
	Loggregator API. In such a case, You may need to override
	`instance_groups.firehose_exporter.properties.firehose_exporter.logging.url`
	if the logging URL is not properly formatted for the v2 API.

# Upgrading

This release bumps the version of Postgres from 11.2 to 11.3. To facilitate a
clean upgrade, please upgrade to kit version 1.3.0 or 1.3.1 before upgrading to
this version.

# Components

| Release                | Version | Release Date |
| ---------------------- | ------- |
| prometheus-boshrelease | [25.0.0](https://github.com/bosh-prometheus/prometheus-boshrelease/releases/tag/v25.0.0) | Apr 25, 2019 |
| postgres-release       | [37](https://github.com/cloudfoundry/postgres-release/releases/tag/v37) | May 11, 2019 |
| node-exporter          | [4.1.0](https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/tag/v4.1.0) | Dec 1, 2018 |
