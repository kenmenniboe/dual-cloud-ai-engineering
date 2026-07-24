# Azure Load Balancer — Reference Notes

Here's the roadmap used for this topic:

**Module 1** – What a Load Balancer is & why it exists
**Module 2** – Public vs. Internal Load Balancer
**Module 3** – SKUs (Basic vs. Standard)
**Module 4** – Frontend IP configuration
**Module 5** – Backend pools
**Module 6** – Health probes
**Module 7** – Load balancing rules
**Module 8** – NAT rules (inbound)
**Module 9** – Distribution mode (5-tuple hash vs. session affinity)
**Module 10** – Outbound rules & SNAT
*(Advanced, after the above)* – HA Ports, Cross-Region Load Balancer, Standard vs. Basic in more depth

---

## Module 1 – What a Load Balancer Is & Why It Exists

A Load Balancer sits in front of multiple VMs and gives clients **one single IP/DNS name** to connect to. It distributes incoming traffic across healthy backend VMs and automatically stops sending traffic to any VM that fails a health check.

**Analogy:** A bank with 3 tellers — customers don't pick a line themselves; a single queue directs each customer to the next available, working teller.

**Key fact:** Azure Load Balancer operates at **Layer 4 (Transport)** — it only reads IP address + port. It has no visibility into HTTP content (URL paths, headers, cookies). That's the job of **Application Gateway (Layer 7)**.

| Need | Use |
|---|---|
| Route by IP + port only | Azure Load Balancer (L4) |
| Route by URL path / host header | Application Gateway (L7) |

## Module 2 – Public vs. Internal Load Balancer

Determined by where the **frontend IP** lives:

- **Public LB** — frontend IP is a public IP → internet-facing traffic
- **Internal LB (ILB)** — frontend IP is a private IP inside the VNet → traffic that should never leave the VNet (e.g., web tier → app tier → DB tier)

AWS equivalent: internet-facing vs. internal load balancer.

## Module 3 – SKUs (Basic vs. Standard)

| | Basic | Standard |
|---|---|---|
| SLA | None | 99.99% |
| Backend pool size | Up to 300 | Up to 1,000 |
| Availability Zones | Not supported | Supported (zone-redundant) |
| Security | Open by default | **Secure by default** — NSG required |
| HA Ports | Not supported | Supported |
| Outbound rules | Not supported | Supported |

**Standard is secure by default** — traffic is blocked unless an NSG explicitly allows it. Basic has no SLA and is being retired; use Standard for all new deployments.

## Module 4 – Frontend IP Configuration

The "front door" clients connect to — either a public IP (Public LB) or a private VNet IP (Internal LB). A single LB resource can have **multiple frontend IP configurations**, each potentially routing to different backend pools/rules.

## Module 5 – Backend Pools

The group of VMs (or VMSS instances) that receive traffic. Only members currently passing their **health probe** receive traffic. VMs can differ in size/config as long as they serve the same app on the same port.

AWS equivalent: **Target Group**.

## Module 6 – Health Probes

Periodic checks the LB sends to each backend VM to determine if it should keep receiving traffic.

- **TCP probe** — just checks if a connection can be established (doesn't care about response content)
- **HTTP / HTTPS probe** — sends a GET request to a path, expects a `200 OK`

Key settings: **interval** (how often to check) and **unhealthy threshold** (consecutive failures before marking down). A failed VM stays in the backend pool — it's just temporarily excluded from traffic until it passes probes again.

## Module 7 – Load Balancing Rules

Ties everything together: **frontend IP + port → backend pool + port**, evaluated against a **health probe**. Each frontend port needs its own rule (e.g., separate rules for port 80 and port 443).

AWS equivalent: **Listener + Listener Rule**.

## Module 8 – NAT Rules (Inbound)

A **1:1 mapping** from a specific frontend port to one specific VM's private IP + port — used for direct management access (e.g., SSH/RDP) without giving the VM a public IP. Multiple NAT rules can share the same frontend public IP, differentiated by port.

Example:
- Frontend port 50001 → `vm-web-1` port 22
- Frontend port 50002 → `vm-web-2` port 22

## Module 9 – Distribution Mode (5-Tuple Hash vs. Session Affinity)

- **5-tuple hash (default)** — hashes source IP, source port, dest IP, dest port, protocol. Since source port varies per connection, the *same client* can land on different VMs across separate requests.
- **Source IP affinity (session affinity)** — ignores source port; same client IP always lands on the same VM (useful for local session state, no shared cache).

## Module 10 – Outbound Rules & SNAT

Inbound traffic (client → LB → VM) is separate from **outbound** traffic (VM → internet). Standard LB is secure by default, so backend pool VMs need an explicit **Outbound Rule** to reach the internet.

**SNAT (Source Network Address Translation)** translates the VM's private IP to the LB's public IP for outbound connections. Limited **SNAT ports** are allocated per VM — too many VMs sharing too few ports causes **SNAT port exhaustion**.

AWS equivalent: **NAT Gateway**.

> ⚠️ **Gotcha confirmed live in this lab:** once a VM's NIC joins a Standard LB's backend pool, it loses default outbound internet access entirely unless an explicit Outbound Rule exists — regardless of any subnet-level "default outbound access" setting.

## Advanced – HA Ports, Cross-Region LB, Standard vs. Basic (Deeper Dive)

**HA Ports (High Availability Ports)**
A load balancing rule with port = 0 — load balances *all* TCP/UDP ports through one rule. Used for Network Virtual Appliances (firewalls, virtual routers) that inspect traffic on any port. Internal Standard LB only.

**Cross-Region / Global Load Balancer**
"Tier: Global" sits above multiple **Regional** Standard LBs across Azure regions, routing users to the closest healthy region via Anycast IP — a "load balancer of load balancers" for multi-region redundancy.

**Standard SKU + Availability Zones**
Backend pool VMs must be in the same VNet as the LB. Standard LB + zone-redundant frontend IP lets the LB itself survive a full zone outage, not just individual VM failures.

---

## Lab: Deploy a Standard Public Load Balancer with 2 Backend VMs

**Goal:** stand up a working Load Balancer, watch it distribute traffic across 2 VMs, and see a health probe pull a VM out of rotation.

**Steps:**
1. Create Resource Group
2. Create VNet + subnet
3. Create 2 Linux VMs in that subnet (no public IPs on the VMs themselves)
4. Create the Load Balancer (Standard, Public) — frontend IP, backend pool, health probe, LB rule
5. Configure NSG to allow inbound HTTP (Standard = secure by default, remember)
6. Install a simple web server on each VM that shows the VM's hostname (so we can visually confirm load balancing)
7. Test — hit the LB's public IP repeatedly and watch it bounce between VMs
8. (Bonus) Stop the web server on one VM and watch the health probe pull it out

### Step 1 — Create Resource Group

```
Name: Azure-LB-Demo
Region: <your lab region>
```

### Step 2 — Create VNet + Subnet

```
VNet name: vnet-lb-lab
Address space: 10.0.0.0/16
Subnet name: subnet-vms
Subnet range: 10.0.0.0/24
Private subnet (no default outbound access): UNCHECKED  # see Q&A below
```

### Step 3 — Create 2 Linux VMs (no public IPs)

Repeat twice — `vm-web-1` and `vm-web-2`:

```
Image: Ubuntu Server LTS
Size: B1s (or smallest available)
VNet/Subnet: vnet-lb-lab / subnet-vms
Public IP: None
Public inbound ports: None
```

### Step 4 — Create the Load Balancer

```
Name: lb-web-demo
SKU: Standard
Type: Public
Tier: Regional

Frontend IP:
  Name: frontend-web
  Public IP: create new → pip-lb-web (Standard SKU, Microsoft network routing)

Backend pool:
  Name: backend-web-pool
  Configuration: NIC-based
  VMs: vm-web-1, vm-web-2

Health probe:
  Name: probe-http
  Protocol: HTTP
  Port: 80
  Path: /
  Interval: 5 seconds
  Unhealthy threshold: 2

Load balancing rule:
  Name: rule-http
  Frontend IP: frontend-web
  Backend pool: backend-web-pool
  Protocol: TCP
  Port: 80 → Backend port: 80
  Health probe: probe-http
  Session persistence: None (5-tuple hash)
  Floating IP: Disabled

Inbound NAT rules:
  nat-ssh-vm1: frontend port 50001 → vm-web-1, port 22, TCP
  nat-ssh-vm2: frontend port 50002 → vm-web-2, port 22, TCP

Outbound rules: (leave empty for now — added later, see Problem #3)
```

### Step 5 — Configure NSG (Standard LB = secure by default)

```
NSG name: nsg-lb-lab

Inbound rules:
  Allow-HTTP: Service=HTTP (port 80, TCP), Source=Any, Priority=100, Action=Allow
  Allow-SSH:  Service=SSH  (port 22, TCP), Source=Any, Priority=110, Action=Allow

Associate to: vnet-lb-lab / subnet-vms  (subnet level — not per-NIC)
```

### Step 6 — Install nginx + show hostname (run on each VM)

```bash
ssh -i ~/.ssh/<key-filename> -p 50001 azureuser@<LB_PUBLIC_IP>   # vm-web-1
# then repeat with -p 50002 for vm-web-2

sudo apt update
sudo apt install -y nginx
echo "<h1>Hello from $(hostname)</h1>" | sudo tee /var/www/html/index.html
curl localhost
```

### Step 7 — Test: hit the LB's public IP repeatedly

```bash
# from your local machine
for i in {1..10}; do curl -s http://<LB_PUBLIC_IP>; echo; done
```

Expected: a mix of `Hello from vm-web-1` / `Hello from vm-web-2`, in a **non-alternating** pattern — this is 5-tuple hash at work (source port changes per new `curl` connection, changing which VM the hash lands on).

### Step 8 — Bonus: watch the health probe pull a VM out

```bash
# SSH into vm-web-1 (port 50001)
sudo systemctl stop nginx
```

```bash
# from your local machine — re-run the same loop
for i in {1..10}; do curl -s http://<LB_PUBLIC_IP>; echo; done
```

Expected: **100% of responses now come from `vm-web-2`** — the probe (5s interval, threshold 2) detected the failure and pulled `vm-web-1` out of rotation automatically, with zero manual LB config changes.

```bash
# restore afterward
sudo systemctl start nginx
```

---

## Q&A From the Lab Session

**Q: Do I leave "Enable private subnet (no default outbound access)" checked when creating the subnet?**
A: Leave it **unchecked** at this point — no outbound rule exists on the LB yet, so the VMs need Azure's default outbound access just to run `apt install` during setup.

**Q: Will we come back and check that box once the LB is configured?**
A: Yes — once an explicit Outbound Rule exists, flipping this on is a good way to prove the *rule* (not the legacy default) is what's providing outbound access.

**Q: Can we use a VM Scale Set instead of 2 standalone VMs?**
A: Possible and very production-realistic, but for this lab, 2 standalone VMs were chosen deliberately — it forces every LB piece (frontend, pool, probe, rule) to be wired up manually instead of the Portal auto-configuring it during VMSS creation, which is better for cementing the concepts.

**Q: Is it OK to leave "Public inbound ports" as None during VM creation?**
A: Yes — NSG configuration is handled deliberately later, in Step 5, rather than relying on the VM-creation wizard's defaults.

**Q: What about the Public IP field defaulting to "(new) vm-web-1-ip" during VM creation?**
A: Change it to **None** — backend VMs shouldn't have their own public IP; all access should route through the Load Balancer.

**Q: What does the "Outbound source network address translation (SNAT)" note mean on the LB rule screen?**
A: It's just an informational banner recommending an explicit Outbound Rule — no toggle to set there. The actual outbound rule is configured separately, under the LB's "Outbound rules" tab.

**Q: Do we need an Inbound NAT rule for this lab?**
A: Yes — since the VMs have no public IP, NAT rules are the only way to SSH in for setup and troubleshooting.

**Q: Which SSH syntax is correct — `-p <port>` or `-i <key>`?**
A: Both are required together: `ssh -i ~/.ssh/<key-filename> -p <NAT-port> azureuser@<LB-public-IP>`.

---

## Problems Encountered & Fixes

### Problem 1 — Stray auto-created per-VM NSGs
Creating the VMs with the NIC-level "Basic" NSG option auto-generated separate NSGs per VM (`vm-web-1-nsg`, `vm-web-2-nsg`, plus a stray duplicate `vmweb2nsg925`). These attached at the **NIC** level — a second gate in addition to the intended subnet-level NSG.
**Fix:** Removed the per-VM NSGs entirely so only the single subnet-level `nsg-lb-lab` governs traffic for both VMs.

### Problem 2 — SSH command missing a flag
Tried `ssh -p <port> user@ip` and `ssh -i <path> user@ip` as separate, either-or attempts — neither alone connected successfully.
**Fix:** Combine both flags in one command: `ssh -i ~/.ssh/<key-file> -p <NAT-port> azureuser@<LB-IP>`. Also confirmed `~/.ssh` is a *folder*, not the key itself — ran `ls -la ~/.ssh` to find the actual private key filename.

### Problem 3 — `apt install nginx` timed out (no outbound internet access)
Once `vm-web-1`'s NIC joined the Standard LB's backend pool, outbound internet access stopped working entirely — `apt` couldn't reach `azure.archive.ubuntu.com`, timing out on every attempt.
**Root cause:** Backend pool VMs on a Standard LB have **no outbound path** by default unless an explicit Outbound Rule exists — this overrides whatever the subnet's "default outbound access" setting was.
**Fix:** Added an Outbound Rule (`outbound-web`) on the LB:
```
Name: outbound-web
Frontend IP: frontend-web (pip-lb-web)
Backend pool: backend-web-pool
Protocol: All
Enable default port allocation (not recommended): CHECKED  # simplifies SNAT math for a small lab
```
Retried `sudo apt install -y nginx` — succeeded immediately after the rule propagated (~30–60s).

---

## Quick Reference (For Future Labs)

**Azure ↔ AWS equivalents**

| Azure | AWS |
|---|---|
| Load Balancer (Layer 4) | Network Load Balancer (NLB) |
| Application Gateway (Layer 7) | Application Load Balancer (ALB) |
| Backend Pool | Target Group |
| Load Balancing Rule | Listener + Listener Rule |
| Outbound Rules / SNAT | NAT Gateway |
| Internal LB | Internal-facing LB |
| Public LB | Internet-facing LB |

**Common gotchas to remember**
- Standard SKU = secure by default → always needs an explicit NSG rule to allow anything in
- Backend pool VMs on a Standard LB have **no outbound internet access** without an explicit Outbound Rule
- NIC-level NSGs (auto-created via "Basic" during VM creation) can silently coexist with a subnet-level NSG — check for both if traffic seems unexpectedly blocked
- SSH through a NAT rule needs **both** `-i <key>` and `-p <NAT-port>` — one alone isn't enough
- 5-tuple hash ≠ round robin — don't expect a clean alternating pattern; source port changes per connection drive the distribution

See `commands.md` for a clean, copy-paste command list grouped by workflow stage.

---

## Architecture Diagram

![Azure Load Balancer Lab Architecture](images/lb-architecture.svg)

The diagram shows: client traffic entering via the LB's public IP (`pip-lb-web`), the load balancing rule (`rule-http`) and health probe (`probe-http`) routing HTTP traffic into the backend pool (`backend-web-pool`), inbound NAT rules providing direct SSH access to each VM, the subnet-level NSG (`nsg-lb-lab`) gating all inbound traffic, and the outbound rule (`outbound-web`) providing the VMs' only path back out to the internet via SNAT.