# Advanced Monitoring Configuration Guide

This guide covers advanced configuration options for the Prometheus Genesis Kit, including customizing scrape configurations, setting up alerting rules, configuring Grafana dashboards, and integrating with external systems.

## Customizing Prometheus Scrape Configurations

The Prometheus Genesis Kit includes default scrape configurations for common BOSH-deployed components. You can customize or extend these configurations by adding custom ops files.

### Creating Custom Scrape Configurations

1. Create an ops file in your deployment's `ops` directory (e.g., `ops/custom-scrape.yml`):

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/scrape_configs/-
  value:
    job_name: custom_exporter
    static_configs:
    - targets:
      - custom_exporter.example.com:9100
    scheme: https
    tls_config:
      insecure_skip_verify: false
    basic_auth:
      username: ((custom_auth.username))
      password: ((custom_auth.password))
```

2. Reference this ops file in your environment file:

```yaml
---
kit:
  name: prometheus
  version: latest
  features:
    - self-signed-cert

params:
  # Standard parameters...

exodus:
  custom_auth:
    username: admin
    password: ((vault-path/to/password))
```

### Custom Scrape Intervals

To modify scrape intervals for specific jobs:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/scrape_configs/job_name=node
  value:
    job_name: node
    scrape_interval: 30s
    scrape_timeout: 10s
    file_sd_configs:
    - files: [ /var/vcap/store/bosh_exporter/bosh_target_groups.json ]
    relabel_configs:
    - action: keep
      regex: node_exporter
      source_labels: [ __meta_bosh_job_process_name ]
    - regex: (.*)
      replacement: ${1}:9100
      source_labels: [ __address__ ]
      target_label: __address__
```

## Advanced Alerting Configuration

### Creating Custom Alert Rules

1. Create a custom alerts ops file (e.g., `ops/custom-alerts.yml`):

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/-
  value:
    name: custom_alerts
    release: prometheus
    properties:
      custom_alerts:
        custom_alert_rules: |
          groups:
          - name: custom.rules
            rules:
            - alert: HighCPUUsage
              expr: avg by(job, instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100 < 10
              for: 5m
              labels:
                severity: warning
              annotations:
                summary: High CPU usage detected
                description: "CPU usage is above 90% for 5 minutes on {{ $labels.instance }}"
```

2. Add the alert rules file to Prometheus configuration:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/rule_files/-
  value: /var/vcap/jobs/custom_alerts/*.alerts.yml
```

### Customizing AlertManager

1. Create an ops file to modify AlertManager configuration (e.g., `ops/alertmanager-config.yml`):

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=alertmanager/properties/alertmanager
  value:
    receivers:
    - name: default
      email_configs:
      - to: 'alerts@example.com'
        from: 'prometheus@example.com'
        smarthost: 'smtp.example.com:587'
        auth_username: '((smtp.username))'
        auth_password: '((smtp.password))'
    - name: pagerduty
      pagerduty_configs:
      - service_key: ((pagerduty.service_key))
    - name: slack
      slack_configs:
      - api_url: ((slack.webhook_url))
        channel: '#alerts'
    route:
      receiver: default
      group_by: ['alertname', 'job']
      group_wait: 30s
      group_interval: 5m
      repeat_interval: 4h
      routes:
      - match:
          severity: critical
        receiver: pagerduty
      - match:
          severity: warning
        receiver: slack
    inhibit_rules:
    - source_match:
        severity: 'critical'
      target_match:
        severity: 'warning'
      equal: ['alertname', 'instance']
```

## Advanced Grafana Configuration

### Adding Custom Dashboards

1. Create a folder to store your custom dashboards in your deployment directory:

```bash
mkdir -p dashboards
```

2. Add JSON dashboard definitions to this directory.

3. Create an ops file to include these dashboards (e.g., `ops/custom-dashboards.yml`):

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/-
  value:
    name: custom_dashboards
    release: prometheus
    properties:
      custom_dashboards:
        dashboards:
          - name: my-custom-dashboard
            content: |
              ((dashboard.my-custom-dashboard))

- type: replace
  path: /instance_groups/name=prometheus/jobs/name=grafana/properties/grafana/prometheus/dashboard_folders/-
  value:
    name: CustomDashboards
    files:
    - /var/vcap/jobs/custom_dashboards/*.json
```

4. Include the dashboard JSON in your environment exodus data:

```yaml
exodus:
  dashboard:
    my-custom-dashboard: |
      {
        "dashboard": {
          "title": "My Custom Dashboard",
          "panels": [
            # Dashboard JSON definition here
          ]
        }
      }
```

### Configuring Grafana Data Sources

To add additional data sources to Grafana:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=grafana/properties/grafana/datasources
  value:
    - name: prometheus
      type: prometheus
      url: http://localhost:9090
      access: proxy
      is_default: true
    - name: influxdb
      type: influxdb
      url: https://influxdb.example.com
      access: proxy
      user: admin
      password: ((influxdb.password))
      database: metrics
```

## External Storage Integration

### Configuring Remote Write

For long-term storage or federation, configure remote write:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/remote_write
  value:
    - url: https://thanos.example.com/api/v1/receive
      basic_auth:
        username: prometheus
        password: ((thanos.password))
      queue_config:
        capacity: 10000
        max_samples_per_send: 2000
        batch_send_deadline: 5s
        min_backoff: 30ms
        max_backoff: 100ms
```

### HA Setup with Multiple Prometheus Instances

For high availability, consider deploying multiple Prometheus instances:

1. Create a separate environment file for each instance
2. Use different static IPs for each instance
3. Configure a load balancer in front of them
4. Use consistent labels to deduplicate alerts

## Performance Tuning

### Memory Management

For environments with high cardinality or many metrics:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/storage
  value:
    tsdb:
      min_block_duration: 2h
      max_block_duration: 6h
      retention:
        time: 15d
```

### Query Performance

To improve query performance, add recording rules:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/-
  value:
    name: recording_rules
    release: prometheus
    properties:
      recording_rules:
        rules: |
          groups:
          - name: recording.rules
            rules:
            - record: job:node_cpu_seconds:avg_rate5m
              expr: avg by (job) (rate(node_cpu_seconds_total{mode!="idle"}[5m]))
```

## Integrating with External Systems

### PagerDuty Integration

Configure AlertManager to send alerts to PagerDuty:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=alertmanager/properties/alertmanager/receivers/-
  value:
    name: pagerduty
    pagerduty_configs:
    - service_key: ((pagerduty.service_key))
      description: '{{ template "pagerduty.default.description" . }}'
      client: 'prometheus'
      client_url: 'https://{{ index .Alerts 0 "Labels" "external_url" }}'
      severity: '{{ if eq (index .Alerts 0 "Labels" "severity") "critical" }}critical{{ else }}warning{{ end }}'
```

### Slack Integration

Configure AlertManager to send alerts to Slack:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=alertmanager/properties/alertmanager/receivers/-
  value:
    name: slack
    slack_configs:
    - api_url: ((slack.webhook_url))
      channel: '#alerts'
      text: '{{ template "slack.default.text" . }}'
      title: '{{ template "slack.default.title" . }}'
      title_link: 'https://{{ index .Alerts 0 "Labels" "external_url" }}'
      color: '{{ if eq (index .Alerts 0 "Labels" "severity") "critical" }}danger{{ else }}warning{{ end }}'
```

### Email Integration

Configure AlertManager to send email alerts:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=alertmanager/properties/alertmanager/receivers/-
  value:
    name: email
    email_configs:
    - to: 'team@example.com'
      from: 'prometheus@example.com'
      smarthost: 'smtp.example.com:587'
      auth_username: '((smtp.username))'
      auth_password: '((smtp.password))'
      require_tls: true
```

## Advanced Monitoring Use Cases

### Multi-cluster Federation

To monitor multiple Prometheus instances, set up federation:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=prometheus2/properties/prometheus/scrape_configs/-
  value:
    job_name: federate
    scrape_interval: 15s
    honor_labels: true
    metrics_path: /federate
    params:
      match[]:
        - '{job="node"}'
        - '{job="bosh"}'
        - '{__name__=~"job:.*"}'
    static_configs:
      - targets:
        - prometheus-secondary-1.example.com:9090
        - prometheus-secondary-2.example.com:9090
```

### Service Level Objectives (SLOs)

Implement SLO monitoring with recording rules:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/-
  value:
    name: slo_rules
    release: prometheus
    properties:
      slo_rules:
        rules: |
          groups:
          - name: slo.rules
            rules:
            - record: slo:http_requests_total:availability_ratio
              expr: sum(rate(http_requests_total{status!~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
            - alert: SLOViolation
              expr: slo:http_requests_total:availability_ratio < 0.95
              for: 5m
              labels:
                severity: critical
              annotations:
                summary: Service availability below 95%
                description: Service has been below 95% availability for 5 minutes.
```

## Security Hardening

### TLS Configuration

Enhance security with stronger TLS configuration:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=nginx/properties/nginx/ssl_protocols
  value: TLSv1.2 TLSv1.3

- type: replace
  path: /instance_groups/name=prometheus/jobs/name=nginx/properties/nginx/ssl_ciphers
  value: HIGH:!aNULL:!MD5
```

### Authentication and Authorization

Implement more granular access control in Grafana:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/name=grafana/properties/grafana/auth
  value:
    ldap:
      enabled: true
      config_file: /var/vcap/jobs/grafana/config/ldap.toml
    users:
      allow_sign_up: false
      auto_assign_org: true
      auto_assign_org_role: Viewer
```

### Network Security

Restrict network access with iptables rules:

```yaml
---
- type: replace
  path: /instance_groups/name=prometheus/jobs/-
  value:
    name: iptables
    release: os-conf
    properties:
      iptables:
        rules:
        - INPUT -p tcp --dport 443 -j ACCEPT
        - INPUT -p tcp --dport 8080 -j ACCEPT
        - INPUT -p tcp --dport 8082 -j ACCEPT
        - INPUT -p tcp -s 10.0.0.0/24 --dport 9090 -j ACCEPT
        - INPUT -p tcp -j DROP
```

## Conclusion

This advanced configuration guide demonstrates the flexibility of the Prometheus Genesis Kit. By leveraging ops files and custom configurations, you can extend the monitoring solution to meet complex requirements while maintaining the benefits of the Genesis framework's standardized deployment approach.