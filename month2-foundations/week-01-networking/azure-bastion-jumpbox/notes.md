# Notes — Azure Bastion + Jumpbox VM

## Core Concept
Azure Bastion = managed jump box service, similar in *purpose* to the AWS bastion host pattern (SG-to-SG trust, SSH relay to private RDS), but different in *mechanism*:

| | AWS-style bastion (built earlier) | Azure Bastion |
|---|---|---|
| Access point | EC2 with public IP, SSH | Portal browser session (HTTPS) |
| Target exposure | Target has no public IP | Target VM has no public IP |
| Managed by | You (self-hosted) | Microsoft (PaaS) |

## AzureBastionSubnet — Rules
- Name must be **exactly** `AzureBastionSubnet` (case-sensitive, reserved) — same pattern as `GatewaySubnet` for VPN Gateways
- Minimum size: **/26** (64 addresses) — anything larger (e.g. /24) also works; anything smaller (/27, /28, /29, /30) is rejected
- Dedicated exclusively to the Bastion resource — a VM cannot be placed in it

## Why Bastion Needs a Public IP (but the VM doesn't)
Something has to be the internet-reachable front door. Bastion is purpose-built and hardened for that exposure, so workload VMs never need to be.

## VM Networking Settings
- **Public IP:** None
- **Public inbound ports:** None
  - Selecting "Allow selected ports → RDP (3389)" here creates a dormant NSG rule — no risk *today* (no public IP to receive traffic), but becomes a live exposure if a public IP is ever attached later. Don't create rules "just in case."

## Connection Flow (Connect → Bastion)
1. VM Overview → Connect → Bastion
2. Enter credentials (password or SSH key)
3. Browser opens an HTML5 session over HTTPS/TLS via the Portal
4. Bastion relays RDP/SSH traffic internally over the VNet — no public IP touched, no RDP client needed

## Step-by-Step: How It Was Built

### Step 1 — Create VNet with Bastion (one-step method)
1. Portal → search **Virtual networks** → **+ Create**
2. **Basics tab:** Resource Group, VNet name, Region
3. **IP Addresses tab:**
   - VNet address space, e.g. `10.0.0.0/16`
   - Add regular subnet, e.g. `10.0.1.0/24` (for the VM)
4. **Security tab:**
   - Check **Enable Bastion**
   - Choose SKU: **Basic**
   - Bastion auto-creates `AzureBastionSubnet` (default /26) and assigns it a public IP
5. **Review + Create** → Create
6. Wait ~5–10 minutes for Bastion to finish deploying

### Step 2 — Create the VM (no public IP)
1. Portal → search **Virtual machines** → **+ Create**
2. **Basics tab:** Resource Group, Region (match VNet), image, size, admin username/credentials
3. **Networking tab:**
   - Virtual network: select the VNet from Step 1
   - Subnet: select the **regular** subnet (not AzureBastionSubnet)
   - Public IP: **None**
   - Public inbound ports: **None**
4. **Review + Create** → Create
5. Wait for deployment to finish

### Step 3 — Connect via Bastion
1. Go to the VM's **Overview** page
2. Click **Connect** → **Bastion**
3. Enter VM credentials (username/password or SSH key)
4. Click **Connect**
5. Browser opens an HTML5 session (RDP/SSH) directly in the Portal — no client software needed

## Exam Traps to Remember
- Reserved subnet name: `AzureBastionSubnet` (not "BastionSubnet")
- Minimum subnet size: `/26`
- VM public inbound ports should be **None** when using Bastion
- Bastion subnet is exclusive — no other resources allowed in it

## Two-Step Method (for comparison, not used this session)
1. Create `AzureBastionSubnet` manually on the VNet
2. Create Bastion resource separately → select VNet → Azure auto-detects the subnet → assign public IP → deploy

Functionally identical to the one-step checkbox; two-step just makes each dependency visible.

