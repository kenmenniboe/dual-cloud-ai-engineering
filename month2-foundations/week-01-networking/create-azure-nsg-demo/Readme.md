# Azure Network Security Group (NSG)

**Date:** Tuesday, June 10, 2026
**Topic:** Creating and Configuring an Azure NSG
**Platform:** Azure Portal
**Resource Group:** First-Demo-RG

---

## What I Did

- Created an Azure NSG (`mydemo-NSG`) in East US
- Explored the 3 default inbound and outbound rules
- Added a custom inbound rule to allow RDP (port 3389)
- Associated the NSG to `Public-Subnet-01` in `First-Demo-Vnet`

## Key Outputs

| Resource | Value |
|---|---|
| NSG Name | mydemo-NSG |
| Resource Group | First-Demo-RG |
| Region | East US |
| Custom Rule | Allow-RDP (port 3389, priority 100) |
| Associated Subnet | Public-Subnet-01 (10.0.0.0/24) |

## Key Takeaway

NSG rules are evaluated **lowest priority number first**. Custom rules (100–4096) always run before the default DenyAll rule (65500).

---

## Next Session

Deploy two VMs + Azure Bastion for secure connectivity (requires `AzureBastionSubnet` in VNet).