# Azure Virtual Network Service Endpoint — Notes & Redo Guide

## Table of Contents
- [1. Overview](#1-overview)
- [2. Concepts](#2-concepts)
  - [2.1 How Service Endpoint Routing Works](#21-how-service-endpoint-routing-works)
  - [2.2 Service Endpoint vs. Private Endpoint — Design Tradeoffs](#22-service-endpoint-vs-private-endpoint--design-tradeoffs)
  - [2.3 Service Endpoint Policies](#23-service-endpoint-policies)
  - [2.4 Private Subnets & Default Outbound Access (2026 platform change)](#24-private-subnets--default-outbound-access-2026-platform-change)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Hands-On Lab (Redo Guide)](#4-hands-on-lab-redo-guide)
  - [4.1 Prerequisite Infrastructure](#41-prerequisite-infrastructure)
  - [4.2 Storage Account Creation — Full Tab Breakdown](#42-storage-account-creation--full-tab-breakdown)
  - [4.3 Enable the Service Endpoint on the Subnet](#43-enable-the-service-endpoint-on-the-subnet)
  - [4.4 Lock the Storage Account to the Subnet](#44-lock-the-storage-account-to-the-subnet)
  - [4.5 Upload a Blob & Generate a SAS URL](#45-upload-a-blob--generate-a-sas-url)
  - [4.6 Verify Access & Run the Negative Test](#46-verify-access--run-the-negative-test)
- [5. Errors & Fixes](#5-errors--fixes)
- [6. Acronyms](#6-acronyms)

---

## 1. Overview

**Service Endpoint** provides private-style access to Azure PaaS services from a VNet, but unlike Private Endpoint, the target resource **keeps its public IP** — what changes is the *routing path* (Azure backbone instead of public internet) and the *trust model* (VNet/subnet identity instead of just IP address).

---

## 2. Concepts

### 2.1 How Service Endpoint Routing Works

Enabling a Service Endpoint (e.g. `Microsoft.Storage`) **on a subnet** does two things:
1. Traffic from that subnet to the service takes an **optimized route over the Azure backbone** — never touching the public internet, even though the destination is still addressed by its public IP.
2. The service can now see the traffic's **VNet identity** (tenant ID, subscription, resource group, VNet name, subnet name) — enabling firewall rules based on "trust this subnet," not just IP whitelisting.

**No NAT needed:** the VM's own private IP is preserved as the source address — nothing is translated, and no NIC or private IP is ever created for the target resource. This is the key structural difference from Private Endpoint (which does create a NIC, in your own VNet).

> [!TIP]
> **AWS anchor:** This is Azure's version of an **AWS Gateway VPC Endpoint** (the type used for S3/DynamoDB) — route-table-based, no ENI, no IP change on the target. Private Endpoint, by contrast, maps to an **Interface VPC Endpoint**.

**Configuration is always 2 steps:**
1. Subnet: enable the service endpoint for the relevant service type (a subnet can have multiple)
2. Resource: restrict the resource's networking to accept only from that VNet/subnet

**Direction:** outbound only — Service Endpoint (like Private Endpoint) secures traffic *leaving* your VNet toward the service; it has no effect on inbound traffic to your VMs.

**Supported services:** Storage, App Service, SQL Database, Container Registry, Key Vault, Service Bus, and more.

### 2.2 Service Endpoint vs. Private Endpoint — Design Tradeoffs

| | Service Endpoint | Private Endpoint |
|---|---|---|
| Pricing | **Free** | Costs based on inbound/outbound traffic |
| Data exfiltration protection | None — traffic still rides the public IP path | Yes — traffic never touches a public IP |
| On-premises access (VPN/ExpressRoute) | Not supported | Supported |
| Regional scope | Regional-specific (some services offer global reach) | Regional-agnostic |
| New resource created? | No — just a subnet property | Yes — NIC + private IP in your VNet |
| Microsoft's direction | No further investment planned | Actively developed — Microsoft's recommended path |

> [!IMPORTANT]
> Microsoft's own documentation explicitly recommends **Private Link/Private Endpoint over Service Endpoint** for secure PaaS access. Service Endpoint remains relevant because it's free and simpler — not because it's the strategic direction.

### 2.3 Service Endpoint Policies

A second, optional layer **on top of** a plain Service Endpoint: restricts *which specific resource instances* (e.g. specific storage accounts) a subnet can reach — closing the gap where a compromised VM could otherwise reach *any* storage account (even one in a different subscription/attacker-controlled) that happens to trust your VNet.

> [!NOTE]
> Service Endpoint Policies currently only support **Azure Storage** as the target service. Not used in this lab (we weren't demonstrating exfiltration risk), but worth knowing for the exam.

### 2.4 Private Subnets & Default Outbound Access (2026 platform change)

As of **March 31, 2026**, new Azure VNets/subnets default to **"private subnet"** — no default outbound internet access. Normally this means VMs need an explicit outbound method (NAT Gateway, Load Balancer outbound rules, Azure Firewall/NVA) to reach anything on the internet.

> [!IMPORTANT]
> **This restriction does NOT apply to Service Endpoints.** They use a distinct next-hop type (`VirtualNetworkServiceEndpoint`) that bypasses the private-subnet limitation entirely. Confirmed working in this lab with **no NAT Gateway** attached to `snet-app`.

---

## 3. Architecture Diagram

![Service Endpoint Architecture](images/architecture-diagram.svg)

Public path (external client, unwhitelisted IP → Storage Account) is blocked (`AuthorizationFailure`). Private path (jumpbox → Service Endpoint route → Storage Account) works via VNet/subnet identity — same public IP the whole time, no NIC involved.

---

## 4. Hands-On Lab (Redo Guide)

### 4.1 Prerequisite Infrastructure

**Resource Group:** `rg-service-endpoint-lab`

**VNet:** `vnet-se-lab`
- Address space: `10.1.0.0/16`
- Subnet `snet-app` → `10.1.1.0/24`
- Subnet `AzureBastionSubnet` → `10.1.2.0/24` (exact name required)

**Bastion:** `bastion-se-lab`, Basic SKU, attached to `AzureBastionSubnet`

**Jumpbox VM:** **Ubuntu** (not Windows this time — `curl` is built in, and the jumpbox has no outbound internet access for installers anyway), e.g. `vm-jumpbox-se`, deployed into `snet-app`, **no public IP**, **NIC-level NSG: None** (no inbound path exists regardless; Bastion is the only entry point)

[SCREENSHOT: VNet subnets overview]
[SCREENSHOT: Ubuntu jumpbox creation — no public IP confirmed]

### 4.2 Storage Account Creation — Full Tab Breakdown

**Basics:**
| Field | Value |
|---|---|
| Resource group | `rg-service-endpoint-lab` |
| Storage account name | globally unique, lowercase+numbers, e.g. `stsepablab1234` |
| Region | same as VNet |
| Performance | Standard |
| Redundancy | Locally-redundant storage (LRS) |

**Advanced:**
| Field | Value |
|---|---|
| Require secure transfer | Enabled (default) |
| Allow anonymous access on containers | Enabled (default — container itself still set Private) |
| Enable storage account key access | Enabled (default) |
| Minimum TLS version | TLS 1.2 |
| Hierarchical namespace (Data Lake Gen2) | Disabled |
| Enable SFTP | Disabled (requires hierarchical namespace anyway) |
| Enable NFS v3 | Disabled (same dependency) |
| Allow cross-tenant replication | Disabled |
| Access tier | Hot |

**Networking:**
| Field | Value |
|---|---|
| Public network access | "Allow inbound and outbound access with the option to restrict select inbound access using resource access configurations" (modern equivalent of old "Enabled") |
| Public network access scope | **All networks** (deliberate "before" state — locked down in 4.4) |
| Private endpoint | Skip — not used this lab |
| Network routing | Microsoft network routing (default) |

**Data protection:**
| Field | Value |
|---|---|
| Point-in-time restore | Disabled |
| Soft delete for blobs | Enabled, 7-day default |
| Soft delete for containers | Enabled, default |
| Soft delete for classic file shares | Disabled |
| Versioning | Disabled |
| Blob change feed | Disabled |
| Version-level immutability | Disabled |

**Security:**
| Field | Value |
|---|---|
| Require secure transfer for REST API | Enabled |
| Allow anonymous access on containers | Enabled |
| Enable storage account key access | Enabled (needed for SAS token generation) |
| Default to Entra authorization in Portal | Enabled |
| Minimum TLS version | TLS 1.2 |
| Permitted scope for copy operations | Default ("From any storage account") |
| Enable Defender for Storage | **Off** (paid add-on, unnecessary for a lab) |

**Encryption:**
| Field | Value |
|---|---|
| Encryption type | Microsoft-managed keys |
| Customer-managed keys | Off |
| Infrastructure encryption | Off |

**Review + create** → **Create**.

**Then create the container:**
- Containers → **+ Container** → name `content` → Public access level: **Private (no anonymous access)**

> [!WARNING]
> Easy to skip — creating the `content` container is a separate step *after* the storage account deploys, not part of the creation wizard. Confirm it exists before moving on (a stray `$logs` container that Azure auto-creates for Storage Analytics logging is not the same thing — ignore it).

[SCREENSHOT: Storage account Networking tab at creation]
[SCREENSHOT: content container created, Private access level]

### 4.3 Enable the Service Endpoint on the Subnet

**VNet → Subnets → `snet-app` → edit:**

| Field | Value | Why |
|---|---|---|
| Subnet purpose | Leave blank | No special delegation needed |
| Enable private subnet (no default outbound access) | **Leave checked** | Doesn't block Service Endpoint traffic (see [2.4](#24-private-subnets--default-outbound-access-2026-platform-change)) — more secure default, no NAT Gateway required |
| NAT gateway | None | Not needed |
| Network security group | None | No inbound path exists anyway |
| Route table | None | Service endpoints route themselves automatically |
| **Service Endpoints** | **Add → `Microsoft.Storage`** | **This is the entire first half of the feature** |
| Subnet Delegation | None | Not needed |
| Private endpoint network policy | Default | Not relevant — no Private Endpoint in this subnet this round |
| Service endpoint policies | Leave empty | Not used this lab (see [2.3](#23-service-endpoint-policies)) |

**Save.**

[SCREENSHOT: Subnet edit blade with Microsoft.Storage service endpoint added]

### 4.4 Lock the Storage Account to the Subnet

1. Storage Account → **Networking**
2. **Public network access scope** → change to **"Selected networks"**
3. Under **Resource settings: Virtual networks, IP addresses, and exceptions** → **View**
4. **Virtual networks** → **Add existing virtual network** → select `vnet-se-lab` / `snet-app` → **Add**
5. Also add your own **client IPv4 address** under the Firewall/IP rules section (needed to test the SAS URL from your local machine)
6. **Save**

Result: any request from outside `snet-app` (or your whitelisted IP) now gets **403 / AuthorizationFailure**.

[SCREENSHOT: Networking — Selected networks with subnet + IP rule added]

### 4.5 Upload a Blob & Generate a SAS URL

1. **Access Control (IAM)** → **+ Add role assignment** → **Storage Blob Data Contributor** → assign to your own account
2. **Containers → `content` → Upload** → any small `.txt` file (e.g. containing "Hello world")
3. Click the uploaded file → **Generate SAS**
   - Permissions: **Read**
   - Allowed protocols: **HTTPS only**
   - Defaults fine for start/expiry (short-lived lab test)
4. Copy the **Blob SAS URL**

[SCREENSHOT: Generate SAS panel with Read permission selected]

### 4.6 Verify Access & Run the Negative Test

**From your local machine (whitelisted IP) — should succeed:**
```bash
curl "<paste the full SAS URL here>"
```

> [!WARNING]
> **Common shell gotcha:** if you don't wrap the URL in quotes, bash treats each unquoted `&` in the query string as a background-job separator — it silently splits your one URL into several background jobs and only sends the fragment before the first `&` to curl. This drops the SAS signature entirely, producing a `ResourceNotFound` error that looks like a real Azure problem but isn't. **Always quote the full URL.**

**From the jumpbox (via Bastion) — should also succeed, via the Service Endpoint route:**
```bash
curl "<same SAS URL>"
```

**Negative test — isolate identity-based trust from IP-based trust:**
1. Storage Account → Networking → remove your own IP rule → Save
2. Retry from your **local machine** → expect:
   ```
   <Error><Code>AuthorizationFailure</Code><Message>This request is not authorized to perform this operation.</Message></Error>
   ```
3. Retry the **same SAS URL, unchanged, from the jumpbox** → expect the file content to still return successfully

This isolates the subnet's *identity* — not an IP address — as what's actually being trusted.

[SCREENSHOT: AuthorizationFailure from local machine]
[SCREENSHOT: successful curl output from jumpbox]

---

## 5. Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| `ResourceNotFound` when curling a SAS URL | Unquoted URL — bash split it at each `&`, only the fragment before the first `&` was sent, dropping the SAS signature | Wrap the entire SAS URL in double quotes |
| Confusion over `$logs` container appearing unexpectedly | Auto-generated system container for Storage Analytics logging — not something you created | Ignore it; not part of this lab |
| Forgot to create the `content` container | It's a separate manual step after the storage account wizard finishes, easy to skip | Containers → + Container → name `content` → Private access level |
| `AuthorizationFailure` from local machine after removing IP rule | **Expected** — this is the success condition for the negative test in [4.6](#46-verify-access--run-the-negative-test) | N/A |

---

## 6. Acronyms

| Acronym | Meaning |
|---|---|
| VNet | Virtual Network |
| NIC | Network Interface Card |
| SAS | Shared Access Signature |
| RBAC | Role-Based Access Control |
| NSG | Network Security Group |
| NAT | Network Address Translation |
| LRS | Locally-Redundant Storage |
| TLS | Transport Layer Security |
| DOA | Default Outbound Access (Azure networking term, retired for new subnets as of March 31, 2026) |