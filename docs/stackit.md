# Stackit IaaS Support for Prometheus Genesis Kit

This document describes the support for the Stackit IaaS provider in the Prometheus Genesis Kit.

## Overview

The Prometheus Genesis Kit now supports Stackit as an IaaS provider, with functionality mirroring that of the OpenStack provider. This allows for seamless deployment of Prometheus on Stackit infrastructure.

## Implementation Details

Stackit support has been implemented in the following areas:

1. **Cloud Config Generation**: The `cloud-config.pm` hook has been extended to support Stackit-specific cloud properties for networks, VM types, and disk types.

2. **Blueprint Generation**: The `blueprint.pm` hook has been enhanced to handle Stackit as a valid IaaS provider for the OCFP feature.

3. **Stackit-Specific Configuration**: A placeholder `stackit.yml` file has been added to the `ocfp` directory to accommodate any future Stackit-specific customizations.

## Network Configuration

The primary difference between Stackit and OpenStack is the 1:1 correspondence of networks to subnets in Stackit, compared to the possibility of a single overarching network in OpenStack. The current implementation handles this difference at the cloud config level, with no special handling required in the hooks themselves.

## Usage

To deploy Prometheus using the Stackit IaaS provider:

1. Ensure your Genesis environment is configured with Stackit as the CPI.
2. Use the same parameters and features as you would with an OpenStack deployment.
3. Deploy as normal with the Genesis command-line tools.

## Limitations

Currently, the Stackit implementation exactly mirrors the OpenStack implementation, as the differences between the two IaaS providers are abstracted away by the cloud config layer.

## Future Enhancements

If Stackit-specific customizations are needed in the future, the `stackit.yml` file in the `ocfp` directory can be modified and included in the blueprint files through the conditional logic already added to `blueprint.pm`.
