# Azure Public IP + NAT Gateway (AZ-104)

## What this covers
End-to-end tutoring + hands-on lab on Azure Public IP addresses and NAT Gateway, self-designed (no course transcript for this section):

- Public IP fundamentals — what it is, NIC association
- Basic vs. Standard SKU (incl. the Basic SKU retirement, Sept 30, 2025)
- Static vs. Dynamic allocation
- Availability Zones for Public IPs (zonal / zone-redundant / no-zone)
- Public IP Prefix (footnote)
- NAT Gateway concept and SNAT behavior
- **Correction mid-session:** NAT Gateway has two SKUs — Standard (v1, zonal only) and StandardV2 (zone-redundant by default, requires StandardV2 Public IPs). This lab used **Standard v1**.
- Full hands-on lab: VNet + Bastion + jumpbox (no public IP) → Standard zone-redundant Public IP → Standard NAT Gateway → verified outbound-only SNAT connectivity → negative test (detach = no outbound) → reattach and re-verify

## Key outputs / results
- Public IP provisioned: `pip-natgw-lab` → **20.15.150.94** (Standard SKU, Static, Zone-redundant)
- NAT Gateway: `natgw-lab` (Standard v1, No Zone)
- Verified `vm-jumpbox` (no Public IP on its NIC) reached the internet outbound-only through the NAT Gateway:
  - `curl ifconfig.me` → `20.15.150.94` (matches the NAT Gateway's Public IP, confirming SNAT)
  - `sudo apt update` succeeded (36.4 MB fetched)
- Negative test confirmed causation: detached NAT Gateway from `snet-workload` → `curl ifconfig.me` timed out (no outbound path at all) → reattached → connectivity restored, confirmed `20.15.150.94` again

## Environment
- Resource group: `rg-natgw-lab`
- VNet: `vnet-natgw-lab` (`10.10.0.0/16`), subnet `snet-workload` (`10.10.1.0/24`), `AzureBastionSubnet` (`10.10.2.0/26`)
- Bastion: `bastion-natgw-lab` (Standard tier)
- Jumpbox: `vm-jumpbox` (Ubuntu 24.04, no Public IP)

See `notes.md` for the full tutorial and redo guide, and `commands.md` for every command used.