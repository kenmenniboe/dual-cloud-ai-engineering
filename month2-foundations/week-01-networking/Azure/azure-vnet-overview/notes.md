# AZ-104 — Virtual Networks: Detailed Notes

> A mini-tutorial covering Modules 1–4 of Azure VNet fundamentals.

---

## 📦 Module 1: Virtual Networks (VNets)

### What is a VNet?

A **Virtual Network (VNet)** is a private, isolated network inside Azure — your own controlled section of the cloud where you decide who gets in, who can talk to whom, and where the doors are.

### Real-World Analogy

Azure is a giant office building shared by thousands of companies. A VNet is like your company renting a private floor — other companies can't walk in. Your Azure resources (VMs, databases, apps) live on that floor and communicate through the VNet.

### Key Properties

- VNets are **region-locked** — a VNet in East US cannot stretch to West Europe
- Two VMs in different regions are on **completely separate networks** by default
- To connect VNets across regions, you need **VNet Peering** (covered later)

### Why Companies Need VNets

1. **Security** — keep resources off the public internet, away from bad actors
2. **Traffic Control** — decide what can talk to what, even between your own resources
3. **Isolation** — separate workloads logically (production vs dev, web vs database)

### What a VNet Consists Of

| Component | Purpose |
|---|---|
| **Address Space** | The range of IP addresses your VNet owns |
| **Subnets** | Smaller divisions inside the VNet |
| **NSG** | Controls allowed/denied traffic |
| **Route Tables** | Controls where traffic gets directed |
| **DNS Settings** | How resources find each other by name |
| **VNet Peering** | Connects two VNets together |
| **Service Endpoints** | Secure connection to Azure services |
| **Private Endpoints** | Brings Azure services into your VNet privately |
| **Gateway Subnet** | Used for VPN/ExpressRoute connections |
| **DDoS Protection** | Protects against denial-of-service attacks |

---

## 📦 Module 2: Subnets

### What is a Subnet?

A **Subnet** is a smaller section carved out of your VNet. Every Azure resource you create (VMs, etc.) **must live inside a subnet** — you can't just float resources inside a VNet without placing them in one.

### Real-World Analogy

If your VNet is a private office floor, **subnets are the separate rooms on that floor**:

- 🖥️ Web servers room (outside knocks allowed)
- 🗄️ Database room (no outside access, internal only)
- 🔧 Admin tools room (IT only)

### Address Space & Subnet Ranges

When you create a VNet, you assign it an **address space**:

```
VNet:  10.0.0.0/16   → ~65,000 IPs total
```

Then carve smaller chunks into subnets:

```
Web subnet:  10.0.1.0/24   → 256 IPs
DB subnet:   10.0.2.0/24   → 256 IPs
```

### Azure's 5 Reserved IPs Per Subnet

Azure reserves **5 IP addresses** in every subnet. Example for `10.0.1.0/24`:

| IP | Reserved For |
|---|---|
| `10.0.1.0` | Network address |
| `10.0.1.1` | Azure default gateway |
| `10.0.1.2` | Azure DNS mapping |
| `10.0.1.3` | Azure future use |
| `10.0.1.255` | Network broadcast address |

**Quick formula:** Usable IPs = Total IPs − 5

For a `/24` subnet: **256 − 5 = 251 usable IPs**

### Key Rules

- ❌ Subnets **cannot have overlapping IP ranges** — Azure throws an error
- ✅ Subnets in the **same VNet talk to each other by default** — no extra config needed
- ✅ Use separate subnets to **apply different NSGs** per workload type

### Why Not Put Everything in One Subnet?

- **Security:** Can't apply targeted rules — it's all or nothing
- **Management:** Harder to troubleshoot and scale
- A good cloud engineer separates resources by **function and sensitivity**

---

## 📦 Module 3: Network Security Groups (NSGs)

### What is an NSG?

An **NSG** is a list of rules that controls what traffic is **allowed or denied** into and out of your resources.

### Real-World Analogy

Think of an NSG as a **bouncer at a club door** with a list of rules:

- ✅ Allow port 80 (HTTP)
- ❌ Deny port 22 (SSH) from outside
- ✅ Allow port 443 (HTTPS)

### Where NSGs Attach

NSGs can attach to **two places**:

1. **Subnet** — rules apply to **everything inside** that subnet
2. **Network Interface (NIC)** — rules apply to **one specific VM**

### NSG Rule Properties

| Property | Description |
|---|---|
| **Priority** | 100–4096; **lower number wins** |
| **Direction** | Inbound or Outbound |
| **Action** | Allow or Deny |
| **Protocol** | TCP, UDP, or Any |
| **Port** | e.g. 80, 443, 22 |

### How Rules Are Evaluated

Azure reads rules **top to bottom by priority**. The **first matching rule wins** — Azure stops checking the rest.

Example:

```
Rule 100 → Allow port 80    ✅ Match found, STOP
Rule 200 → Deny port 80     ❌ Never evaluated
```

### Azure's 3 Default Rules (Always Present)

| Priority | Rule |
|---|---|
| **65000** | Allow traffic from inside the VNet |
| **65001** | Allow traffic from Azure Load Balancer |
| **65500** | Deny everything else |

These rules **cannot be deleted**. Your custom rules sit **above** them.

### Layered Security (Subnet NSG + NIC NSG)

When inbound traffic arrives at a VM:

1. Hits the **subnet NSG first**
2. Then the **NIC NSG**

🔑 **Critical rule:** BOTH NSGs must allow the traffic for it to get through. If either denies it, the traffic is blocked.

**Example:**

- Subnet NSG: Deny all at priority 100 → traffic blocked at floor entrance
- NIC NSG: Allow port 80 → never even reached
- **Result: Traffic denied**

### Practical Example — Web Server Setup

To allow HTTP (port 80) and HTTPS (port 443), block everything else:

| Priority | Action | Port |
|---|---|---|
| 100 | Allow | 80 |
| 200 | Allow | 443 |
| 65500 | Deny | All *(Azure default)* |

No explicit deny rule needed — Azure's default handles it.

---

## 📦 Module 4: Route Tables

### What is a Route Table?

Azure has built-in **system routes** that handle routing automatically. A **Route Table** lets you create **custom routes** that override Azure's defaults to send traffic through specific paths.

### Real-World Analogy

Azure's default routing is a **GPS system** for your network traffic. A Route Table is you saying:

> *"Don't take the highway — I want ALL traffic to go through my security checkpoint first."*

### Why Override Default Routing?

The main reason: **force ALL traffic through a security device** (like a firewall) for inspection before it goes anywhere.

This security device in Azure is called a **Network Virtual Appliance (NVA)**.

### Route Components

A custom route answers two questions:

| Field | Meaning |
|---|---|
| **Destination** | Where the traffic is **trying to go** |
| **Next Hop** | Where Azure **actually sends it first** |

### The 3 Most Common Next Hop Types

| Next Hop Type | What It Does |
|---|---|
| **Virtual Appliance** | Send traffic to a firewall/security VM |
| **Internet** | Send traffic out to the public internet |
| **None** | Drop the traffic — block it completely |

### Special Destination: `0.0.0.0/0`

`0.0.0.0/0` is shorthand for **"all possible IP addresses"** — meaning **everything**, including the entire internet.

### Practical Example — Forcing Traffic Through a Firewall

Company wants all internet-bound traffic from web servers to go through a firewall VM first:

| Destination | Next Hop Type | Next Hop Address |
|---|---|---|
| `0.0.0.0/0` | Virtual Appliance | Firewall VM IP |

### Practical Example — Blocking Internet for a Subnet

Database subnet should NEVER reach the internet:

| Destination | Next Hop Type |
|---|---|
| `0.0.0.0/0` | None |

Traffic gets dropped — completely blocked. 🗑️

### System Routes (Azure's Defaults)

Azure automatically creates these in the background:

- ✅ Traffic between subnets in the same VNet
- ✅ Traffic to the internet
- ✅ Traffic to peered VNets

You don't see them or create them — they just exist.

### Custom Routes vs System Routes

🎯 **Custom routes ALWAYS win over system routes.** When you create a custom rule for a destination, Azure ignores its default for that same destination.

---

## 🧠 Mental Models to Remember

| Concept | Quick Memory Hook |
|---|---|
| VNet | Private floor in Azure's office building |
| Subnet | Separate rooms on your floor |
| NSG | Bouncer with a rule list |
| Route Table | Custom GPS directions |
| `0.0.0.0/0` | Everything / the entire internet |
| Lower priority # | Wins the rule conflict |
| 5 reserved IPs | Always taken by Azure per subnet |

---

## ⚠️ Common Pitfalls

1. **Forgetting Azure reserves 5 IPs** — a `/24` gives 251 usable, not 256
2. **Confusing ports with priorities in NSG rules** — port 443 ≠ priority 443
3. **Forgetting subnet NSG is evaluated before NIC NSG** — both must allow
4. **Trying to overlap subnets** — Azure rejects this immediately
5. **Assuming custom routes need ports** — routes are about destinations, not ports (that's NSG territory)

---

## ⏭️ Next Up

- **Module 5:** VNet Peering — connecting VNets across regions
- **Module 6:** Service Endpoints & Private Endpoints
- **Module 7:** VPN Gateway / ExpressRoute
- **Module 8:** DNS in Azure