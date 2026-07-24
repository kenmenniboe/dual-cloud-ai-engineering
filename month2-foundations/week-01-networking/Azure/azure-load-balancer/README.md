# Azure Load Balancer

Hands-on lab building and testing a Standard Public Load Balancer in Azure — covering every core component: frontend IP, backend pool, health probes, load balancing rules, NAT rules, distribution modes, and outbound rules/SNAT.

## What I Learned

- Azure Load Balancer operates at **Layer 4** (TCP/UDP) — no visibility into HTTP content (that's Application Gateway's job, Layer 7)
- **Public vs. Internal LB** — determined entirely by whether the frontend IP is public or private
- **Standard vs. Basic SKU** — Standard is secure by default (NSG required to allow traffic), supports Availability Zones, HA Ports, and outbound rules; Basic has no SLA and is being retired
- Core LB flow: **Frontend IP → Backend Pool → Health Probe → Load Balancing Rule**
- **NAT Rules** give 1:1 direct access to a specific VM (e.g., SSH) without assigning it a public IP
- **Distribution mode**: 5-tuple hash (default, spreads load) vs. source IP affinity (sticky sessions)
- **Outbound Rules & SNAT**: backend pool VMs behind a Standard LB have **no outbound internet access** without an explicit outbound rule — hit this live mid-lab
- Advanced: **HA Ports** (port=0, all-ports LB for NVAs), **Cross-Region/Global** LB tier for multi-region failover

## Key Outputs / Results

- Deployed `lb-web-demo` (Standard SKU, Public, Regional) with frontend IP `pip-lb-web`
- Backend pool `backend-web-pool`: 2 VMs (`vm-web-1`, `vm-web-2`), no public IPs on either VM
- Load balancing rule `rule-http` (port 80) + health probe `probe-http` (HTTP, path `/`)
- NAT rules for direct SSH management access: `nat-ssh-vm1` (frontend port 50001), `nat-ssh-vm2` (frontend port 50002)
- NSG `nsg-lb-lab` applied at the **subnet** level (not per-NIC) — allows inbound HTTP (80) and SSH (22)
- Verified **5-tuple hash** traffic distribution via repeated `curl` requests to the LB's public IP
- Verified **health probe failover**: stopped nginx on `vm-web-1` → 100% of traffic automatically rerouted to `vm-web-2` within seconds, no manual intervention

### Real troubleshooting win
Hit a genuine outbound connectivity failure (`apt install nginx` timing out) caused by backend pool VMs on a Standard LB losing default outbound internet access. Diagnosed the cause and fixed it by adding an explicit **Outbound Rule** (`outbound-web`) with default SNAT port allocation — confirmed the fix by successfully installing nginx afterward.

## Resources

All lab resources were deployed in a single resource group (`Azure-LB-Demo`) and torn down after the session.