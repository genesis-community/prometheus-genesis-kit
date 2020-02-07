# Breaking Changes

* Newer versions of Cloud Foundry use Loggregator API v2, and previously this kit kept v1 as a default,
  as our CF kits did not deploy a version of Loggregator that used this API yet. Now that we do have CF
  kits that support Loggregator API v2, the cf-exporter will now support this new API by default. To
  use the v1 API, you will need to enable the new `legacy-firehose` feature.
* Due to the inclusion of the `legacy-firehose` feature, the `use_legacy_firehose` parameter used by
  the `monitor-cf` feature has been removed.

# Components

| Release                | Version | Release Date |
| ---------------------- | ------- |----------|
| prometheus-boshrelease | [26.2.0](https://github.com/bosh-prometheus/prometheus-boshrelease/releases/tag/v26.2.0) | Jan 22, 2020 |
| postgres-release       | [40](https://github.com/cloudfoundry/postgres-release/releases/tag/v40) | Dec 6, 2019 |
| node-exporter          | [4.2.0](https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/tag/v4.2.0) | Aug 29, 2019 |
