# AZ-104 Lab: Azure VNet Peering & Hub-Spoke Topology

## What I Learned
- How Azure VNet Peering works (private connectivity over Microsoft's backbone)
- Network topology patterns: Mesh, Hub & Spoke, and Hybrid (Hub & Spoke with direct spoke links)
- How Hub-based Gateways (VPN/ExpressRoute) extend connectivity to on-premises networks
- Prerequisites for peering (non-overlapping IP address spaces)
- How to configure bidirectional peering settings in the Azure Portal
- How to validate peering connectivity end-to-end using test VMs

## What I Built
- 2x VNets: `vnet-hub` (10.0.0.0/16) and `vnet-spoke` (10.1.0.0/16), same region
- Bidirectional VNet Peering between them
- 1x test VM in each VNet (`vm-hub`, `vm-spoke`), same SSH key pair (`adminuser`)
- SSH'd into `vm-hub` and pinged `vm-spoke`'s private IP to confirm peering works

## Key Result
```
ping -c 4 10.1.0.4
4 packets transmitted, 4 received, 0% packet loss
rtt min/avg/max/mdev = 4.095/6.678/10.789/2.499 ms
```
✅ Peering confirmed working — private IP connectivity across both VNets with zero packet loss.

