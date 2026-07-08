# Notes: TCP/IP Model + CIDR Math (Reference Guide)

---

## Module 1: The TCP/IP Model

Four layers, each with one job, stacked and handing off to each other:

```
4. Application    →  What the data MEANS (HTTP, DNS, SSH)
3. Transport      →  Reliable (TCP) vs. fast/best-effort (UDP) delivery
2. Internet       →  Addressing & routing (IP addresses)
1. Network Access →  Physical/electrical delivery (Ethernet, Wi-Fi)
```

**Analogy:** Mailing a package — Application = the letter's content, Transport = shipping method (tracked vs. dropped in a mailbox), Internet = street address/postal routing, Network Access = the truck/plane physically moving it.

**TCP vs UDP**

| | TCP (Transmission Control Protocol) | UDP (User Datagram Protocol) |
|---|---|---|
| Style | Reliable, guarantees delivery | Best-effort, fire-and-forget |
| Order | Guaranteed | Not guaranteed |
| Overhead | Higher (handshakes, ACKs) | Lower |
| Example use | SSH, Docker image pulls | Video/voice calls, DNS |

**Cloud tie-in:** SSH into EC2 = TCP (Transport) + IP addressing (Internet) + virtual NIC (Network Access). Route tables in a VPC/VNet = Internet layer logic.

---

## Module 2: MAC vs. IP Addressing

- **MAC address** — permanent, unique hardware identifier ("serial number") burned into a NIC. Used only for **local, same-network** delivery. Doesn't change if the device's IP changes.
- **IP address** — the device's current network **location**. Can change (e.g., via DHCP).

**DHCP (Dynamic Host Configuration Protocol):** Automatically leases IP addresses to devices joining a network, so they don't need manual configuration. In AWS/Azure, this is what assigns private IPs to instances/VMs launched into a subnet.

**Local delivery:** Two devices on the same network (same Wi-Fi/subnet) talk directly via MAC address — no routing needed.

**Remote delivery (e.g., reaching google.com):**
1. Device can only send frames to devices on its own local network (MAC-layer limitation)
2. So it sends the frame to its **default gateway** (the router)
3. Router inspects the destination **IP**, determines it's remote, and forwards it onward
4. **MAC address changes at every hop**; the **destination IP stays the same** for the entire journey

**Cloud tie-in:** EC2/VM instances send traffic to the subnet's default gateway, which routes it within the VPC/VNet, out to the internet (via Internet Gateway/NAT), or across VPN/peering.

---

## Module 3: Binary Fundamentals

- An IPv4 address = **32 bits**, split into **4 octets** of **8 bits** each.
- Each bit is either 1 or 0. Each additional bit **doubles** the number of possible combinations: `2^N`.
- One octet (8 bits) = `2^8` = **256 combinations**, numbered **0–255** (starts at 0, so max is 255, not 256).

**Bit value chart (memorize this):**
```
128   64   32   16   8   4   2   1
```
To convert binary → decimal, add up the position values wherever there's a `1`.

| Binary | Decimal |
|---|---|
| `10000000` | 128 |
| `11000000` | 192 |
| `11100000` | 224 |
| `11111111` | 255 |
| `00000000` | 0 |

---

## Module 4: Subnet Masks

Every IP address has two parts:
- **Network part** — which network the device is on
- **Host part** — which specific device on that network

A **subnet mask** is a 32-bit number (same 4-octet format as an IP) that marks which bits are network (`1`) vs. host (`0`).

Example: `255.255.255.0`
```
11111111 . 11111111 . 11111111 . 00000000
 (network)   (network)  (network)   (host)
```

**Key insight:** The network/host split doesn't have to land on a clean octet boundary — it can cut through the middle of an octet (e.g., `192` = `11000000` = 2 network bits + 6 host bits within that one octet).

**Counting bits across a full mask:**
`255.255.255.192` = 24 (from first 3 octets) + 2 (from the `192`) = **26 total network bits**

---

## Module 5: CIDR Notation

**CIDR** = Classless Inter-Domain Routing. Shorthand for subnet masks: `/prefix` = number of network bits.

| Subnet Mask | CIDR |
|---|---|
| `255.0.0.0` | `/8` |
| `255.255.0.0` | `/16` |
| `255.255.255.0` | `/24` |
| `255.255.255.192` | `/26` |
| `255.255.255.224` | `/27` |

**Converting CIDR → mask:** the prefix number tells you how many `1`s to fill in from the left, across all 32 bits, then convert each octet back to decimal.

**Cloud tie-in:** This is the exact notation used when creating AWS VPC/subnet CIDR blocks or Azure VNet address spaces (e.g., `10.0.0.0/16`, `10.0.1.0/24`) — no separate subnet mask field needed.

---

## Module 6: Host Count Math

**Formula:**
```
Usable Hosts = 2^(host bits) − 2
```
The `− 2` accounts for two addresses that are always reserved in every subnet:
1. **Network address** — first address in the range (all host bits = 0)
2. **Broadcast address** — last address in the range (all host bits = 1)

**Reference table:**

| CIDR | Host Bits | Usable Hosts |
|---|---|---|
| `/24` | 8 | 254 |
| `/26` | 6 | 62 |
| `/27` | 5 | 30 |
| `/28` | 4 | 14 |

**Working backward (device count → CIDR size):**
1. Find the smallest host-bit count where `2^(host bits) − 2` ≥ required devices
2. CIDR prefix = 32 − host bits

Example: need ≥100 devices → 7 host bits (`2^7 − 2` = 126) → `/25`

**AWS-specific note:** AWS reserves **5** IPs per subnet (not just 2) — network address, broadcast, plus 3 more for internal DNS/routing/future use. A `/28` subnet shows **11** available IPs in the AWS console, not the standard 14.

---

## Module 7 (Advanced): Subnet Ranges & VLSM

For any subnet, four key addresses:

```
Network Address:   first address (all host bits = 0) — reserved
First Usable IP:   network address + 1
Last Usable IP:    broadcast address − 1
Broadcast Address: last address (all host bits = 1) — reserved
```

**Example — `192.168.1.0/24`:**
```
Network:    192.168.1.0
First:      192.168.1.1
Last:       192.168.1.254
Broadcast:  192.168.1.255
```

**Mid-octet split — `192.168.1.0/26`:**
Block size = `2^(host bits) = 2^6 = 64`. The last octet splits into blocks of 64:
```
Block 1:  .0   – .63
Block 2:  .64  – .127
Block 3:  .128 – .191
Block 4:  .192 – .255
```
```
Network:    192.168.1.0
First:      192.168.1.1
Last:       192.168.1.62
Broadcast:  192.168.1.63
```
A fresh `/26` sequence in a **new** octet always restarts at `.0` (e.g., the next block after `192.168.1.255` starts at `192.168.2.0`).

**VLSM — real-world 4-tier VPC design example:**
Splitting `10.0.0.0/24` into 4× `/26` subnets:

```
10.0.0.0/26    → Public Web Tier      (10.0.0.1   – 10.0.0.62)
10.0.0.64/26   → Private App Tier     (10.0.0.65  – 10.0.0.126)
10.0.0.128/26  → Database Tier        (10.0.0.129 – 10.0.0.190)
10.0.0.192/26  → Management/Bastion   (10.0.0.193 – 10.0.0.254)
```
Each subnet: 62 usable hosts, clean boundaries for security groups/NSGs and route tables per tier.

---

## Errors / Corrections Made This Session

- Initially reversed Transport vs. Internet layer responsibilities — corrected via self-check back to Q2
- Miscounted binary-to-decimal addition (`128+64` misread as 292) — corrected by re-reading the bit chart
- Momentarily inverted host-bit pattern for a `/26` last octet (`11110000` instead of `11000000`) — corrected by re-counting 1s
- Skipped straight to a final answer instead of building through `2^7` step-by-step — corrected by isolating the doubling step
- Mixed up network vs. broadcast address as the "start" of a new octet block (`192.168.2.255` vs. `.0`) — corrected by comparing to Block 1's pattern

