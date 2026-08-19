# Azure Virtual WAN — Conceptual Walkthrough + Private Link Service Recap

> Conceptual session — no hands-on deployment (full hub build intentionally skipped per AZ-104 "basics" depth: not worth the cost/time).

## Table of Contents
- [Session Overview](#session-overview)
- [Module 1: What Is Azure Virtual WAN?](#module-1-what-is-azure-virtual-wan)
- [Module 2: Core Building Blocks](#module-2-core-building-blocks)
- [Module 3: Basic vs Standard SKU](#module-3-basic-vs-standard-sku)
- [Module 4: vWAN vs Traditional Hub-and-Spoke](#module-4-vwan-vs-traditional-hub-and-spoke)
- [Module 5: Routing Basics](#module-5-routing-basics)
- [Module 6: Private Link Service — Quick Recap](#module-6-private-link-service--quick-recap)
- [Architecture Diagram](#architecture-diagram)
- [Quiz Review (Self-Test / Redo)](#quiz-review-self-test--redo)
- [Acronyms](#acronyms)
- [Buffer — Deferred to Future Sessions](#buffer--deferred-to-future-sessions)

---

## Session Overview

This session covered the **conceptual model** of Azure Virtual WAN (vWAN) — what it is, its core components, SKU tiers, how it compares to traditional Hub-and-Spoke, and basic routing behavior — followed by a quick recap of **Private Link Service** (the provider-side counterpart to the Private Endpoint lab already completed). No new Azure resources were deployed this session.

---

## Module 1: What Is Azure Virtual WAN?

**The problem it solves:** Traditional Hub-and-Spoke (manual VNet Peering) works fine for a handful of VNets in one region, but becomes unmanageable at scale — many VNets, many regions, many branch VPNs, ExpressRoute circuits, and remote users, all needing manual peering and routing config.

**Virtual WAN** is Microsoft's managed, global network hub-of-hubs service. It automates connectivity and routing between VNets, branches, and users at scale, across regions — you don't manually peer or configure routing between spokes.

> [!TIP]
> **Analogy:** Traditional Hub-and-Spoke = you personally wiring an office phone system. Virtual WAN = hiring the phone company (Microsoft) to run a managed switching network — you plug in, they route it.

---

## Module 2: Core Building Blocks

| Component | Role |
|---|---|
| **Virtual WAN resource** | Top-level container/management wrapper only — does **not** do networking itself, no traffic flows "through" it directly |
| **Virtual Hub** | The actual Microsoft-managed regional networking component |
| **Hub Virtual Network Connections** | How existing VNets attach to the hub (replaces manual VNet Peering) |
| **VPN Gateway** (in hub) | Terminates Site-to-Site (branch) VPN tunnels |
| **ExpressRoute Gateway** (in hub) | Terminates ExpressRoute circuits from on-prem |
| **Point-to-Site (User VPN) Gateway** (in hub) | Terminates individual remote-user connections |
| **Azure Firewall** (optional, via Firewall Manager) | Centralized traffic inspection |

All three gateway types are independent and can coexist in the same hub simultaneously.

> [!WARNING]
> **Common mix-up (caught live this session):** The Virtual WAN resource does **not** terminate any connections — it's a pure management container. The actual tunnel/circuit endpoints are the specific gateway resources (VPN Gateway, ExpressRoute Gateway, P2S Gateway) deployed **inside** the Virtual Hub. Also — VPN Gateway ≠ ExpressRoute Gateway; they're separate resource types for separate connection methods.

> [!TIP]
> **Analogy:** Virtual WAN = the corporate network plan (organizational decision). Virtual Hub = a regional POP/data center Microsoft built for you. Gateways = the physical connection ports at that POP (one type per connection method).

---

## Module 3: Basic vs Standard SKU

| | Basic | Standard |
|---|---|---|
| Site-to-Site VPN | ✅ | ✅ |
| ExpressRoute | ❌ | ✅ |
| Point-to-Site (User VPN) | ❌ | ✅ |
| Hub-to-hub routing/transit | ❌ | ✅ |
| VNet-to-VNet transit through hub | ❌ | ✅ |
| Azure Firewall / Firewall Manager integration | ❌ | ✅ |
| Custom route tables | ❌ | ✅ |

Most real deployments use **Standard** — Basic is too limited (VPN-only) for typical enterprise needs.

---

## Module 4: vWAN vs Traditional Hub-and-Spoke

| | Traditional Hub-and-Spoke | Virtual WAN |
|---|---|---|
| Hub | A VNet you build and manage | Microsoft-managed Virtual Hub |
| Connecting spokes | Manual VNet Peering, one pair at a time | Hub Virtual Network Connections, centrally managed |
| Spoke-to-spoke routing | Manual UDRs or peering-mesh | Automatic by default |
| Branch VPN/ExpressRoute | Self-managed Gateway VNet | Built-in gateways inside the hub |
| Scale | Manageable for small numbers | Built for large-scale, multi-region |
| Control level | Full manual control | Less granular, far less operational overhead |

**Key distinction:** Hub-and-Spoke is something *you* build with VNets and peering. Virtual WAN is a *managed service* — Azure operates the hub and automates routing underneath.

> [!TIP]
> **Analogy:** Hub-and-Spoke = running your own internal PBX (you own every wire). vWAN = outsourcing to a telecom provider's managed network (you plug in, they route it globally).

---

## Module 5: Routing Basics

1. **Default Route Table** — every connected VNet/site is associated with and propagates routes into it by default → automatic any-to-any reachability, zero manual config.
2. **Custom Route Tables** (Standard SKU only) — override default behavior to *segment* traffic. Example: force "Production" VNet traffic through Azure Firewall before reaching other spokes, while "Dev" VNet stays on the default table with direct routing.

> [!TIP]
> **Analogy:** Default route table = open-floor office, everyone reaches everyone. Custom route tables = badge-access zones — Finance's floor requires a security checkpoint (firewall) to reach Engineering, even in the same building.

---

## Module 6: Private Link Service — Quick Recap

Already built the **consumer side** (Private Endpoint) in the Azure SQL lab. This recap covers the **provider side**.

| | Private Endpoint | Private Link Service |
|---|---|---|
| Role | Consumer-side NIC that connects **into** a service | Provider-side object that **exposes** a service |
| Sits behind | N/A (it *is* the connection point) | A Standard Load Balancer |
| Use case | Reach a PaaS/other service privately | Publish your own service for others (even cross-tenant) to reach privately |

**Cross-tenant use case:** Company publishes an internal API behind a Standard Load Balancer → wraps it as a Private Link Service → a partner (different tenant) connects via their own Private Endpoint. No VNet peering required, no public exposure.

> [!TIP]
> **Analogy:** The SQL Private Endpoint lab = getting a private, unlisted line to call Microsoft's SQL service. Private Link Service = setting up your *own* unlisted line so *your* customers can call your app directly, bypassing the public switchboard.

---

## Architecture Diagram

![vWAN Architecture Diagram](diagram.svg)

*Shows: Virtual WAN container → two Virtual Hubs → gateways (VPN/ER/P2S) → branch/on-prem/remote-user connections → default vs custom route tables → Production VNet routed through Azure Firewall while Dev VNet uses default routing → automatic hub-to-hub mesh. Private Link Service noted separately as an independent concept (not part of hub routing).*

---

## Quiz Review (Self-Test / Redo)

Use this section to re-test yourself without re-reading the modules above.

1. **Scenario:** 5-country offices, 30 VNets across 6 regions, need centralized automated routing without manual peering. What do you use?
   <br>**Answer:** Azure Virtual WAN

2. **Scenario:** 3 branch offices need Site-to-Site VPN into vWAN, automatically reaching VNets. What terminates the branch VPN tunnels?
   <br>**Answer:** VPN Gateway (inside the hub) — *not* the Virtual WAN resource, *not* a Hub Virtual Network Connection

3. **Scenario:** An ExpressRoute circuit needs to connect into vWAN. What do you deploy inside the hub?
   <br>**Answer:** ExpressRoute Gateway (separate resource from VPN Gateway)

4. **Scenario:** Need both Site-to-Site VPN and ExpressRoute through the same vWAN. Which SKU?
   <br>**Answer:** Standard (Basic doesn't support ExpressRoute)

5. **Scenario:** 10 VNets already connected and meshed; a new spoke VNet needs to join and reach all existing spokes. What's required?
   <br>**Answer:** Just connect the new VNet to the Virtual Hub — routing is automatic, no manual peering/UDRs

6. **Scenario:** Production VNet traffic must be inspected by Azure Firewall before reaching other spokes; Dev VNet should route directly. How, in Standard SKU?
   <br>**Answer:** Create a custom route table, associate the Production connection with it (routed via Firewall); leave Dev on the default route table

7. **Scenario:** Internal API behind a Standard Load Balancer; a partner in a different tenant needs private access, no peering, no public exposure. What do you deploy on your side?
   <br>**Answer:** A Private Link Service, published from behind the Standard Load Balancer

---

## Acronyms

| Acronym | Meaning |
|---|---|
| vWAN | Virtual WAN |
| VNet | Virtual Network |
| Hub | Virtual Hub (within a Virtual WAN) |
| S2S | Site-to-Site (VPN) |
| P2S | Point-to-Site (VPN) |
| ER | ExpressRoute |
| SKU | Stock Keeping Unit (pricing/feature tier — Basic vs Standard here) |
| UDR | User-Defined Route |
| NVA | Network Virtual Appliance |
| IPsec | Internet Protocol Security (VPN tunnel encryption protocol) |
| PaaS | Platform as a Service |
| PE | Private Endpoint |
| PLS | Private Link Service |
| LB | Load Balancer |

---

