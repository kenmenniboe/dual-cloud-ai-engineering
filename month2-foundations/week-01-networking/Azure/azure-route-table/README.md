# Azure Route Table (UDR) Demo — AZ-104

## What I Learned
- What a Route Table is and how it overrides Azure's default (system) routing
- The difference between System Routes, Default Routes, and Custom Routes (UDRs)
- Real-world use cases for Route Tables: custom routing, forcing traffic through an NVA firewall, enabling spoke-to-spoke communication in Hub-and-Spoke
- What an NVA (Network Virtual Appliance) is
- The "Propagate gateway routes" setting on Route Table creation
- How to build and test a Route Table from scratch using a "black hole" route (`0.0.0.0/0 → Next hop: None`)
- Confirmed that Route Tables filter by **destination IP only** — not protocol/port (that's an NSG's job)

## Lab Summary
Built a fresh environment to test Route Table behavior:
1. VNet + subnet (`vnet-routetable-demo`)
2. VM (`vm-routetable-test`) with public IP for testing
3. Route Table with one UDR: `0.0.0.0/0 → None`
4. Associated Route Table to the subnet

## Key Result
- **Before** route association: `ping 8.8.8.8` succeeded (0% packet loss)
- **After** route association: all outbound traffic — including the active SSH session — was dropped, causing SSH to disconnect with a timeout
- This confirmed the UDR was actively blocking **all** outbound traffic (not just ping), since Route Tables don't distinguish by protocol/port

## Cleanup
Resource Group deleted after testing (per usual lab workflow).