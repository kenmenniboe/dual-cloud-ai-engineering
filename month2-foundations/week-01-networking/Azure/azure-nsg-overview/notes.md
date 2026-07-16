# NSG (Network Security Groups) — Detailed Notes

**Date:** Tue Jun 10, 2026
**Course:** AZ-104 (Udemy side-by-side)
**Topic:** Network Security Groups — Fundamentals & Security Rules

---

## Module 1: What is an NSG?

### Definition

An NSG (Network Security Group) is a **Layer 4 firewall ruleset** in Azure that controls
**inbound and outbound network traffic** to Azure resources.

It filters traffic based on:
- Source / Destination IP address
- Port number (e.g. 80, 443, 22, 3389)
- Protocol (TCP, UDP, or Any)
- Direction (Inbound or Outbound)

### OSI Layer

NSGs operate at **Layer 4 (Transport Layer)**.

| Layer | Tool | What it inspects |
|---|---|---|
| Layer 4 | NSG | IP, Port, Protocol |
| Layer 7 | Azure Firewall / WAF | HTTP paths, URLs, content, malware |

> NSGs cannot inspect the content of traffic — for that you need Azure Firewall or WAF.

### Real-World Analogy

> NSG = **bouncer at a nightclub** — checks your ID and ticket (who you are, what port you're using).
> Azure Firewall = **security guard who searches your bag** (what you're actually carrying/doing).

---

### Where Can an NSG Be Attached?

| Attachment Point | Scope |
|---|---|
| **Subnet** | Protects ALL resources inside that subnet |
| **Network Interface (NIC)** | Protects ONE specific VM |

> An NSG is **optional** on both — but best practice is to always attach one.

### Subnet-Level vs NIC-Level — When to Use Which

| Scenario | Best Choice |
|---|---|
| Same rules for all VMs in a subnet | Subnet NSG |
| Rules specific to one individual VM | NIC NSG |

### Multiple Subnets — Each Gets Its Own NSG

Example — classic 3-tier architecture:

| Subnet | NSG | Rule Example |
|---|---|---|
| Web-Subnet | NSG-Web | Allow 80, 443 from internet |
| App-Subnet | NSG-App | Allow traffic from Web-Subnet only |
| DB-Subnet | NSG-DB | Allow traffic from App-Subnet only |

> [Screenshot placeholder — Azure Portal: VNet with 3 subnets, each with an attached NSG]

---

### Applying NSG to Both Subnet AND NIC

You **can** attach an NSG to both the subnet and the NIC of the same VM simultaneously.
Azure evaluates **both** — in a specific order.

#### Inbound Traffic Evaluation Order

```
Internet → [ Subnet NSG ] → [ NIC NSG ] → VM
```

1. Subnet NSG evaluated **first**
2. NIC NSG evaluated **second**

#### Outbound Traffic Evaluation Order

```
VM → [ NIC NSG ] → [ Subnet NSG ] → Internet
```

1. NIC NSG evaluated **first**
2. Subnet NSG evaluated **second**

#### The Critical Rule

> If **either** NSG denies the traffic — it is **blocked. Full stop.**
> **Both** NSGs must allow the traffic for it to pass through.

#### Exam Trap Example

- Subnet NSG: **Allow** port 443
- NIC NSG: **Deny** port 443
- Result: ❌ Traffic is **blocked** — NIC NSG denial wins

---

## Module 2: NSG Security Rules

### The 5 Components of Every Rule

| Property | Description |
|---|---|
| **Priority** | Number 100–4096. Lower number = evaluated first |
| **Source** | Where traffic originates (IP, range, Service Tag) |
| **Destination** | Where traffic is going |
| **Port** | Port number (e.g. 443, 22, 3389) or range |
| **Action** | Allow ✅ or Deny ❌ |

### Priority — How It Works

- Range: **100 to 4096**
- **Lower number = higher priority = evaluated first**
- Azure evaluates rules in order and **stops at the first match**
- Custom rules should start at 100 — leaves room before defaults kick in

#### Priority Analogy

> Priority 100 = VIP guest — checked first, no questions asked
> Priority 4096 = last person on the list — only checked if nobody matched above

#### Exam Trap Example

| Priority | Port | Action |
|---|---|---|
| 100 | 3389 | ❌ Deny |
| 200 | 3389 | ✅ Allow |

Result: **RDP is denied** — rule 100 is evaluated first, deny wins, rule 200 is never reached.

---

### Default NSG Rules

Every NSG includes **3 built-in default rules** for inbound and outbound.
These **cannot be deleted** — but can be overridden with a lower priority number.

#### Default Inbound Rules

| Priority | Name | Source | Destination | Port | Action |
|---|---|---|---|---|---|
| 65000 | AllowVnetInBound | VirtualNetwork | VirtualNetwork | Any | ✅ Allow |
| 65001 | AllowAzureLoadBalancerInBound | AzureLoadBalancer | Any | Any | ✅ Allow |
| 65500 | DenyAllInBound | Any | Any | Any | ❌ Deny |

#### Default Outbound Rules

| Priority | Name | Source | Destination | Port | Action |
|---|---|---|---|---|---|
| 65000 | AllowVnetOutBound | VirtualNetwork | VirtualNetwork | Any | ✅ Allow |
| 65001 | AllowInternetOutBound | Any | Internet | Any | ✅ Allow |
| 65500 | DenyAllOutBound | Any | Any | Any | ❌ Deny |

> [Screenshot placeholder — Azure Portal: NSG default inbound and outbound rules]

#### Key Insight

> **DenyAllInBound / DenyAllOutBound at 65500** is the safety net — catches anything
> that didn't match a previous rule. You don't need to create your own deny-all rule.

---

### Designing a Minimal Ruleset — Exam Pattern

Goal: Allow HTTP and HTTPS from internet, block everything else.

| Priority | Port | Action | Notes |
|---|---|---|---|
| 100 | 80 | ✅ Allow | HTTP |
| 200 | 443 | ✅ Allow | HTTPS |
| 65500 | Any | ❌ Deny | Default — no custom rule needed |

> Only 2 custom rules needed — let the default DenyAll handle the rest.

---

## Quick Reference Summary

| Concept | Key Takeaway |
|---|---|
| What is an NSG | Layer 4 traffic filter — IP, port, protocol |
| Attachment points | Subnet (broad) or NIC (granular) |
| Multiple subnets | Each subnet can have its own NSG |
| Both at once | Allowed — evaluated in order |
| Inbound order | Subnet NSG → NIC NSG |
| Outbound order | NIC NSG → Subnet NSG |
| Deny rule | Either NSG denying = traffic blocked |
| Priority range | 100–4096, lower = higher priority |
| First match wins | Azure stops at first matching rule |
| Default rules | 3 inbound, 3 outbound — cannot be deleted |
| DenyAll | Priority 65500 — always last resort |

---

## Up Next

- **Module 3:** Service Tags and Application Security Groups (ASGs)
- **Advanced:** NSG Flow Logs, diagnostics, and exam edge cases