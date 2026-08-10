# Prometheus Genesis Kit Troubleshooting Guide

This guide helps you diagnose and resolve common issues with Prometheus Genesis Kit deployments.

## Deployment Issues

### Failed BOSH Deployment

#### Symptoms
- BOSH deployment fails with errors
- `genesis deploy` command exits with non-zero status

#### Possible Causes and Solutions

1. **Missing Prerequisites**
   - **Cause**: Required BOSH releases or stemcells are not available
   - **Solution**: Run `genesis check-manifest` to verify the required releases, and ensure your BOSH director has access to them

2. **Network Configuration Issues**
   - **Cause**: Static IP unavailable or network misconfigured
   - **Solution**: Verify static IPs are available and correctly configured in your cloud config
   - **Verification**: `bosh cloud-config` to review current configuration

3. **Disk Sizing Issues**
   - **Cause**: Insufficient persistent disk space allocated
   - **Solution**: Increase the size of the `prometheus` disk type in your cloud config
   - **Verification**: Check cloud config and error messages for disk-related failures

4. **Stemcell Issues**
   - **Cause**: Specified stemcell not available or incompatible
   - **Solution**: Verify stemcell is uploaded to BOSH director with `bosh stemcells`
   - **Fix**: Upload required stemcell with `bosh upload-stemcell URL`

5. **Resource Exhaustion**
   - **Cause**: IaaS resource limits reached
   - **Solution**: Check your IaaS dashboard for resource quotas and limits
   - **Fix**: Increase quotas or use a smaller VM type for deployment

### Certificate Issues

#### Symptoms
- Deployment fails with certificate-related errors
- Web interfaces are inaccessible due to certificate errors

#### Possible Causes and Solutions

1. **Self-signed Certificate Generation Failure**
   - **Cause**: Issues with Vault or Genesis certificate generation
   - **Solution**: Verify that Genesis can access your Vault and has necessary permissions
   - **Fix**: Run `genesis new-secrets my-prometheus` to regenerate certificates

2. **Provided Certificate Issues**
   - **Cause**: Certificates are improperly formatted or missing from Vault
   - **Solution**: Verify certificates are correctly stored in Vault
   - **Verification**: `safe get $GENESIS_VAULT_PREFIX/nginx/ssl_certificate` should show both certificate and key

3. **Certificate Validity Period Format**
   - **Cause**: Invalid format for certificate validity periods
   - **Solution**: Ensure `ca_validity_period` and `webssl_validity_period` follow format like "3y" or "365d"

4. **External Domain Configuration**
   - **Cause**: Certificate doesn't match the external_domain parameter
   - **Solution**: Ensure the provided certificate includes the domain specified in `external_domain`

## Monitoring Issues

### Missing Metrics

#### Symptoms
- Expected metrics not appearing in Prometheus
- Dashboards showing "No Data" for certain panels

#### Possible Causes and Solutions

1. **Node Exporter Not Deployed**
   - **Cause**: Node exporter BOSH addon not applied to VMs
   - **Solution**: Generate node exporter runtime config with `genesis do my-prometheus -- runtime-config`
   - **Fix**: Apply the runtime config with `bosh update-runtime-config`

2. **Scrape Configuration Issues**
   - **Cause**: Target systems not being scraped properly
   - **Solution**: Check Prometheus configuration and scrape targets
   - **Verification**: Access the Prometheus UI at `https://<external_domain>:<prometheus_port>/targets`

3. **Network Connectivity**
   - **Cause**: Prometheus cannot reach target systems
   - **Solution**: Verify network connectivity and security group settings
   - **Verification**: SSH to Prometheus VM with `bosh ssh prometheus/0` and test connectivity

4. **Authentication Issues**
   - **Cause**: Prometheus lacks proper credentials to access targets
   - **Solution**: Verify UAA client credentials are correct
   - **Fix**: Update credentials in Genesis vault or environment file

5. **Wrong Exodus Path**
   - **Cause**: Incorrect exodus path for external systems (CF, BOSH, CredHub)
   - **Solution**: Verify exodus paths in your environment file
   - **Verification**: Check the actual exodus data paths with `genesis lookup my-cf` or similar

### Cloud Foundry Monitoring Issues

#### Symptoms
- No CF metrics in Prometheus
- Firehose exporter not working

#### Possible Causes and Solutions

1. **UAA Client Issues**
   - **Cause**: Missing or misconfigured UAA client
   - **Solution**: Verify that the CF deployment has a UAA client for Firehose
   - **Verification**: Check CF exodus data with `genesis lookup my-cf`

2. **Legacy Firehose Misconfiguration**
   - **Cause**: Using wrong API version for your CF deployment
   - **Solution**: For older CF deployments, add the `legacy-firehose` feature
   - **Verification**: Check CF deployment version and API compatibility

3. **Doppler URL or Port Incorrect**
   - **Cause**: Misconfigured Doppler connection
   - **Solution**: Verify `doppler_url` and `doppler_port` parameters
   - **Fix**: Update parameters based on CF deployment configuration

### CredHub Monitoring Issues

#### Symptoms
- No CredHub metrics in Prometheus
- CredHub exporter not working

#### Possible Causes and Solutions

1. **Wrong CredHub URL**
   - **Cause**: Incorrect CredHub API URL
   - **Solution**: Verify `credhub_exporter_api_url` parameter or exodus data
   - **Fix**: Update the URL in your environment file

2. **Authentication Issues**
   - **Cause**: Incorrect CredHub credentials
   - **Solution**: Verify UAA client has appropriate CredHub permissions
   - **Fix**: Update client credentials in your environment file or Vault

## UI Access Issues

### Cannot Access Web Interfaces

#### Symptoms
- Unable to reach Prometheus, Grafana, or AlertManager UIs
- Browser shows connection timeout or access denied

#### Possible Causes and Solutions

1. **Firewall Blocking Access**
   - **Cause**: Network firewall preventing connection to UI ports
   - **Solution**: Verify firewall rules allow access to configured ports
   - **Verification**: Try accessing from a VM within the same network

2. **Nginx Configuration Issues**
   - **Cause**: Nginx reverse proxy misconfigured
   - **Solution**: Check Nginx configuration and logs
   - **Verification**: SSH to Prometheus VM and check logs with `bosh logs prometheus/0 nginx`

3. **Port Conflicts**
   - **Cause**: Configured ports conflict with other services
   - **Solution**: Change port assignments in your environment file
   - **Verification**: Verify port accessibility with `netstat` from the Prometheus VM

4. **DNS Resolution**
   - **Cause**: DNS name not resolving to the correct IP
   - **Solution**: Verify DNS resolution or use IP address directly
   - **Verification**: Attempt to ping or traceroute to the `external_domain`

5. **Authentication Issues**
   - **Cause**: Incorrect credentials for basic auth
   - **Solution**: Verify admin password in your Vault
   - **Verification**: `safe get $GENESIS_VAULT_PREFIX/admin:password`

## Data Storage Issues

### High Disk Usage

#### Symptoms
- BOSH disk alerts for the Prometheus VM
- Prometheus reporting storage issues

#### Possible Causes and Solutions

1. **Insufficient Disk Space**
   - **Cause**: Persistent disk too small for metrics volume
   - **Solution**: Increase disk size in cloud config and redeploy
   - **Verification**: Check current usage with `bosh ssh prometheus/0 -c "df -h"`

2. **Retention Period Too Long**
   - **Cause**: Prometheus storing data for too long
   - **Solution**: Adjust retention period with a custom ops file
   - **Example**:
     ```yaml
     - type: replace
       path: /instance_groups/name=prometheus/jobs/name=prometheus/properties/prometheus/storage
       value:
         tsdb:
           retention:
             time: 7d
     ```

3. **High Cardinality Metrics**
   - **Cause**: Metrics with many unique label combinations
   - **Solution**: Review scrape configs and reduce high-cardinality labels
   - **Verification**: Check metric counts in Prometheus UI status page

### Data Loss or Gaps

#### Symptoms
- Missing data points in time series
- Graphs showing gaps or "no data" periods

#### Possible Causes and Solutions

1. **VM Restarts**
   - **Cause**: Prometheus VM restarted due to maintenance or failures
   - **Solution**: Normal for short periods, consider HA setup for critical environments
   - **Verification**: Check BOSH task logs for restarts

2. **Target Connectivity Issues**
   - **Cause**: Intermittent connectivity to monitored targets
   - **Solution**: Check network reliability and target health
   - **Verification**: Look for scrape errors in Prometheus logs

3. **Disk I/O Bottlenecks**
   - **Cause**: Slow disk I/O causing samples to be skipped
   - **Solution**: Use a faster disk type in your cloud config
   - **Verification**: Check I/O wait times in system metrics

## Genesis-Specific Issues

### Genesis Deployment Errors

#### Symptoms
- `genesis deploy` fails with errors
- Error messages about hooks or templates

#### Possible Causes and Solutions

1. **Outdated Genesis Version**
   - **Cause**: Using a Genesis version below the minimum required
   - **Solution**: Upgrade Genesis to the latest version
   - **Verification**: Check your Genesis version with `genesis -v`

2. **Kit Version Incompatibility**
   - **Cause**: Features or parameters not supported by kit version
   - **Solution**: Update kit version or adjust parameters
   - **Verification**: Check kit.yml for `genesis_version_min`

3. **Hooks Script Errors**
   - **Cause**: Errors in Genesis hooks execution
   - **Solution**: Examine hook error messages for specific issues
   - **Debug**: Run with extra verbosity: `genesis -vC deploy my-prometheus`

4. **Missing Features**
   - **Cause**: Referring to features that don't exist
   - **Solution**: Verify feature names in your environment file
   - **Verification**: Check available features in kit documentation

## Performance Issues

### Slow Query Performance

#### Symptoms
- Grafana dashboards load slowly
- Prometheus queries time out

#### Possible Causes and Solutions

1. **Undersized VM**
   - **Cause**: Insufficient CPU or memory resources
   - **Solution**: Increase the VM size in your cloud config
   - **Verification**: Check resource usage with `bosh ssh prometheus/0 -c "top"`

2. **Too Many Metrics**
   - **Cause**: Collecting excessive metrics for available resources
   - **Solution**: Reduce scrape targets or frequency
   - **Verification**: Check total metric count in Prometheus UI status page

3. **Inefficient Queries**
   - **Cause**: Dashboard queries too complex or unoptimized
   - **Solution**: Optimize queries or add recording rules
   - **Verification**: Check query timing in Prometheus UI

4. **Disk I/O Bottlenecks**
   - **Cause**: Slow persistent disk
   - **Solution**: Use SSD-based persistent disks
   - **Verification**: Check disk latency with `iostat` on the Prometheus VM

## Getting Help

If you continue to experience issues after trying the solutions in this guide:

1. Check the [Genesis Community Forums](https://github.com/genesis-community/prometheus-genesis-kit/issues)
2. Review BOSH logs with `bosh logs prometheus/0`
3. Consider opening an issue on the [Prometheus Genesis Kit GitHub repository](https://github.com/genesis-community/prometheus-genesis-kit/issues)
4. Reach out to the Genesis community on Slack or mailing lists

When requesting help, provide:
- Genesis Kit version
- BOSH Director version
- IaaS provider
- Relevant error messages
- Deployment manifest (redacted of secrets)
- Steps to reproduce the issue