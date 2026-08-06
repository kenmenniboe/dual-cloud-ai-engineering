# Azure Virtual Network Service Endpoint — Azure Storage

## What I Learned

Continuation of AZ-104 networking prep, following directly from the Private Endpoint lab. This session covered **Virtual Network Service Endpoints**, using Azure Storage as the target service.

**Concepts covered:**
- How Service Endpoint routing works: optimized Azure-backbone route + VNet/subnet identity-based trust — **no NIC, no private IP, no new resource created anywhere**
- Source IP preservation: the VM's own private IP is used as-is, no NAT involved
- The 2-step configuration pattern: enable on the subnet → restrict the resource to that subnet

- **Service Endpoint vs. Private Endpoint** design tradeoffs: pricing (free vs. metered), data exfiltration protection (none vs. yes), on-prem access (no vs. yes), regional scope (regional vs. agnostic), and Microsoft's stated strategic direction (actively investing in Private Link, not Service Endpoints)

- **Service Endpoint Policies**: a Storage-only add-on that restricts *which specific resource instances* a subnet can reach — closes the "any storage account that trusts my VNet" exfiltration gap (not used this lab, since demonstrating exfiltration risk wasn't the goal)

- A platform-level networking change: Azure subnets created after March 31, 2026 default to **"private subnet" (no default outbound internet access)** — and confirmed that this does **not** block Service Endpoint traffic, since it uses a distinct routing path (`VirtualNetworkServiceEndpoint` next hop)

**Hands-on lab:** built the full open → locked-down lifecycle for Azure Storage, including a deliberate negative test proving identity-based (not IP-based) trust.

> [!NOTE]
> No Terraform this session either — Portal only, consistent with the Private Endpoint lab.

## Key Outputs / Results

| Test | Result |
|---|---|
| Public access (before lockdown) | ✅ Confirmed reachable from local machine via SAS URL |
| Service Endpoint enabled on subnet | ✅ `Microsoft.Storage` added — no new resource created |
| Storage account locked to selected networks | ✅ Only `snet-app` + whitelisted local IP trusted |
| Access from jumpbox via Service Endpoint | ✅ `curl` to SAS URL succeeded — optimized backbone route, same public IP throughout |
| Negative test — IP rule removed | ✅ Local machine → `AuthorizationFailure`; jumpbox (subnet identity) → still succeeded |

**Resources built:** VNet + subnets (private subnet, no NAT Gateway needed), Bastion, Ubuntu jumpbox VM, Storage Account (Standard/LRS) + `content` container, Service Endpoint on `snet-app`, storage firewall locked to selected networks.

See `notes.md` for the full tutorial/reference guide and `commands.md` for every command used.