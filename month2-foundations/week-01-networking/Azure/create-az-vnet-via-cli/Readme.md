# Azure VNet — Created via Azure CLI (AZ-104)

**Date:** June 2, 2026
**Topic:** Hands-on Demo — Creating an Azure VNet using Azure CLI
**Course:** AZ-104 (Udemy)
**Tool:** Azure Cloud Shell (Bash) in VS Code

---

## What I Built

A Resource Group with a Virtual Network and two subnets, created entirely from the Azure CLI.

```
my-firstVSC-RG
└── my-firstVSC-VNet (10.0.0.0/16)
    ├── mySubnet1 (10.0.1.0/24)
    └── mySubnet2 (10.0.2.0/24)
```

---

## Key Outputs

**Resource Group created:**
```
"provisioningState": "Succeeded"
"location": "eastus"
"name": "my-firstVSC-RG"
```

**VNet created:**
```
"provisioningState": "Succeeded"
"addressPrefixes": ["10.0.0.0/16"]
"name": "my-firstVSC-VNet"
```

**Subnets verified:**
```
SubnetName    AddressPrefix
----------    -------------
mySubnet1     10.0.1.0/24
mySubnet2     10.0.2.0/24
```

---

## Commands Used

| Action | Command |
|--------|---------|
| Create Resource Group | `az group create` |
| Create VNet | `az network vnet create` |
| Create Subnet | `az network vnet subnet create` |
| Verify VNet | `az network vnet show --output table` |
| List Subnets | `az network vnet subnet list --output table` |
| Delete Resource Group | `az group delete` |

---

## What I Learned

- Azure CLI follows a consistent pattern: `az [resource] [action] [--flags]`
- Everything in Azure must live inside a Resource Group
- VNets use CIDR notation to define the total IP address space
- Subnets must be carved from within the VNet's address range
- CLI is preferred over the portal for reusable, repeatable infrastructure (IaC)
- Short flags like `-g`, `-n`, `-l` are shorthand for `--resource-group`, `--name`, `--location`
- `--query` with JMESPath filters JSON output to only what you need