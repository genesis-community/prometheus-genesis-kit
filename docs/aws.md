# AWS IaaS Support for Prometheus Genesis Kit

This document provides guidance for deploying the Prometheus Genesis Kit on Amazon Web Services (AWS).

## Overview

The Prometheus Genesis Kit can be deployed on AWS infrastructure using the BOSH AWS CPI. This document covers the specific considerations, configurations, and best practices for AWS deployments.

## Prerequisites

Before deploying Prometheus on AWS, ensure you have:

1. A BOSH Director configured with the AWS CPI
2. Appropriate AWS IAM permissions
3. A VPC with at least one subnet configured for your BOSH deployment
4. Security Groups that allow necessary traffic
5. Genesis 2.7.10 or higher

## Cloud Config Requirements

Your BOSH cloud config needs specific configurations for AWS deployments:

### Networks

Configure a network for Prometheus with static IPs:

```yaml
networks:
- name: prometheus
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    az: us-east-1a
    dns: [8.8.8.8]
    reserved: [10.0.0.1-10.0.0.10]
    static: [10.0.0.20]
    cloud_properties:
      subnet: subnet-abc123 # Your AWS subnet ID
```

### VM Types

Define appropriate VM types based on your monitoring needs:

```yaml
vm_types:
- name: default
  cloud_properties:
    instance_type: t3.medium
    ephemeral_disk:
      size: 25_000
      type: gp2

- name: prometheus-large
  cloud_properties:
    instance_type: m5.large
    ephemeral_disk:
      size: 25_000
      type: gp2
```

### Disk Types

Define persistent disk types for Prometheus data storage:

```yaml
disk_types:
- name: prometheus
  disk_size: 51200  # 50GB
  cloud_properties:
    type: gp3
    iops: 3000      # Baseline performance for gp3
    throughput: 125 # Baseline throughput for gp3

- name: prometheus-large
  disk_size: 102400 # 100GB
  cloud_properties:
    type: gp3
    iops: 5000
    throughput: 250
```

## Security Group Requirements

Ensure your AWS Security Groups allow the following traffic:

### Inbound

| Type | Protocol | Port Range | Source |
|------|----------|------------|--------|
| SSH | TCP | 22 | BOSH Director Security Group |
| Custom TCP | TCP | 443 | Administrators' IP range |
| Custom TCP | TCP | 8080 | Administrators' IP range |
| Custom TCP | TCP | 8082 | Administrators' IP range |
| Custom TCP | TCP | 9090-9100 | BOSH Deployment Security Group |

### Outbound

| Type | Protocol | Port Range | Destination |
|------|----------|------------|-------------|
| All traffic | All | All | 0.0.0.0/0 |

## Deployment Parameters

Specific parameters for AWS deployments:

```yaml
---
kit:
  name: prometheus
  version: latest
  features:
    - self-signed-cert

params:
  # AWS-specific
  static_ip: 10.0.0.20  # Must match a static IP in your network
  vm_type: prometheus-large  # For larger AWS deployments
  disk_type: prometheus-large  # For larger AWS deployments
  
  # General Prometheus configuration
  prometheus_port: 443
  grafana_port: 8080
  alertmanager_port: 8082
```

## AWS-Specific Performance Considerations

### Instance Type Selection

- **Small deployments** (< 100 VMs): t3.medium
- **Medium deployments** (100-500 VMs): m5.large
- **Large deployments** (> 500 VMs): m5.xlarge or higher

### Storage Considerations

- Use gp3 volumes for better performance and cost efficiency
- For high-performance requirements, consider io2 volumes
- For large deployments, consider Amazon EFS for long-term storage

### Networking

- Place Prometheus in a private subnet with a NAT Gateway
- Use AWS PrivateLink for secure connections to AWS services
- Consider using AWS Network Load Balancer for high-availability setups

## Example Deployment

Here's a complete example for deploying Prometheus on AWS:

```yaml
---
kit:
  name: prometheus
  version: latest
  features:
    - self-signed-cert
    - monitor-cf

params:
  # AWS-specific infrastructure
  static_ip: 10.0.0.20
  vm_type: prometheus-large
  disk_type: prometheus-large
  network: monitoring-net
  
  # Prometheus configuration
  prometheus_port: 443
  grafana_port: 8080
  alertmanager_port: 8082
  external_domain: prometheus.example.com
  
  # Certificate validity periods
  ca_validity_period: 3y
  webssl_validity_period: 1y
```

## Troubleshooting AWS-Specific Issues

### Instance Not Available

If your BOSH deployment fails with "Instance not available" errors:

1. Check AWS service status in the region
2. Verify instance quota limits for your account
3. Try a different instance type or AZ

### Disk Performance Issues

If Prometheus shows poor performance on AWS:

1. Check CloudWatch metrics for the EBS volume
2. Consider upgrading to a faster EBS volume type
3. Verify that EBS volumes are properly configured with the right IOPS

### Connectivity Issues

If Prometheus cannot scrape targets:

1. Check security group rules
2. Verify network ACLs are properly configured
3. Test connectivity using AWS VPC Reachability Analyzer

## Further Reading

- [AWS BOSH CPI Documentation](https://bosh.io/docs/aws-cpi/)
- [AWS EBS Volume Types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html)
- [AWS Security Best Practices](https://aws.amazon.com/architecture/security-identity-compliance/)