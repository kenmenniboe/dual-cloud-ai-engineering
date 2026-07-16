# Azure NSG — Detailed Notes

**Date:** Tuesday, June 10, 2026
**Lab Type:** Azure Portal (hands-on)
**Course:** AZ-104 (Udemy)

---

## What Is an NSG?

An **NSG (Network Security Group)** is Azure's built-in firewall ruleset. It filters traffic **inbound and outbound** using priority-based rules.

**Analogy:** Think of it like a bouncer at a club — it checks every packet against a list before letting it in or out.

### Where Can You Attach an NSG?

| Target | Scope |
|---|---|
| Subnet | Protects ALL resources inside the subnet |
| NIC | Protects one specific VM only |

---

## How Priority Works

- Rules are evaluated **lowest number first**
- Range: **100 – 65535**
- Lower number = higher priority = evaluated first
- You **cannot delete** default rules, but you can override them with a lower priority number

---

## Default Rules (Auto-Created by Azure)

### Inbound

| Priority | Name | Port | Protocol | Source | Destination | Action |
|---|---|---|---|---|---|---|
| 65000 | AllowVnetInBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowAzureLoadBalancerInBound | Any | Any | AzureLoadBalancer | Any | Allow |
| 65500 | DenyAllInBound | Any | Any | Any | Any | Deny |

### Outbound

| Priority | Name | Port | Protocol | Source | Destination | Action |
|---|---|---|---|---|---|---|
| 65000 | AllowVnetOutBound | Any | Any | VirtualNetwork | VirtualNetwork | Allow |
| 65001 | AllowInternetOutBound | Any | Any | Any | Internet | Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | Any | Deny |

---

## Step-by-Step: Create an NSG (Portal)

### 1. Navigate to NSG
- Search **"Network Security Groups"** in the top bar
- Click the result under **Services**

### 2. Create NSG
- Click **"+ Create"**
- Fill in:
  - Subscription
  - Resource Group
  - Name (e.g. `mydemo-NSG`)
  - Region (match your other resources)
- Click **Review + Create → Create**

`[SCREENSHOT: NSG creation form]`

### 3. View Default Rules
- Open the NSG → click **"Inbound security rules"**
- You'll see the 3 default rules at priorities 65000, 65001, 65500

`[SCREENSHOT: Default inbound rules list]`

---

## Step-by-Step: Add a Custom Inbound Rule

1. Click **"+ Add"** on the Inbound security rules page
2. Fill in the panel:

| Field | Value |
|---|---|
| Source | Any |
| Source port ranges | * |
| Destination | Any |
| Service | RDP |
| Action | Allow |
| Priority | 100 |
| Name | Allow-RDP |

3. Click **"Add"**

`[SCREENSHOT: Custom rule panel filled in]`

### ⚠️ Warning You'll See

> "RDP port 3389 is exposed to the Internet. This is only recommended for testing."

This is **expected** — it's a warning, not an error. In production, use **Azure Bastion** or a **VPN Gateway** instead of exposing port 3389.

---

## Step-by-Step: Associate NSG to a Subnet

1. In the NSG left panel → click **"Subnets"**
2. Click **"+ Associate"**
3. Select:
   - Virtual network: `First-Demo-Vnet`
   - Subnet: `Public-Subnet-01`
4. Click **"OK"**

`[SCREENSHOT: Subnet association panel]`

**Result:** All resources inside `Public-Subnet-01` are now governed by `mydemo-NSG` rules.

---

## Production Best Practices

| Scenario | Recommendation |
|---|---|
| Remote VM access | Use Azure Bastion (not open RDP) |
| Bastion deployment | Requires dedicated `AzureBastionSubnet` in your VNet |
| NSG rule design | Start with Deny All, allow only what's needed |

---

## Coming Up Next

- Deploy 2 VMs
- Deploy Azure Bastion
- Create `AzureBastionSubnet` in `First-Demo-Vnet`