# Overview

This release modernizes the Prometheus Genesis Kit for Genesis 2.6. It
also is a total rewrite of the existing kit.

Prometheus is now version v23.1, is fully HTTPS for web UI endpoints,
and uses `node_exporter`, `bosh_exporter`, and `service_discovery` to
as a baseline to gather all VM status. A feature, named `monitor-cf`
uses two CF UAA accounts to connect to the Firehose and Cloud
Controller to gain insight into CF status. Grafana is included for
visualizing the metrics, and AlertManager for sending notifications
during alerts.

Previous Prometheus Genesis Kit manifests are wholly incompatible with
this upgrade. 