# Notes — Azure VNet via Azure CLI (AZ-104)

**Date:** June 2, 2026
**Topic:** Hands-on Demo — Creating an Azure VNet using Azure CLI
**Tool:** Azure Cloud Shell (Bash) in VS Code

---

## 1. Why Use Azure CLI Instead of the Portal?

Using the CLI means your infrastructure is **reusable and repeatable** — write it once, run it anywhere.
This concept is called **Infrastructure as Code (IaC)**.

Instead of clicking through the portal every time, you save commands in a script and run them across dev, test, and production environments identically.

Azure CLI is a lightweight entry point into IaC before moving to more advanced tools like Bicep or Terraform.

---

## 2. Azure CLI Command Pattern

Every Azure CLI command follows this same structure:

```
az [resource-type] [action] [--flags]
```

Examples:
```
az group create       → Create a resource group
az network vnet create → Create a virtual network
az network vnet subnet list → List subnets in a VNet
```

This pattern repeats for everything in Azure CLI. Learn it once, apply it everywhere.

---

## 3. Short Flag vs Long Flag

Azure CLI supports shorthand flags for commonly used options:

| Long Flag | Short Flag |
|-----------|------------|
| `--resource-group` | `-g` |
| `--name` | `-n` |
| `--location` | `-l` |

Both are identical — professionals use short flags to type faster.

---

## 4. Azure Resource Hierarchy

Every resource in Azure lives in a hierarchy:

```
Subscription
└── Resource Group
    └── Resource (VNet, VM, Storage, etc.)
```

The full resource ID always reflects this path:
```
/subscriptions/{id}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}
```

This matters for billing, access control, and organization.

---

## 5. Step 1 — Create a Resource Group

A Resource Group is a container for related Azure resources. Everything must live in one.

**Command:**
```bash
az group create --name my-firstVSC-RG --location eastus
```

**Output:**
```json
{
  "id": "/subscriptions/16b685b8-1e93-416f-8acc-080d39023a35/resourceGroups/my-firstVSC-RG",
  "location": "eastus",
  "name": "my-firstVSC-RG",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "type": "Microsoft.Resources/resourceGroups"
}
```

✅ Key indicator: `"provisioningState": "Succeeded"`

---

## 6. CIDR Notation and VNet Sizing

Azure VNets use CIDR notation to define the total IP address space.

| CIDR | Available IPs | Analogy |
|------|--------------|---------|
| /16  | 65,536       | A whole city |
| /24  | 256          | A neighborhood |
| /28  | 16           | A single street |

The smaller the number after `/`, the **larger** the network.

`10.0.0.0/16` = the entire VNet pool before any subnetting.
Subnets are carved out of this space.

---

## 7. Step 2 — Create a VNet

**Command:**
```bash
az network vnet create \
  --name my-firstVSC-VNet \
  --resource-group my-firstVSC-RG \
  --location eastus \
  --address-prefix 10.0.0.0/16
```

**Output (key fields):**
```json
{
  "newVNet": {
    "addressSpace": {
      "addressPrefixes": ["10.0.0.0/16"]
    },
    "provisioningState": "Succeeded",
    "subnets": [],
    "name": "my-firstVSC-VNet"
  }
}
```

✅ Notice `"subnets": []` — VNet exists but no subnets yet.

---

## 8. Step 3 — Create Subnets

Subnets must use an address range that falls **inside** the VNet's address space.

- VNet: `10.0.0.0/16`
- Valid subnet: `10.0.1.0/24` ✅
- Invalid subnet: `192.168.1.0/24` ❌ (different network entirely)

**Command (run once per subnet):**
```bash
az network vnet subnet create \
  --name mySubnet1 \
  --vnet-name my-firstVSC-VNet \
  --resource-group my-firstVSC-RG \
  --address-prefix 10.0.1.0/24

az network vnet subnet create \
  --name mySubnet2 \
  --vnet-name my-firstVSC-VNet \
  --resource-group my-firstVSC-RG \
  --address-prefix 10.0.2.0/24
```

**Alternative (Udemy instructor style — both subnets in one command):**
```bash
az network vnet subnet create \
  -g my-firstVSC-RG \
  --vnet-name my-firstVSC-VNet \
  -n mySubnet \
  --address-prefixes ["10.0.1.0/24" "10.0.2.0/24"]
```

Note: `--address-prefixes` (plural) accepts a list `[]`. `--address-prefix` (singular) takes one value only.

**Output (Subnet 1):**
```json
{
  "addressPrefix": "10.0.1.0/24",
  "name": "mySubnet1",
  "provisioningState": "Succeeded",
  "resourceGroup": "my-firstVSC-RG"
}
```

---

## 9. Step 4 — Verify VNet

**Command:**
```bash
az network vnet show \
  --name my-firstVSC-VNet \
  --resource-group my-firstVSC-RG \
  --output table
```

**Output:**
```
EnableDdosProtection    Location    Name              ProvisioningState    ResourceGroup
----------------------  ----------  ----------------  -------------------  ---------------
False                   eastus      my-firstVSC-VNet  Succeeded            my-firstVSC-RG
```

---

## 10. Step 5 — Verify Subnets

**Command:**
```bash
az network vnet subnet list \
  --vnet-name my-firstVSC-VNet \
  --resource-group my-firstVSC-RG \
  --output table
```

**Output:**
```
AddressPrefix    Name       ProvisioningState    ResourceGroup
---------------  ---------  -------------------  ---------------
10.0.1.0/24      mySubnet1  Succeeded            my-firstVSC-RG
10.0.2.0/24      mySubnet2  Succeeded            my-firstVSC-RG
```

---

## 11. Filtering Output with --query (JMESPath)

The `--query` flag uses **JMESPath** syntax to filter and rename JSON output fields.

**Command:**
```bash
az network vnet subnet list \
  -g my-firstVSC-RG \
  --vnet-name my-firstVSC-VNet \
  --query "[].{SubnetName:name, AddressPrefix:addressPrefix}" \
  --output table
```

**Breaking it down:**
```
[]                          → all items in the list
.{SubnetName:name}          → rename field "name" → "SubnetName"
.{AddressPrefix:addressPrefix} → rename field "addressPrefix" → "AddressPrefix"
```

**Output:**
```
SubnetName    AddressPrefix
------------  ---------------
mySubnet1     10.0.1.0/24
mySubnet2     10.0.2.0/24
```

Much cleaner than raw JSON or full table output.

---

## 12. Step 6 — Delete Resource Group

When cleaning up, deleting the Resource Group removes **everything inside it**.

**Command:**
```bash
az group delete --name my-firstVSC-RG --yes --no-wait
```

**Flag breakdown:**
| Flag | Meaning |
|------|---------|
| `--yes` | Skip the "are you sure?" confirmation prompt |
| `--no-wait` | Return terminal control immediately; deletion runs in the background |

Note: `--no-wait` doesn't make deletion faster — it just frees your terminal while Azure works behind the scenes.

---

## Summary — Full Infrastructure Built

```
my-firstVSC-RG
└── my-firstVSC-VNet (10.0.0.0/16)
    ├── mySubnet1 (10.0.1.0/24)
    └── mySubnet2 (10.0.2.0/24)
```

Built entirely from Azure Cloud Shell in VS Code using Azure CLI. No portal clicks required.