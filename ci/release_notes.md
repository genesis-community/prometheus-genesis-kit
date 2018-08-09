# Improvements 

This release squashes a few bugs found:
  * Migrated from using the BOSH admin user/password authentication method over to a specifically created `prometheus` UAA client. This fixes an issue where `bosh_exporter` would stop collecting data after token expiration.
  * Grafana and Prometheus scraping from Service Discovery has been fixed.

This release requires `bosh-genesis-kit` version 1.1.2, which creates the UAA account necessary for gathering BOSH metrics.
