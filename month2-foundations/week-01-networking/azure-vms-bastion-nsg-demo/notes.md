# Notes: Azure VMs, Bastion & NSG Lab

**Date:** Thu Jun 11, 2026
**Folder:** `thu-jun-11-azure-vms-bastion-nsg`

---

## Concepts Covered

### Azure Bastion
- A managed PaaS service that provides secure RDP/SSH access to VMs **without exposing public IPs**
- Lives in its own dedicated subnet: `AzureBastionSubnet` (exact name required)
- Subnet must be `/26` or larger
- Connects via the Azure Portal browser or native RDP client (if Native client support is enabled)
- Standard tier supports native client, shareable links, session recording, and more

### Network Security Groups (NSGs)
- Act as a firewall ruleset attached to a **subnet** or **NIC**
- Evaluate rules by **priority number** — lower number = evaluated first
- Default rules (cannot be deleted):
  - `AllowVnetInBound` (65000) — allows traffic within the VNet
  - `AllowAzureLoadBalancerInBound` (65001)
  - `DenyAllInBound` (65500) — denies everything else
  - `AllowVnetOutBound` (65000)
  - `AllowInternetOutBound` (65001)
  - `DenyAllOutBound` (65500)
- Azure auto-creates an NSG per VM NIC when deploying VMs

### Two-Layer Security Model
- **NSG** = Azure network layer (controls what traffic reaches the VM)
- **Windows Firewall** = OS layer (controls what the OS accepts)
- **Both** must allow traffic for communication to succeed
- ICMP (ping) is blocked by Windows Firewall by default even if NSG allows it

---

## Step-by-Step Lab Walkthrough

### Step 1: Create Resource Group
- Name: `rg-bastion-lab`
- Region: Central US *(East US had capacity issues for Bastion)*

> 📸 *Screenshot placeholder: Resource Group overview page*

---

### Step 2: Create Virtual Network
- Name: `vnet-bastion-lab`
- Address space: `10.0.0.0/16`
- Rename default subnet to `snet-vms`, range `10.0.1.0/24`
- Do NOT add Bastion subnet yet

> 📸 *Screenshot placeholder: VNet IP address configuration*

---

### Step 3 & 4: Create VM-1 and VM-2
- Image: Windows Server 2022 Datacenter
- Size: Standard_B1s
- Availability: No infrastructure redundancy required
- Security type: Trusted launch (default)
- Public inbound ports: None (select RDP 3389 to satisfy form)
- Networking:
  - VNet: `vnet-bastion-lab`
  - Subnet: `snet-vms`
  - Public IP: **None**
- Azure auto-creates `vm-1-nsg` and `vm-2-nsg` attached to each NIC

> 📸 *Screenshot placeholder: VM networking tab showing no public IP*

---

### Step 5: Add AzureBastionSubnet
- Go to `vnet-bastion-lab` → Subnets → + Subnet
- Name: `AzureBastionSubnet` *(exact spelling and capitalization required)*
- Range: `10.0.2.0/26`

> ⚠️ If the name is wrong, Bastion deployment will fail

> 📸 *Screenshot placeholder: Subnet list showing AzureBastionSubnet*

---

### Step 6: Deploy Azure Bastion
- Name: `bastion-lab`
- Region: Central US
- Tier: Standard
- VNet: `vnet-bastion-lab`
- Subnet: auto-selects `AzureBastionSubnet`
- Public IP: use existing `pip-bastion-lab`
- Instance count: 1
- Enable **Native client support** after deployment via Configuration blade

> 📸 *Screenshot placeholder: Bastion overview page showing connected VNet*

---

### Step 7: Connect via Bastion
- Go to VM → Connect → Bastion
- Connection type: Native client (RDP)
- Enter username/password
- Opens RDP session through secure tunnel — no public IP on VM needed

> 📸 *Screenshot placeholder: Bastion connection screen*

---

### Step 8: Test VM-to-VM Connectivity

**Enable ICMP on Windows Firewall (both VMs):**
```powershell
# Allow inbound ICMP
netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4:8,any dir=in action=allow

# Allow outbound ICMP
netsh advfirewall firewall add rule name="Allow ICMPv4 Outbound" protocol=icmpv4:8,any dir=out action=allow
```

**Ping from vm-1 to vm-2:**
```powershell
ping 10.0.0.5
```

> ✅ Should succeed — `AllowVnetInBound` default rule permits intra-VNet traffic

---

### Step 9: Block Ping with NSG Rule

Added inbound deny rule to `vm-2-nsg`:
- Source: IP Address `10.0.0.4` (vm-1)
- Protocol: ICMP
- Action: Deny
- Priority: 300
- Name: `Deny-ICMP-vm1`

> ✅ Ping from vm-1 to vm-2 now times out

> 📸 *Screenshot placeholder: NSG inbound rules showing custom Deny-ICMP rule*

---

### Step 10: Allow Ping from vm-2 to vm-1

Added inbound allow rule to `vm-1-nsg`:
- Source: IP Address `10.0.0.5` (vm-2)
- Protocol: ICMP
- Action: Allow
- Priority: 300
- Name: `Allow-ICMP-vm2`

> ✅ Ping from vm-2 to vm-1 succeeds after also enabling Windows Firewall ICMP rules

---

## Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| Bastion deployment failed (Conflict) | Subnet too small or wrong name | Verified `AzureBastionSubnet` at `/26` |
| Bastion capacity error (East US) | Region capacity constraint | Rebuilt everything in Central US |
| Public IP quota exceeded | Free tier limit of 3 public IPs | Used existing `pip-bastion-lab` |
| Ping timeout despite NSG allow | Windows Firewall blocking ICMP | Added firewall rules via `netsh` |
| Wrong VM private IP (`10.0.1.5`) | Assumed IP, didn't verify | Checked actual IP in portal (`10.0.0.5`) |

---

## Exam Tips (AZ-104)

- Bastion subnet **must** be named `AzureBastionSubnet` — exact match
- Bastion subnet minimum size is `/26`
- NSG rules evaluated by priority — **lower number wins**
- Default `DenyAllInBound` at priority 65500 is always last
- NSGs can be attached to subnet OR NIC (or both)
- NSG + OS firewall are independent — both must allow traffic