# Azure Lab: Deploy Two VMs, Bastion, and NSG

**Date:** Thu Jun 11, 2026
**Course:** AZ-104 Udemy
**Topic:** Secure VM access with Azure Bastion + NSG traffic control

---

## What I Built

| Resource | Name | Details |
|----------|------|---------|
| Resource Group | `rg-bastion-lab` | Central US |
| Virtual Network | `vnet-bastion-lab` | `10.0.0.0/16` |
| VM Subnet | `snet-vms` | `10.0.1.0/24` |
| Bastion Subnet | `AzureBastionSubnet` | `10.0.2.0/26` |
| VM-1 | `vm-1` | Windows Server 2022, no public IP |
| VM-2 | `vm-2` | Windows Server 2022, no public IP |
| Bastion | `bastion-lab` | Standard tier, native RDP enabled |
| NSG | `vm-1-nsg`, `vm-2-nsg` | Auto-created per VM |

---

## Key Results

- ✅ Connected to both VMs securely via Azure Bastion (no public IP needed)
- ✅ Confirmed VM-to-VM ping works inside the VNet
- ✅ Blocked ICMP from vm-1 to vm-2 using a custom NSG inbound rule
- ✅ Allowed ICMP from vm-2 to vm-1 using a custom NSG inbound rule
- ✅ Learned that Windows Firewall and NSGs are independent layers

---

## Key Concepts

- Azure Bastion provides secure RDP/SSH access through the browser or native client — no public IP on VMs required
- NSGs filter traffic at the NIC or subnet level using priority-based rules
- Windows Firewall is a separate layer from NSGs — both must allow traffic for it to flow
- `AzureBastionSubnet` must be named exactly and sized `/26` or larger