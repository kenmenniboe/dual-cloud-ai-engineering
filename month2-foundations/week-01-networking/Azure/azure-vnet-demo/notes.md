# 📓 Notes — Azure Virtual Network (VNet) Deep Dive
**Date:** Sunday, May 31, 2026
**AZ-104 Topic:** Creating a Hands-On Demo Azure VNet
**Study Method:** Udemy video + interactive tutor session

---

## 1. What is a VNet?

A **Virtual Network (VNet)** is a private, isolated network inside Azure.
Think of it as **your own dedicated floor in an Azure data center** — you control who talks to what.

### Key Properties:
- Lives inside a **Resource Group**
- Tied to a specific **Azure Region**
- Has an **Address Space** (a reserved block of IPs)
- Contains one or more **Subnets**

> 💡 VNets are **region-locked** — resources in different regions cannot automatically communicate through the same VNet. Putting resources in mismatched regions causes **latency** and **connectivity issues.**

---

## 2. VNet vs Subnet Analogy

| Concept | Real-World Analogy |
|---|---|
| VNet | The entire office building 🏢 |
| Subnet | Individual offices on a floor 🚪 |
| Address Space | Total number of rooms in the building |
| IP Addresses | Individual room numbers |

**Why multiple subnets?**
Just like an office separates HR from Engineering, subnets let you **segment and regulate traffic** between different types of resources (web servers, databases, admin tools, etc.) — this is called **Network Segmentation.**

---

## 3. Address Space & CIDR Notation

When creating a VNet, Azure asks you to define an **Address Space** — a reserved block of IP addresses using **CIDR notation.**

### Example:
```
10.0.0.0/16
```

| Part | Meaning |
|---|---|
| `10.0.0.0` | Starting IP address of your network |
| `/16` | Prefix length — defines how many addresses you get |
| Total IPs | 65,536 possible addresses |

> 💡 Think of the address space like **reserving a block of apartment numbers** before anyone moves in. The larger the block, the more resources you can connect later.

### Subnet Sizing:
Each subnet carves out a slice of the address space.

| CIDR | Addresses Available |
|---|---|
| /24 | 256 |
| /16 | 65,536 |

**Rule:** Subnet ranges must **fit inside** the VNet address space and **cannot overlap** each other.

---

## 4. Subnets Created in This Demo

```
VNet Address Space: 10.0.0.0/16

├── Public-Subnet-01   → 10.0.0.0/24  (10.0.0.0   – 10.0.0.255)
├── Private-Subnet-02  → 10.0.1.0/24  (10.0.1.0   – 10.0.1.255)
├── Public-Subnet-03   → 10.0.2.0/24  (10.0.2.0   – 10.0.2.255)
└── Private-Subnet-04  → 10.0.3.0/24  (10.0.3.0   – 10.0.3.255)
```

### Public vs Private Subnets:
| Type | Purpose |
|---|---|
| **Public Subnet** | Resources reachable from the internet (e.g. web servers) |
| **Private Subnet** | Resources hidden from the internet (e.g. databases) |

---

## 5. Security Tab — Features Reviewed

> ⚠️ All features were left **OFF** for this demo — they add cost and complexity.

### 🔐 Virtual Network Encryption
Encrypts traffic **between resources inside the VNet.**
Even on a private network, Azure infrastructure staff have physical access — encryption ensures traffic can't be read even if intercepted at the hardware level.

---

### 🏰 Azure Bastion
A secure way to **connect to your VMs without a public IP.**

| Normal VM Access | With Bastion |
|---|---|
| Requires a Public IP | No Public IP needed |
| Exposed to the internet | Accessed via Azure Portal only |
| Vulnerable to brute force | Private and secured |

> Analogy: Normal access = a door facing the street. Bastion = a private entrance only accessible from inside the building. 🏰

---

### 🛡️ Azure Firewall
A managed security service that **monitors and filters traffic flowing in and out of your VNet.**

- VNet = locked front door (keeps strangers out)
- Azure Firewall = security guard (monitors what happens **inside and outside**)

Specifically it:
- Watches outbound traffic leaving your VNet
- Blocks traffic based on rules you define
- Adds a layer beyond what the VNet boundary provides alone

---

### 💧 Azure DDoS Protection
Protects against **Distributed Denial of Service (DDoS) attacks.**

**What is a DDoS attack?**
Thousands of computers flood your resource with fake requests simultaneously — so much traffic that **real users can't get through.**

> Analogy: A flash mob blocking every entrance to your building so your actual employees can't get in. 😤

**Azure DDoS Protection** detects the flood and absorbs it — keeping your real resources available.

---

## 6. Tags

**Tags** are key-value pairs attached to Azure resources for organization and cost tracking.

### Example Tags:
```
Environment : Production
Owner       : Kenneth
Project     : AZ-104-Demo
```

> Like labels on a file folder — they don't change how the resource works, but help you track and manage resources at scale.

---

## 7. Deployment Steps (Portal Walkthrough)

```
1. Go to portal.azure.com
2. Search "Virtual Networks" in the top bar
3. Click Create
4. Fill in:
   - Subscription
   - Resource Group
   - Virtual Network Name  → First-Demo-VNet
   - Region               → East US
5. Security Tab           → Leave all OFF
6. IP Addresses Tab       → Address Space: 10.0.0.0/16
                          → Create 4 Subnets (/24 each)
7. Tags Tab               → Skip for demo
8. Review + Create        → Validate → Create
```

---

## 8. Key Concepts to Remember

| Concept | One-Line Summary |
|---|---|
| VNet | Private isolated network in Azure |
| Subnet | Segmented slice of the VNet for specific resources |
| Address Space | Reserved block of IPs in CIDR notation |
| CIDR /16 | 65,536 addresses |
| CIDR /24 | 256 addresses |
| Network Segmentation | Isolating resources to regulate traffic between them |
| Azure Bastion | Secure VM access without a public IP |
| Azure Firewall | Monitors + filters VNet traffic |
| DDoS Protection | Absorbs flood attacks to keep resources available |
| Tags | Key-value labels for organization and cost tracking |