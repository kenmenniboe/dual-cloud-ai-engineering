# Azure Firewall — hub-and-spoke reference notes

AZ-104 lab, built manually (no wizard shortcuts) to understand the pieces individually.

---

## 0. Step-by-step build order (portal navigation)

Built in this exact sequence. Concepts and settings behind each step are detailed in the sections below.

### 1. Create Hub-VNet
- Portal → Virtual networks → **+ Create**
- Name: `Hub-VNet`
- Address space: `10.0.0.0/16`
- Subnets: skip/remove the default
- Review + Create

### 2. Add `AzureFirewallSubnet`
- `Hub-VNet` → Subnets → **+ Subnet**
- Name: `AzureFirewallSubnet`
- Address range: `10.0.1.0/26`
- Private subnet: off
- NAT gateway / NSG / route table: none
- Save

### 3. Deploy Azure Firewall
- Portal → Firewalls → **+ Create**
- Resource group / region: same as Hub-VNet
- Tier: `Standard`
- Firewall management: Use a Firewall Policy → **Add new**
- Policy name: `hub-fw-policy`
- Virtual network: use existing → `Hub-VNet`
- Public IP: Add new (Standard SKU)
- Firewall Management NIC: off
- Review + Create (~5–10 min deploy)

### 4. Create Spoke-VNet
- Virtual networks → **+ Create**
- Name: `Spoke-VNet`
- Address space: `10.1.0.0/16`
- Subnet: `workload-subnet` — `10.1.1.0/24`
- Private subnet: off
- Review + Create

### 5. Peer Hub ↔ Spoke
- `Hub-VNet` → Peerings → **+ Add**
- Peering link names: `Hub-to-Spoke` / `Spoke-to-Hub`
- Remote virtual network: `Spoke-VNet`
- On **both** sides:
  - Allow access: ON
  - **Allow forwarded traffic: ON**
  - Gateway/route server options: OFF
- Add

### 6. Create route table, add route, associate to spoke subnet
- Route tables → **+ Create**
- Name: `spoke-to-firewall-rt`
- Resource group / region: same as before
- Create
- Open it → Routes → **+ Add**
  - Name: `default-to-firewall`
  - Destination type: IP Addresses
  - Destination CIDR: `0.0.0.0/0`
  - Next hop type: Virtual appliance
  - Next hop address: Firewall's **private IP**
- Same route table → Subnets → **+ Associate**
  - Virtual network: `Spoke-VNet`
  - Subnet: `workload-subnet`

### 7. Add the Application rule
- Firewall Policy `hub-fw-policy` → Application rules
- Open `DefaultApplicationRuleCollectionGroup`
- **+ Add a rule collection**
  - Name: `allow-updates`
  - Priority: `100`
  - Rule collection action: Allow
- Rule inside it:
  - Source type: IP Address
  - Source: `10.1.0.0/16`
  - Protocol: `https:443,http:80`
  - Destination type: FQDN
  - Destination: `ubuntu.com,*.ubuntu.com`
- Save

### 8. Add `AzureBastionSubnet` (in Hub-VNet)
- `Hub-VNet` → Subnets → **+ Subnet**
- Name: `AzureBastionSubnet`
- Address range: `10.0.2.0/26`
- Same off/none settings as step 2
- Save

### 9. Deploy Azure Bastion
- Bastions → **+ Create**
- Name: `hub-bastion`
- Tier: `Standard` (required to reach peered VNets)
- Virtual network: `Hub-VNet`
- Public IP: Add new (Standard SKU)
- Review + Create (~5–10 min deploy)

### 10. Deploy the test VM
- Virtual machines → **+ Create**
- Name: `test-vm`
- Image: Ubuntu Server
- Size: B1s
- Networking:
  - Virtual network: `Spoke-VNet`
  - Subnet: `workload-subnet`
  - Public IP: None
  - Public inbound ports: None
- Authentication: SSH public key → generate new RSA key pair
- Download the `.pem` when prompted — only chance to get it
- Review + Create

### 11. Connect and test
- `test-vm` → Connect → Bastion
- Upload the `.pem` (check `~/Downloads` if not moved)
- Connect
- Run the `curl` tests from `commands.md`

---

## 1. Why Azure Firewall exists (vs. NSGs)

NSGs filter by **IP / port / protocol** only. That breaks down for services behind a **CDN**, where the IP behind a domain (e.g. `*.windowsupdate.com`) changes constantly.

Azure Firewall adds **FQDN filtering** — write a rule like `allow *.ubuntu.com` and the Firewall matches on the domain name itself, regardless of which IP currently answers for it.

| Term | Meaning |
|---|---|
| NSG | Network Security Group — IP/port filtering, per subnet or NIC |
| FQDN | Fully Qualified Domain Name (e.g. `www.ubuntu.com`) |
| CDN | Content Delivery Network — distributed servers, IP changes often |
| NIC | Network Interface Card — a VM's virtual network adapter |

**How FQDN matching actually works (HTTPS):** Azure Firewall reads the **SNI (Server Name Indication)** field in the TLS "Client Hello" — the one piece of plaintext visible even before encryption kicks in. It never decrypts the payload (Standard tier). For HTTP, it reads the plaintext **Host header** instead.

> ⚠️ **Gotcha:** `*.ubuntu.com` matches subdomains only — **not** the bare `ubuntu.com`. List both if you want to cover the apex domain and all subdomains:
> ```
> ubuntu.com,*.ubuntu.com
> ```
> (no spaces around the comma — Azure can misparse the entry otherwise)

---

## 2. Hub-and-spoke topology

- **Hub VNet** — shared infrastructure: Firewall, Bastion, (Gateway if needed). Built once.
- **Spoke VNets** — actual workloads. Peer to the Hub, not to each other directly.
- Traffic between spokes (or out to internet) is forced **through the hub** so the Firewall can inspect it.

![Screenshot: hub-and-spoke diagram](screenshots/hub-spoke-diagram.png)

**Address plan used:**
| VNet | Range |
|---|---|
| Hub-VNet | `10.0.0.0/16` |
| `AzureFirewallSubnet` | `10.0.1.0/26` |
| `AzureBastionSubnet` | `10.0.2.0/26` |
| Spoke-VNet | `10.1.0.0/16` |
| `workload-subnet` | `10.1.1.0/24` |

Use `/16` at the VNet level so there's room to add subnets later without redesigning addressing.

---

## 3. Reserved-name subnets

Two special subnets, both **exact, case-sensitive names**, both need **/26 minimum** (Azure enforces this, not just recommends it):

- `AzureFirewallSubnet` — hosts Azure Firewall
- `AzureBastionSubnet` — hosts Azure Bastion

**For both subnets, leave these off/empty:**
- "Enable private subnet (no default outbound access)" → **unchecked** (both Firewall and Bastion need their own outbound path — Firewall to act as egress point, Bastion for cert checks/management traffic)
- NAT gateway → none
- Network security group → **none** (an NSG on `AzureFirewallSubnet` can block Firewall's own management traffic)
- Route table → none (route tables go on **workload** subnets, not these)
- Service endpoints / subnet delegation / private endpoint policy → all default/empty

Regular workload subnets (e.g. `workload-subnet`) have no naming restriction — name them anything.

![Screenshot: subnet creation form](screenshots/subnet-create.png)

---

## 4. VNet peering — the "forwarded traffic" gotcha

Peering is bidirectional — each side configures independently (portal does both in one step).

| Setting | Value | Why |
|---|---|---|
| Allow 'X' to access 'Y' | ON | Basic handshake |
| **Allow 'X' to receive forwarded traffic from 'Y'** | **ON** | Required — see below |
| Allow gateway/route server to forward traffic | OFF | No gateway in this lab |
| Enable use of remote gateway/route server | OFF | No gateway in this lab |

**Why forwarded traffic matters:** a packet from Spoke-A keeps Spoke-A's IP as its source, even after Azure Firewall forwards it toward Spoke-B. When it arrives at Spoke-B via the Hub peering link, Spoke-B checks whether the source matches a direct peer. It doesn't (source = Spoke-A, path = via Hub) — so without "allow forwarded traffic" enabled, the packet is silently dropped. This must be ON on both sides of every peering in a hub-spoke-with-firewall design.

![Screenshot: peering settings both sides](screenshots/peering-settings.png)

---

## 5. Forced tunneling (Route Table / UDR)

Without this, spoke traffic goes straight to the internet, bypassing the Firewall entirely.

**Steps:**
1. Create a Route Table (e.g. `spoke-to-firewall-rt`)
2. Add a route:
   - Destination: `0.0.0.0/0` (everything)
   - Next hop type: **Virtual appliance**
   - Next hop address: Firewall's **private IP** (not public — next hop must be reachable inside the VNet)
3. **Associate** the route table to the workload subnet (an unattached route table does nothing)

"Enable peering routes" toggle on the route table → leave at default/enabled. Peering routes are more specific (longer prefix) than `0.0.0.0/0`, so **longest prefix match** means your forced-tunnel route still wins for general traffic without blocking direct peer reachability.

![Screenshot: route table config](screenshots/route-table.png)

---

## 6. Azure Firewall deployment

- Needs a **public IP** (Standard SKU) — used as the source IP when forwarding traffic out to the internet, even though it's inspecting internal traffic.
- **Firewall Management NIC** (Force Tunneling option) → leave **disabled** unless routing the firewall's own traffic through an on-prem network via VPN. Not needed for this lab.
- Tier used: **Standard** (FQDN rules, threat intel — no TLS inspection needed, that's Premium-only).

---

## 7. Firewall Policy rule hierarchy

Three levels, not two:

```
Rule Collection Group   (folder — has its own priority)
  └─ Rule Collection    (sub-folder — action: Allow/Deny, priority)
       └─ Rule          (the actual match condition)
```

Azure **pre-creates three default Rule Collection Groups** per policy (`DefaultApplicationRuleCollectionGroup`, `DefaultNetworkRuleCollectionGroup`, `DefaultDnatRuleCollectionGroup`) — no need to manually create a group before adding a rule collection into it.

**Processing order (fixed, regardless of priority number):** DNAT → Network → Application rules, always in that order. Priority numbers only control ordering *within* the same rule type.

**Rule collection type used:** Application
**Example rule:**
| Field | Value |
|---|---|
| Source type | IP Address |
| Source | `10.1.0.0/16` |
| Protocol | `https:443,http:80` |
| Destination type | FQDN |
| Destination | `ubuntu.com,*.ubuntu.com` |
| TLS inspection | Off (Standard tier doesn't support it) |

![Screenshot: application rule collection](screenshots/app-rule.png)

---

## 8. Test VM + Azure Bastion

- Test VM deployed with **no public IP** — forced-tunnel routing is the only outbound path, by design.
- "Public inbound ports" on VM create wizard → **None** (Bastion handles access, no need to open SSH/RDP to the internet).
- SSH auth: key pair, RSA, Azure auto-generates and lets you download the private key **once** — save it (it lands in `~/Downloads` by default on Mac, not `~/.ssh`).
- **Bastion tier: Standard** — Basic tier only connects to VMs in its *own* VNet; Standard is required to reach VMs in a peered VNet.
- Deployed Bastion in the **Hub-VNet** (Microsoft's recommended pattern) rather than in each spoke — one Bastion, reusable across all future spokes via peering.

**Mac tip:** `.ssh` is a hidden folder in Finder. Jump to it with `Cmd+Shift+G` → type `~/.ssh`, or toggle all hidden files with `Cmd+Shift+.`

![Screenshot: Bastion connect panel](screenshots/bastion-connect.png)

---

## 9. Validation — proving the whole chain works

From the test VM (connected via Bastion):

```bash
curl -v https://ubuntu.com   # first attempt FAILED — SSL_ERROR_SYSCALL (apex domain not covered by wildcard-only rule)
# fixed rule to include both ubuntu.com and *.ubuntu.com
curl -v https://ubuntu.com   # succeeded after fix
curl -v http://ubuntu.com    # succeeded — 301 redirect to https
curl -v https://github.com   # failed as expected — SSL_ERROR_SYSCALL, no matching rule (deny by default)
```

**What the failure pattern tells you:** TCP connects fine every time ("Connected to ... port 443") — the block always happens right after **TLS Client Hello**. That's the Firewall reading the SNI, checking it against Application rules, and cutting the connection if there's no match. A clean end-to-end result (full HTTP response, "Connection left intact") means the rule matched; a `SSL_ERROR_SYSCALL` right after Client Hello means it didn't.

**Result: full chain confirmed.**
1. Spoke traffic forced through Hub Firewall (UDR) ✅
2. Allowed FQDN passes ✅
3. Unlisted FQDN blocked by default ✅