# OCFP Feature and Stackit IaaS Support

This document provides detailed information about the Open Container Framework Platform (OCFP) feature and Stackit IaaS support in the Prometheus Genesis Kit.

## What is OCFP?

The Open Container Framework Platform (OCFP) feature is designed to standardize deployments across multiple IaaS providers, with a focus on OpenStack-compatible infrastructures like OpenStack itself and Stackit. This feature adapts deployment configurations to work seamlessly with these platforms, handling their specific requirements and capabilities.

## What is Stackit?

Stackit is an IaaS provider that offers cloud infrastructure services compatible with OpenStack APIs. It provides a 1:1 correspondence between networks and subnets, unlike traditional OpenStack which can have multiple subnets within a single network.

## OCFP Feature Overview

When you enable the `ocfp` feature, the Prometheus Genesis Kit:

1. Includes specific configuration files from the `ocfp/` directory
2. Adjusts network, VM, and disk configurations for compatibility with OpenStack/Stackit
3. Handles IaaS-specific property mappings through the cloud config layer
4. Provides a standardized approach for both OpenStack and Stackit deployments

## Enabling OCFP and Stackit Support

To use the Prometheus Genesis Kit with Stackit:

1. Include the `ocfp` feature in your environment file:

```yaml
kit:
  name: prometheus
  version: latest
  features:
    - ocfp
    - self-signed-cert  # or other desired features
```

2. Configure your environment with Stackit as the CPI in your Genesis deployment:

```yaml
# Example infrastructure-specific parameters
params:
  ocfp_env_scale: dev  # or prod, affects VM and disk sizing
  ocfp_vault_config_slug: my-stackit-env  # Optional vault configuration reference
```

## Technical Implementation

### Cloud Config Integration

The `cloud-config.pm` hook has been enhanced to support Stackit-specific properties:

1. **Networks**: Handles Stackit's 1:1 network-to-subnet mapping
2. **VM Types**: Maps to appropriate Stackit instance types
3. **Disk Types**: Configures appropriate Stackit storage types

Example cloud config definition generated for Stackit:

```yaml
networks:
- name: prometheus
  type: manual
  subnets:
  - range: 10.0.0.0/24
    gateway: 10.0.0.1
    static: [10.0.0.20]
    cloud_properties:
      net_id: net-abc123  # Stackit network ID
      security_groups: [default]
```

### VM and Disk Types

The OCFP feature scales VM and disk resources based on the environment scale:

**VM Types**:
- Development scale: `m1.2` instance type
- Production scale: `m1.3` instance type

**Disk Types**:
- Development scale: 128GB storage
- Production scale: 256GB storage

Both use the `storage_premium_perf6` storage type for optimal performance.

### Blueprint Generation

The `blueprint.pm` hook conditionally includes the appropriate YAML files based on the detected IaaS provider:

1. Base OCFP files: `ocfp/meta.yml` and `ocfp/ocfp.yml` are always included
2. IaaS-specific files: Conditional logic detects Stackit and can include `ocfp/stackit.yml` if needed

### Example Stackit Deployment Configuration

```yaml
---
kit:
  name: prometheus
  version: latest
  features:
    - ocfp
    - self-signed-cert
    - monitor-cf

params:
  # Stackit-specific
  ocfp_env_scale: prod
  
  # Genesis environment name will be used for BOSH and CF exodus path defaults
  
  # Standard Prometheus params
  external_domain: prometheus.example.com
  prometheus_port: 443
  grafana_port: 8080
  alertmanager_port: 8082
```

## Network Configuration Differences

The primary difference between OpenStack and Stackit is in network configuration:

1. **OpenStack**: Can have multiple subnets within a single network
2. **Stackit**: Has a 1:1 relationship between networks and subnets

The OCFP feature handles these differences transparently, ensuring your Prometheus deployment works correctly regardless of which platform you choose.

## Resource Scaling

The OCFP feature includes built-in scaling based on the `ocfp_env_scale` parameter:

| Scale | VM Type | Disk Size | Use Case |
|-------|---------|-----------|----------|
| dev   | m1.2    | 128GB     | Development/testing environments |
| prod  | m1.3    | 256GB     | Production environments with higher resource needs |

## Stackit-Specific Customizations

Currently, Stackit deployments use the same configuration as OpenStack deployments, with differences abstracted by the cloud config layer. If you need to customize Stackit deployments specifically:

1. Edit the `ocfp/stackit.yml` file to add Stackit-specific overrides
2. Modify `blueprint.pm` to uncomment the inclusion of the Stackit-specific file

## Limitations and Future Enhancements

### Current Limitations

1. Stackit implementation currently mirrors OpenStack exactly
2. Limited testing in large-scale Stackit environments
3. No Stackit-specific dashboard or visualization optimizations

### Planned Enhancements

1. Enhanced Stackit-specific cloud property mapping
2. Improved support for Stackit's unique network architecture
3. Pre-configured dashboards for Stackit-specific metrics (if applicable)

## Troubleshooting Stackit Deployments

### Common Issues

#### Network Connectivity Issues

**Symptoms**:
- Deployment fails with network-related errors
- Unable to reach Prometheus component UIs

**Solutions**:
1. Verify Stackit network configuration in your cloud config
2. Check security group rules allow necessary traffic
3. Ensure static IP allocation doesn't conflict with existing IPs

#### Resource Allocation Failures

**Symptoms**:
- Deployment fails with resource allocation errors
- VMs cannot be created

**Solutions**:
1. Verify resource quotas in your Stackit account
2. Try smaller instance types by setting `ocfp_env_scale: dev`
3. Check that requested instance types are available in your Stackit environment

#### API Compatibility Issues

**Symptoms**:
- Unexpected errors during deployment
- BOSH CPI reports API errors

**Solutions**:
1. Ensure BOSH director uses latest compatible CPI for Stackit
2. Verify authentication and API endpoints are correctly configured
3. Check Stackit documentation for API version compatibility

## Example: Full Stackit Deployment

```yaml
---
kit:
  name: prometheus
  version: latest
  features:
    - ocfp
    - self-signed-cert
    - monitor-cf
    - monitor-credhub

params:
  # OCFP Configuration
  ocfp_env_scale: prod
  
  # Component access
  external_domain: prometheus.stackit.example.com
  prometheus_port: 443
  grafana_port: 8080
  alertmanager_port: 8082
  
  # Certificate configuration 
  ca_validity_period: 3y
  webssl_validity_period: 1y
  
  # Cloud Foundry monitoring
  cf_env: prod-cf
  skip_ssl_validation: false
  
  # CredHub monitoring
  credhub_exodus_path: prod/bosh
```

## References

- [Stackit Documentation](https://docs.stackit.cloud/)
- [OpenStack API Documentation](https://docs.openstack.org/api/)
- [BOSH OpenStack CPI](https://bosh.io/docs/openstack-cpi/)

## Conclusion

The OCFP feature and Stackit IaaS support in the Prometheus Genesis Kit provide a standardized approach to deploying Prometheus across OpenStack-compatible platforms. By abstracting infrastructure differences at the cloud config layer, the kit ensures consistent deployments regardless of the underlying IaaS provider, while also providing flexibility for environment-specific customizations.