# Azure VPN Gateway — Site-to-Site (S2S) — Reference Guide

AZ-104 hands-on lab: simulating an on-prem ↔ Azure Site-to-Site VPN using two Azure VNets instead of physical hardware.

## Table of contents

- [1. Concept: what a Site-to-Site VPN Gateway is](#1-concept-what-a-site-to-site-vpn-gateway-is)
- [2. Concept: the Gateway Subnet](#2-concept-the-gateway-subnet)
- [3. Concept: the Virtual Network Gateway resource](#3-concept-the-virtual-network-gateway-resource)
- [4. Concept: the Local Network Gateway](#4-concept-the-local-network-gateway)
- [5. Concept: the Connection resource](#5-concept-the-connection-resource)
- [6. Real on-premises variant — what's different](#6-real-on-premises-variant--whats-different)
- [7. Final architecture](#7-final-architecture)
- [8. Redo guide — exact steps](#8-redo-guide--exact-steps)
  - [8.1 Resource group](#81-resource-group)
  - [8.2 VNet-A](#82-vnet-a)
  - [8.3 VNet-B](#83-vnet-b)
  - [8.4 Virtual Network Gateway — A](#84-virtual-network-gateway--a)
  - [8.5 Virtual Network Gateway — B](#85-virtual-network-gateway--b)
  - [8.6 Local Network Gateways](#86-local-network-gateways)
  - [8.7 Connections](#87-connections)
  - [8.8 Test VMs + Bastion Developer](#88-test-vms--bastion-developer)
- [9. Acronyms](#9-acronyms)
- [10. Outstanding / next session](#10-outstanding--next-session)

---

## 1. Concept: what a Site-to-Site VPN Gateway is

A **VPN Gateway** creates an encrypted tunnel (**IPsec/IKE**) between two networks over the **public internet**. **Site-to-Site (S2S)** connects an on-prem network (or another VNet) to an Azure VNet.

**IKE** (Internet Key Exchange) negotiates and authenticates the session and exchanges keys — same job as a TLS handshake, but at the network layer. **IPsec** then encrypts every packet using those keys. "Tunnel" doesn't mean a separate physical path — packets travel the same public internet routes as anything else; they're just wrapped in an encrypted envelope.

| | VNet Peering | VPN Gateway (S2S) |
|---|---|---|
| Path | Microsoft private backbone | Public internet |
| Encryption | Not needed | Required (IPsec/IKE) |
| Use case | Azure-to-Azure only | On-prem-to-Azure, or Azure-to-Azure over internet |
| Gateway resource? | No | Yes — billed hourly |

> [!TIP]
> Since a VPN Gateway just needs "an IP address speaking IPsec/IKE" on the far end, a second Azure VNet with its own gateway can stand in for real on-prem hardware. Config steps are identical either way — this is the standard AZ-104 lab technique.

## 2. Concept: the Gateway Subnet

Every VNet needs one dedicated subnet before a VPN Gateway can be created:

- Name must be **exactly** `GatewaySubnet`
- Minimum `/29`, **recommended `/27` or larger**
- **No NSG support** — attaching one can break the gateway
- One `GatewaySubnet` per VNet, no matter how many gateway resources/connections use it

## 3. Concept: the Virtual Network Gateway resource

The billed, compute-backed resource. Key choices at creation:

- **Gateway type**: `VPN` (not `ExpressRoute`)
- **VPN type**: `Route-based` (dynamic, handles multiple tunnels via routing) vs `Policy-based` (legacy, IKEv1 only, one tunnel, fixed address list) — Route-based is the near-universal choice today
- **SKU**: determines cost, throughput, and feature support (BGP, active-active, zone redundancy)
- **Public IP**: required — this is what the *other side* connects to

## 4. Concept: the Local Network Gateway

**Not a gateway** — a free metadata resource with three fields:

- **Name**
- **Endpoint** — the public IP of the *other side's* Virtual Network Gateway
- **Address space** — the CIDR range(s) behind that IP

No SKU, no Public IP of its own, no hourly compute cost. It's how your real gateway knows *where* to send traffic for a given destination range.

> [!NOTE]
> In a two-VNet lab, **each side needs an LNG describing the other side** — 2 real gateways + 2 free LNGs = 4 resources total, but only the 2 gateways are billed.

## 5. Concept: the Connection resource

Ties a Virtual Network Gateway to a Local Network Gateway and brings the tunnel up.

- **Connection type**: `Site-to-site (IPsec)`
- **Shared key (PSK)**: must match **exactly** on both sides — mismatched keys are the #1 cause of a tunnel stuck on `Not connected`
- Status shown on the Connection's Overview page: `Connecting` → `Connected`
- `Data in` / `Data out` stay at `0 B` until actual traffic crosses the tunnel — a `Connected` status alone doesn't prove data flows

## 6. Real on-premises variant — what's different

Everything above was simulated using a second Azure VNet standing in for "on-prem." For a genuine on-prem-to-Azure connection, the resources and steps shrink on the Azure side, and a few things move outside Azure entirely:

- **Only one Virtual Network Gateway is needed** — on the Azure side. There's no `vnet-b` / `vgw-b`; the on-prem side isn't an Azure resource at all, it's physical or virtualized hardware outside Azure's control plane.
- **Only one Local Network Gateway is needed**, representing the real on-prem device: its public IP (or FQDN) as the **Endpoint**, and the on-prem network's real address range(s) as the **Address space**.
- **Only one Connection resource is needed** on the Azure side. There's no mirrored "other direction" Connection to create in the Portal — the on-prem device is configured separately, on its own admin console, to match.

> [!IMPORTANT]
> **The on-prem device needs matching IKE/IPsec parameters**, configured on its own management interface (Azure Portal never touches it): shared key, IKE version, encryption/integrity algorithms, DH group, PFS group, SA lifetimes. Azure's **Default** IPsec/IKE policy is a common baseline most modern devices support out of the box, but a parameter mismatch here is just as common a "Not connected" cause as a shared-key typo.

> [!TIP]
> Azure Portal can generate a **device-specific config script**: from the Connection resource → **Download configuration** → pick the on-prem device's vendor/OS (Cisco, Juniper, Fortinet, pfSense, etc.) — pre-fills most IKE/IPsec parameters automatically. Not used in this simulated lab since there was no real device to configure.

Other real-world differences:

- **Public IP stability matters more.** A real on-prem VPN device typically needs a **static** public IP, or a Dynamic DNS-backed FQDN — the Local Network Gateway's Endpoint needs a stable value, since a drifting IP breaks the tunnel until the LNG is manually updated.
- **NAT and firewall rules on-prem**: the on-prem firewall must explicitly allow **UDP 500** (IKE) and **UDP 4500** (IPsec NAT-Traversal) both directions to/from Azure's gateway public IP. If the VPN device itself sits behind a separate NAT device, NAT-T handling needs to be enabled there too.
- **BGP becomes more practical.** This lab used static routing (manually-maintained address spaces on the LNG) since keeping two VNets in sync is trivial. With a real on-prem router that supports BGP, dynamic route propagation avoids manually updating the LNG's address space every time the on-prem network changes.

## 7. Final architecture

![Site-to-Site VPN lab architecture](images/architecture-diagram.svg)

Two VNets, each with a Virtual Network Gateway in a `GatewaySubnet`, each pointed at the other via a Local Network Gateway, linked by a Connection resource carrying the IPsec/IKE tunnel. (For the real on-prem variant, VNet-B collapses into a single physical/virtual on-prem device — see [Section 6](#6-real-on-premises-variant--whats-different).)

## 8. Redo guide — exact steps

### 8.1 Resource group

| Field | Value |
|---|---|
| Name | `rg-vpn-s2s-lab` |
| Region | Central US |

### 8.2 VNet-A

**Basics**: Resource group `rg-vpn-s2s-lab`, Name `vnet-a`, Region Central US
**IP Addresses**: `10.1.0.0/16` → subnets: `snet-a-workload` (`10.1.1.0/24`), `GatewaySubnet` (`10.1.255.0/27`)
**Security**: Bastion / DDoS / Firewall all **Disabled**

![Screenshot: VNet-A IP Addresses tab](images/vnet-a-ip-addresses.png)

### 8.3 VNet-B

Same as 8.2, mirrored: `vnet-b`, `10.2.0.0/16` → `snet-b-workload` (`10.2.1.0/24`), `GatewaySubnet` (`10.2.255.0/27`)

> [!WARNING]
> Address spaces must **not overlap** between VNet-A and VNet-B — the tunnel has no way to route correctly if both sides use the same range. (In the real on-prem variant, this becomes: VNet-A's range must not overlap the real on-prem network's range.)

### 8.4 Virtual Network Gateway — A

Original plan was **Basic SKU** (~$0.04/hr).

> [!IMPORTANT]
> **Portal validation/availability issue:** Basic SKU does not appear as a selectable option in the Portal's Create Virtual Network Gateway blade. Current Microsoft documentation confirms Basic SKU is **CLI/PowerShell-only** now. **Fix:** switched to **VpnGw1AZ**, the cheapest Portal-selectable, currently-recommended SKU (Microsoft is steering new deployments toward AZ-suffixed SKUs generally; legacy `VpnGw1`–`VpnGw5` non-AZ are slated for migration).

| Field | Value |
|---|---|
| Name | `vgw-a` |
| Gateway type | VPN |
| VPN type | Route-based |
| SKU | VpnGw1AZ |
| Virtual network | `vnet-a` |
| Public IP | Create new, `vgw-a-pip`, Standard, Static |
| Enable active-active mode | **Disabled** |
| Configure BGP | **Disabled** |
| Enable Key Vault Access | Disabled |

> [!NOTE]
> **Unexpected field: "Enable Advanced Connectivity."** Replaced the "Generation" dropdown described in older documentation — no authoritative Microsoft doc found describing it at time of lab. Left at default (**Disabled**) since it wasn't needed for a basic S2S tunnel.

> [!TIP]
> A **"Second public IP address"** section appears on this page — it's only relevant if **Enable active-active mode** is set to Enabled. Since we set it to Disabled, that section can be left blank entirely.

Deployment time: **30–45 minutes**.

![Screenshot: vgw-a Basics tab](images/vgw-a-basics.png)

### 8.5 Virtual Network Gateway — B

Same as 8.4, mirrored: `vgw-b`, `vnet-b`, Public IP `vgw-b-pip`, same SKU/toggles.

> [!NOTE]
> In the real on-prem variant (see [Section 6](#6-real-on-premises-variant--whats-different)), this step doesn't exist — there is no second Azure gateway.

### 8.6 Local Network Gateways

**`lng-b`** (created alongside VNet-A's side, represents VNet-B):
| Field | Value |
|---|---|
| Name | `lng-b` |
| Endpoint | IP address of `vgw-b-pip` |
| Address space | `10.2.0.0/16` |
| Configure BGP | No |

**`lng-a`** (mirrored, represents VNet-A):
| Field | Value |
|---|---|
| Name | `lng-a` |
| Endpoint | IP address of `vgw-a-pip` |
| Address space | `10.1.0.0/16` |
| Configure BGP | No |

> [!TIP]
> Public IPs typically resolve faster than full gateway provisioning — grab them from **Public IP addresses** in the Portal while the gateways are still deploying, so the LNGs can be created without waiting idle.

> [!NOTE]
> In the real on-prem variant, only `lng-b`-equivalent exists — one LNG, pointed at the real on-prem device's public IP/FQDN and real address space.

### 8.7 Connections

**`connect-a-to-b`**:
| Field | Value |
|---|---|
| Connection type | Site-to-site (IPsec) |
| Virtual network gateway | `vgw-a` |
| Local network gateway | `lng-b` |
| Shared key | `VpnLab-S2S-Aug2026!` |
| IKE Protocol | IKEv2 |
| Enable BGP / Use Azure Private IP / FastPath | all unchecked |
| Use policy based traffic selector | Disable |
| DPD timeout | 45 |
| Connection Mode | Default |

**`connect-b-to-a`**: mirrored — `vgw-b` → `lng-a`, **same shared key**.

> [!NOTE]
> Right after creating both Connections, one showed `Connected` while the other briefly showed `Connecting`. This is normal propagation lag — each Connection resource reports its own state independently. It settled to `Connected` on both sides after refreshing about a minute later; no action needed.

> [!NOTE]
> In the real on-prem variant, only `connect-a-to-b`-equivalent exists on the Azure side. The matching configuration on the on-prem device (shared key, IKE/IPsec parameters) is applied separately, on that device's own admin console — see [Section 6](#6-real-on-premises-variant--whats-different).

Result confirmed this session: both connections → **Status: Connected**.

### 8.8 Test VMs + Bastion Developer

**VM Basics (both `vm-a` and `vm-b`)**: Ubuntu Server 24.04 LTS, size **`Standard_B1s`**, Authentication: Password, Public inbound ports: **None**.
**Networking**: matching VNet/workload subnet, **Public IP: None**, NIC NSG: None.

> [!WARNING]
> **`vm-b` deployed with size `Standard D2s v3` instead of `Standard_B1s`, plus an unintended public IP (assigned automatically) with NIC NSG set to None** — meaning SSH was open to the internet with no filtering. Root cause not confirmed (likely a Portal default on the Networking tab that wasn't overridden as intended). **Fix** (not yet completed as of end of session):
> 1. Stop `vm-b`
> 2. Networking blade → NIC → IP configurations → `ipconfig1` → Public IP address → **Disassociate** → Save
> 3. Delete the orphaned Public IP resource
> 4. Resize to `Standard_B1s` while stopped
> 5. Start `vm-b` again
> 6. **Before repeating this VM creation step in future labs**, double-check the Networking tab's Public IP dropdown explicitly shows "None" selected before submitting — don't assume the default matches what was picked earlier in the wizard.

Bastion access plan: use the free **Bastion Developer SKU** (confirmed available in Central US, no dedicated subnet required, one VM at a time) via the VM's own **Connect → Bastion** tab, rather than deploying a separate Basic/Standard Bastion host.

## 9. Acronyms

| Acronym | Meaning |
|---|---|
| S2S | Site-to-Site |
| IKE | Internet Key Exchange — negotiates/authenticates the VPN session, exchanges keys |
| IPsec | Internet Protocol Security — encrypts and authenticates packets using IKE's keys |
| PSK | Pre-Shared Key — the shared secret both Connection resources must match exactly |
| LNG | Local Network Gateway — metadata pointer to the remote side's public IP + address space |
| VNG | Virtual Network Gateway — the billed, compute-backed gateway resource |
| BGP | Border Gateway Protocol — dynamic route propagation; not used in this lab (static routing via LNG) |
| PIP | Public IP (address) |
| NSG | Network Security Group |
| DPD | Dead Peer Detection — timeout used to detect a lost tunnel |
| APIPA | Automatic Private IP Addressing — the address range used for BGP peering IPs in some configs |
| NAT-T | NAT Traversal — lets IPsec/IKE traffic pass through a device performing NAT |
| FQDN | Fully Qualified Domain Name — usable as a Local Network Gateway Endpoint instead of a static IP |

## 10. Outstanding / next session

- [ ] Apply the `vm-b` public IP / NSG fix (see [Section 8.8](#88-test-vms--bastion-developer))
- [ ] Deploy Bastion Developer SKU via `vm-a`'s Connect blade
- [ ] SSH into `vm-a` via Bastion, `ping` `vm-b`'s private IP
- [ ] Confirm `Data in` / `Data out` on both Connections go above `0 B`
- [ ] Delete `rg-vpn-s2s-lab` once validation is complete (standard cleanup habit)