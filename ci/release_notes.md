# Improvements

- Added support for monitoring credhub (`monitor-credhub` feature).

- Better support for cf-genesis-kit v2.0.0.

- Better wizard for creating new environments.
  - Automatically detects prometheus network and IP address
  - Simpler interface for adding monitors.

- Updated for Genesis v2.7 deployment (min patch version 9).  Allows
  alternative paths for secret and exodus.

  If you are using params.env or params.bosh in you environment files, you will
  need to replace these values with genesis.env or genesis:bosh\_env
  respectively.

- Added support for provided SSL certificates when adding/checking secrets.

# Bug Fixes

- If you specified the `params.bosh_exodus_path` in your environment files,
  then this kit would expect your cf exodus data under your bosh exodus path,
  such as `/secrets/my-bosh-env/bosh/cf` -- this has been corrected to look
  under the exodus path  using the same name as your prometheus deployment + '/cf';
  if this isn't correct for your situation, you can specify the cf deployment
  name with `params.cf_exodus_path`

# Components

| Release                | Version | Release Date |
| ---------------------- | ------- |----------|
| prometheus-boshrelease | [26.3.0](https://github.com/bosh-prometheus/prometheus-boshrelease/releases/tag/v26.3.0) | Sep 27, 2020 |
| postgres-release       | [42](https://github.com/cloudfoundry/postgres-release/releases/tag/v42) | Aug 18, 2020 |
| node-exporter          | [5.0.0](https://github.com/bosh-prometheus/node-exporter-boshrelease/releases/tag/v5.0.0) | Aug 15, 2020 |
