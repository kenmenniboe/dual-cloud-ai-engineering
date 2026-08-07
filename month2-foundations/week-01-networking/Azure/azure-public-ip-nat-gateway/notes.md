# Azure Public IP + NAT Gateway — Full Notes (AZ-104)

No course transcript existed for this section, so this curriculum was self-designed and taught in Socratic style, with a live current-state check on Azure NAT Gateway SKUs partway through.

## Table of Contents
- [1. What is a Public IP?](#1-what-is-a-public-ip)
- [2. NIC Refresher](#2-nic-refresher)
- [3. Basic vs. Standard SKU](#3-basic-vs-standard-sku)
- [4. Static vs. Dynamic Allocation](#4-static-vs-dynamic-allocation)
- [5. Availability Zones for Public IPs](#5-availability-zones-for-public-ips)
- [6. Public IP Prefix (footnote)](#6-public-ip-prefix-footnote)
- [7. NAT Gateway — The Concept](#7-nat-gateway--the-concept)
- [8. Correction: NAT Gateway Standard vs. StandardV2](#8-correction-nat-gateway-standard-vs-standardv2)
- [9. Architecture Diagram](#9-architecture-diagram)
- [10. Hands-On Lab](#10-hands-on-lab)
  - [10.1 Part A — VNet, Bastion, Jumpbox](#101-part-a--vnet-bastion-jumpbox)
  - [10.2 Part B — Public IP](#102-part-b--public-ip)
  - [10.3 Part C — NAT Gateway](#103-part-c--nat-gateway)
  - [10.4 Part D — Verify Outbound Connectivity](#104-part-d--verify-outbound-connectivity)
  - [10.5 Part E — Negative Test](#105-part-e--negative-test)
- [11. Acronyms](#11-acronyms)
- [12. Redo Guide (Condensed)](#12-redo-guide-condensed)

---

## 1. What is a Public IP?

A Public IP is a **standalone Azure resource** — an internet-routable address you create separately, then attach to something else: a NIC, a Load Balancer frontend, an Application Gateway, a NAT Gateway, VPN Gateway, or Bastion.

**Analogy:** A Public IP is like a phone number — not the phone itself, but something assigned to a device. A VM's private IP is the internal office extension; the Public IP is the outside line.

> [!NOTE]
> **AWS anchor:** Direct match to an EC2 instance's public-facing address — except in AWS you either get an ephemeral auto-assigned public IP or an Elastic IP. Azure's Public IP resource is more like the Elastic IP model — it's always a distinct, manageable resource.

**Q asked:** *Can a VM with no Public IP, no NAT Gateway, and no Load Balancer reach the internet?*
**A:** No — without a Public IP or an outbound path, there's no route out. Older Azure behavior had an implicit default-outbound fallback; Microsoft has been retiring that (see §8 and the March 31, 2026 private-subnet-by-default change).

---

## 2. NIC Refresher

A **NIC (Network Interface Card)** is the virtual network adapter attached to a VM — it plugs the VM into a subnet. It holds the VM's private IP, MAC address, and (optionally) an associated Public IP and/or NSG.

**Key relationship:** VM → NIC → subnet. The VM itself doesn't hold an IP — the NIC does. A Public IP attaches to a specific **IP configuration on the NIC**, not to the VM, subnet, or VNet directly.

**Analogy:** The NIC is the physical network port on the back of the VM. The private IP is the wired connection to the local office network; a Public IP is an extra cable plugged into that same port reaching the outside world.

> [!NOTE]
> **AWS anchor:** Direct match to an **ENI (Elastic Network Interface)**. EC2 instance → ENI → subnet, private IP lives on the ENI, Elastic IP (if any) associates to it.

---

## 3. Basic vs. Standard SKU

| | **Basic** | **Standard** |
|---|---|---|
| Allocation | Static or Dynamic | Static only |
| Security | Open by default (no NSG needed) | Secure by default — inbound denied unless NSG allows it |
| SLA | None | 99.99% |
| Zones | No zone support | Zonal, zone-redundant, or no-zone |
| Works with | VMs (basic scenarios) | Standard LB, NAT Gateway, App Gateway v2, Azure Firewall, Bastion |

> [!IMPORTANT]
> **Current-state note:** Basic SKU Public IPs stopped being creatable in the Portal as of **March 31, 2025**, and were fully retired **September 30, 2025**. In the Portal today, **Standard is the only real option** — this comparison still matters for the AZ-104 exam, but hands-on, you'll only ever see Standard.

**Q asked:** *What does SLA mean?*
**A: Service Level Agreement** — Microsoft's formal, financially-backed uptime promise. Standard Public IPs carry a 99.99% SLA with service credits if missed. Basic carries none.

> [!NOTE]
> **AWS anchor:** AWS doesn't tier IPs by SKU. Closest mapping: Azure Basic-Dynamic ≈ an EC2 instance's auto-assigned public IP (changes on stop/start). Azure Standard-Static (or old Basic-Static) ≈ an **Elastic IP** (persistent, reserved to the account).

**Key rule:** Azure enforces **SKU matching** between paired resources — a Standard Load Balancer requires a Standard Public IP; you cannot mix Basic and Standard on the same logical pair. Same rule applies to NAT Gateway.

---

## 4. Static vs. Dynamic Allocation

Independent setting from SKU — controls whether the IP address itself changes.

- **Dynamic:** Assigned from Azure's pool on start; released back to the pool on deallocation — may get a different address next time.
- **Static:** Reserved to the resource specifically; doesn't change across stop/start, only on explicit deletion.

**Analogy:** Dynamic is a hotel room (whatever's free at check-in, released at check-out). Static is an owned, named parking spot — always yours.

> [!IMPORTANT]
> Standard SKU **only** supports Static — Dynamic isn't offered as an option once you select Standard. Since Basic is retired for new creation, every Public IP built today will be Static in practice.

> [!NOTE]
> **AWS anchor:** Dynamic ≈ EC2 auto-assigned public IP. Static ≈ Elastic IP.

---

## 5. Availability Zones for Public IPs

Three configurations on a Standard Public IP:

- **Zone-redundant** (default): served from all zones in the region simultaneously — survives a single-zone failure.
- **Zonal:** pinned to one specific zone (1, 2, or 3) — goes down if that zone fails. Chosen deliberately to co-locate with a zonal resource.
- **No zone:** regional, non-redundant — rarely picked deliberately.

**Analogy:** Zone-redundant is a phone number that rings through to three offices in different parts of the city. Zonal only rings one office.

> [!NOTE]
> **AWS anchor:** An Elastic IP is regional, always reachable regardless of AZ — AWS doesn't zone-scope the IP itself. The real AWS parallel is that **NAT Gateway is inherently zonal in AWS**, so multi-AZ resilience means deploying one NAT Gateway (with its own EIP) *per AZ*. Azure's zone-redundant Public IP + (StandardV2) zone-redundant NAT Gateway achieves in one resource what AWS needs several resources to do.

Zone-redundancy requires the region to physically have multiple Availability Zones — it isn't available in regions without them.

---

## 6. Public IP Prefix (footnote)

A **contiguous block** of Public IPs (e.g., a /28 = 16 addresses) reserved together as one resource, instead of individual Public IPs one at a time. Useful when a partner needs to allowlist a known range, or when a NAT Gateway needs more outbound SNAT ports than a single IP provides.

**Analogy:** A single Public IP is renting one parking spot. A Prefix is leasing a whole numbered row at once.

> [!NOTE]
> **AWS anchor:** AWS's closest match is BYOIP with a CIDR block. More practically: since an AWS NAT Gateway attaches only one EIP each, getting a Prefix-like range of addresses in AWS means deploying multiple NAT Gateways — Azure's Prefix gives that whole block to a single NAT Gateway.

**Exam fact:** Prefixes must be Standard SKU; all IPs in the prefix share the same allocation and zone setting.

---

## 7. NAT Gateway — The Concept

A managed resource giving an entire **subnet outbound-only** internet access through a shared Public IP (or Prefix) — without any individual VM needing its own public address.

**Key characteristics:**
- **Outbound only** — cannot receive unsolicited inbound traffic.
- **Subnet-level attachment** — not per-VM or per-NIC.
- **Takes priority** over other outbound methods (e.g., a Load Balancer's outbound rules) once attached to a subnet.
- Requires a **Standard-tier** Public IP or Prefix (Basic never worked with NAT Gateway).

**Analogy:** NAT Gateway is the mailroom in an office building. Employees (VMs) drop mail there; it goes out under one building address. Nobody outside can mail *into* an employee through that address.

> [!NOTE]
> **AWS anchor:** Near 1:1 match to AWS NAT Gateway — outbound-only, attached via route table, one Elastic IP. Key difference: AWS NAT Gateway is inherently zonal (deploy one per AZ for HA); Azure's can be a single zone-redundant resource — see §8 for the current nuance on which SKU actually delivers that.

---

## 8. Correction: NAT Gateway Standard vs. StandardV2

> [!WARNING]
> Mid-session correction: NAT Gateway zone-redundancy isn't as simple as "select zone-redundant" like a Public IP. There are two NAT Gateway SKUs with materially different zone behavior.

| | **Standard (v1)** | **StandardV2** |
|---|---|---|
| Zone behavior | **Zonal only** — "No Zone" (Azure silently picks one zone) or a specific zone. No true zone-redundant option. | **Zone-redundant by default** |
| Compatible Public IP | Standard SKU Public IP | **StandardV2 Public IP only** — not cross-compatible with Standard |
| Protocol support | IPv4 only | IPv4 + IPv6 |
| Status | Long-standing, exam-standard | Newer, higher throughput, recommended for production going forward |

**Decision made for this lab:** kept the Standard (v1) NAT Gateway paired with the already-built Standard Public IP — simpler, matches current AZ-104 exam material — and accepted that the NAT Gateway itself is zonal (`No Zone` selected), even though its Public IP is zone-redundant. A zone-redundant *Public IP* does not make a Standard v1 NAT Gateway's own placement zone-redundant.

> [!TIP]
> For a genuinely zone-redundant path end-to-end, both the Public IP **and** the NAT Gateway need to be StandardV2 — that's a separate lab/redo, not what was built here.

---

## 9. Architecture Diagram

![NAT Gateway lab architecture](diagram.svg)

Yellow path = Bastion inbound management (RDP/SSH into the jumpbox). Green path = NAT Gateway outbound-only SNAT (jumpbox → internet). Both paths are independent — the jumpbox itself never has a Public IP.

---

## 10. Hands-On Lab

Goal: a VM with **no Public IP of its own** reaches the internet outbound-only through a Standard, zone-redundant Public IP attached to a Standard NAT Gateway.

### 10.1 Part A — VNet, Bastion, Jumpbox

**A1. Virtual Network**

| Tab | Field | Value |
|---|---|---|
| Basics | Resource group | Create new → `rg-natgw-lab` |
| Basics | Name | `vnet-natgw-lab` |
| Basics | Region | lab region |
| Security | Azure Bastion | off here (created separately in A3) |
| Security | DDoS Protection | Basic (default) |
| Security | Azure Firewall | Disabled |
| IP Addresses | Address space | `10.10.0.0/16` |
| IP Addresses | Subnet | `snet-workload` → `10.10.1.0/24` |
| Review + Create | — | Create |

**A2. Bastion subnet** — add to `vnet-natgw-lab` → Subnets:
- Name: exactly `AzureBastionSubnet`
- Range: `10.10.2.0/26`

**A3. Azure Bastion**

| Tab | Field | Value |
|---|---|---|
| Basics | Name | `bastion-natgw-lab` |
| Basics | Tier | Standard |
| Basics | Virtual network | `vnet-natgw-lab` |
| Basics | Subnet | `AzureBastionSubnet` (auto-detected) |
| Basics | Public IP | Create new → `pip-bastion-natgw-lab`, Standard SKU |
| Review + Create | — | Create |

**A4. Jumpbox VM — no Public IP**

| Tab | Field | Value |
|---|---|---|
| Basics | VM name | `vm-jumpbox` |
| Basics | Image | Ubuntu Server 24.04 LTS |
| Basics | Size | B1s / B2s |
| Basics | Auth type | SSH public key (or password) |
| Basics | Inbound port rules | None |
| Disks | OS disk | Standard SSD |
| Networking | Virtual network / Subnet | `vnet-natgw-lab` / `snet-workload` |
| Networking | **Public IP** | **None** ← critical |
| Networking | NIC NSG | Basic, allow SSH from Bastion range only (or default + rely on Bastion) |
| Review + Create | — | Create |

<!-- SCREENSHOT: Part A complete — VNet + Bastion + jumpbox overview in resource group -->

### 10.2 Part B — Public IP

| Tab | Field | Value |
|---|---|---|
| Basics | Resource group | `rg-natgw-lab` |
| Basics | Region | same as VNet |
| Basics | Name | `pip-natgw-lab` |
| Basics | IP Version | IPv4 |
| Basics | SKU | **Standard** |
| Basics | Tier | Regional |
| Basics | Availability zone | **Zone-redundant** |
| Basics | Routing preference | Microsoft network (default) |
| Basics | Allocation | Static (auto-set, greyed out) |
| Basics | Idle timeout | 4 minutes |
| Basics | DNS name label | skip |
| Review + Create | — | Create |

**Result:** `pip-natgw-lab` → **20.15.150.94**

<!-- SCREENSHOT: Public IP resource overview showing SKU=Standard, Allocation=Static, Zone=Zone-redundant -->

### 10.3 Part C — NAT Gateway

| Tab | Field | Value |
|---|---|---|
| Basics | Resource group | `rg-natgw-lab` |
| Basics | Region | must match Public IP's region exactly |
| Basics | Name | `natgw-lab` |
| Basics | Availability zone | **No Zone** (Standard v1 has no true zone-redundant option — see §8) |
| Basics | Idle timeout | 4 minutes |
| Outbound IP | Public IP addresses | Add → `pip-natgw-lab` |
| Outbound IP | Public IP prefix | none |
| Subnet | Virtual network | `vnet-natgw-lab` |
| Subnet | Subnet(s) | check **`snet-workload`** only — not `AzureBastionSubnet` |
| Review + Create | — | Create |

> [!TIP]
> If `pip-natgw-lab` doesn't show up as selectable in the Outbound IP tab, double-check the NAT Gateway's region matches the Public IP's region exactly — Azure enforces regional co-location silently.

<!-- SCREENSHOT: NAT Gateway overview showing attached Public IP and subnet association -->

### 10.4 Part D — Verify Outbound Connectivity

1. Portal → `vm-jumpbox` → **Connect** → **Bastion** → sign in.
2. From the jumpbox terminal, run the commands in [`commands.md`](commands.md) (`curl ifconfig.me`, `sudo apt update`).
3. Confirm the returned IP matches `pip-natgw-lab` (**20.15.150.94**) — not the private `10.10.1.x` address, not Bastion's IP.

**Result:** `curl ifconfig.me` → `20.15.150.94`; `sudo apt update` fetched 36.4 MB successfully.

**Why it works:** NAT Gateway performs **SNAT** — rewriting the jumpbox's private source IP to the NAT Gateway's Public IP on the way out, and reversing that mapping for return traffic. The internet only ever sees `20.15.150.94`.

### 10.5 Part E — Negative Test

Proves causation, not just correlation.

1. `vnet-natgw-lab` → Subnets → `snet-workload` → **NAT gateway** → set to **None** → Save.
2. Re-run `curl -s --max-time 10 ifconfig.me` from the jumpbox.
   **Result:** empty response — timed out. No NAT Gateway, no outbound path at all.
3. Reattach: same subnet blade → **NAT gateway** → select `natgw-lab` → Save.
4. Re-run `curl -s ifconfig.me` → confirmed **20.15.150.94** again — connectivity restored.

<!-- SCREENSHOT: Subnet NAT gateway setting toggled back to natgw-lab -->

---

## 11. Acronyms

| Acronym | Meaning |
|---|---|
| NIC | Network Interface Card |
| SKU | Stock-Keeping Unit (the resource "tier"/edition) |
| SLA | Service Level Agreement |
| SNAT | Source Network Address Translation |
| NAT | Network Address Translation |
| NSG | Network Security Group |
| VNet | Virtual Network |
| CIDR | Classless Inter-Domain Routing |
| ENI | Elastic Network Interface (AWS) |
| EIP | Elastic IP (AWS) |

---

## 12. Redo Guide (Condensed)

```
1. Create rg-natgw-lab
2. Create vnet-natgw-lab (10.10.0.0/16) with snet-workload (10.10.1.0/24)
3. Add AzureBastionSubnet (10.10.2.0/26)
4. Create bastion-natgw-lab (Standard tier) + pip-bastion-natgw-lab (Standard)
5. Create vm-jumpbox (Ubuntu 24.04, subnet=snet-workload, Public IP=None)
6. Create pip-natgw-lab (Standard, Static, Zone-redundant)
7. Create natgw-lab (Standard v1, No Zone) → attach pip-natgw-lab → attach snet-workload
8. Bastion into vm-jumpbox → curl ifconfig.me → expect pip-natgw-lab's address
9. Negative test: detach NAT gateway from snet-workload → curl times out
10. Reattach natgw-lab → curl succeeds again
11. Tear down: delete rg-natgw-lab (removes everything in one shot)
```