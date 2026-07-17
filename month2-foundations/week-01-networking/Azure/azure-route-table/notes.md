# Azure Route Table (UDR) — Reference Notes

## 1. What Problem Does a Route Table Solve?

Azure automatically routes traffic between subnets, VNets, and the internet using
**system routes**. A **Route Table** lets you override that default behavior —
telling Azure "for this destination, send traffic somewhere specific instead"
(e.g., through a firewall NVA, or nowhere at all).

## 2. Key Terminology

| Term | Created By | Description |
|---|---|---|
| **System route** | Azure (automatic) | Built-in routing rules — VNet traffic, internet-bound traffic, peering traffic |
| **Default route** | Part of system routes | The catch-all rule `0.0.0.0/0` — unmatched traffic goes to the internet by default |
| **Custom route (UDR)** | You | A rule you manually add to override system/default behavior |

**UDR = User Defined Route** — the individual rule inside a Route Table.
**Route Table** = the container/resource that holds one or more UDRs.

## 3. NVA (Network Virtual Appliance)

A VM that acts like a network device (firewall, router, load balancer) via
software instead of dedicated hardware. Common example: a firewall NVA sitting
between subnets, inspecting traffic before it's allowed through.

## 4. Route Table Use Cases

| Use Case | What It Solves |
|---|---|
| **Custom network routes** | General capability — override Azure's default routing |
| **Redirect traffic to an NVA firewall** | Traffic already has a path; you force it through inspection first |
| **Enable spoke-to-spoke communication** | Traffic has *no path at all* by default (VNet peering alone doesn't allow Spoke1 → Spoke2 through the Hub) — a UDR creates that path |

> Key distinction: NVA redirection = "inspect traffic on an existing path."
> Spoke-to-spoke = "create a path that doesn't exist yet."

## 5. Route Table Creation — Field Notes

- **Subscription / Resource Group / Region** — Region must match the VNet/subnet you'll associate it to
- **Name** — e.g., `rt-demo-01`
- **Propagate gateway routes** (Yes/No) — controls whether routes learned from an
  on-premises network (via VPN/ExpressRoute Gateway) are automatically added to
  this Route Table.
  - **Yes** → subnet learns on-prem routes automatically
  - **No** → on-prem routes blocked; useful when you want only your UDRs controlling traffic
  - Not relevant when there's no VPN/ExpressRoute Gateway involved (as in this lab)

[screenshot: Route Table creation — Basics tab]

## 6. Next Hop Type — Full Reference

| Next Hop Type | Behavior |
|---|---|
| **Virtual network gateway** | Sends traffic to a VPN/ExpressRoute gateway (on-prem connectivity) |
| **Virtual network** | Sends traffic to another VNet/subnet directly (spoke-to-spoke, peering) |
| **Internet** | Sends traffic straight to the internet (default behavior already) |
| **Virtual appliance** | Sends traffic to an NVA (firewall VM) — requires entering the NVA's private IP |
| **None** | Drops traffic completely — a "black hole" |

[screenshot: Add route — Next hop type dropdown]

## 7. Lab Walkthrough

### Step 1 — Create the Route Table
Portal → Route table → + Create → fill Subscription/RG/Region/Name → Create.

### Step 2 — Create a fresh VNet
Portal → Virtual networks → + Create → name (`vnet-routetable-demo`) →
default address space `10.0.0.0/16`, one subnet `default` (`10.0.0.0/24`).

### Step 3 — Create a VM in that VNet
Portal → Virtual machines → + Create:
- Same Resource Group/Region as VNet
- Ubuntu Server image, small size (B1s)
- SSH authentication
- Networking tab → select the new VNet/subnet → Public IP = Yes
- Skipped **Custom Data / cloud-init** (not needed for a simple ping/SSH test —
  Ubuntu has ping and basic networking tools built in by default)

[screenshot: VM creation — Networking tab]

### Step 4 — Baseline test (before Route Table applied)
SSH into the VM:
```bash
ssh -i /path/to/your-key.pem azureuser@<VM_PUBLIC_IP>
```
Test internet connectivity:
```bash
ping -c 4 8.8.8.8
```
`8.8.8.8` = Google Public DNS — used because it's always online, reliably
responds to ping, and is a well-known test target.

**Result:** 0% packet loss — VM has full internet access (baseline confirmed).

### Step 5 — Add the "black hole" UDR
Route Table → Settings → Routes → + Add:
- **Route name:** `block-internet`
- **Destination type:** IP Addresses
- **Destination IP addresses/CIDR ranges:** `0.0.0.0/0`
- **Next hop type:** `None`

[screenshot: Route created — block-internet]

### Step 6 — Associate the Route Table to the subnet
Route Table → Settings → Subnets → + Associate → select VNet + `default` subnet → OK.

> A Route Table has no effect until it's associated with a subnet.

### Step 7 — Re-test (after Route Table applied)
```bash
ping -c 4 8.8.8.8
```
**Result:** SSH session itself disconnected —
`Read from remote host <public-ip>: Operation timed out` / `Broken pipe`.

**Why:** The SSH connection's return traffic also has to leave the VNet via
`0.0.0.0/0`, which is now set to `None`. The block affects **all** outbound
traffic, not just ICMP — proving the UDR works even more convincingly than a
simple failed ping.

## 8. Route Tables vs. NSGs — Important Distinction

**Question raised:** Can a Route Table block ping but still allow SSH?

**Answer: No.** Route Tables make decisions based on **destination IP only** —
they cannot distinguish protocols or ports (ping vs. SSH vs. HTTP, etc.).

To block ping specifically while allowing SSH, you need an **NSG**, which filters by:
- Protocol (TCP/UDP/ICMP)
- Port number
- Source/destination

**Summary distinction:**
- **Route Table** → controls *where* traffic goes
- **NSG** → controls *what type* of traffic is allowed

## 9. Cleanup

Deleted the Resource Group to remove all lab resources at once (VNet, VM,
Route Table, NIC, disk, public IP, SSH public key resource).

**Note on SSH keys:** Deleting the RG removes the **public key resource** in
Azure (it belongs to the RG), but your local `.pem` private key file is
untouched. Tip: keep `.pem` files in a dedicated local folder
(e.g., `~/azure-lab-keys/`) since Azure-side key resources are disposable but
local keys are not automatically backed up.