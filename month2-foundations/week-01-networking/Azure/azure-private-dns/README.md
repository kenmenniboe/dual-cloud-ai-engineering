# Azure Private DNS Zone — AZ-104 Lab

**Topic:** Azure Private DNS Zones — concepts + hands-on Portal lab
**Cert track:** AZ-104

## What I Learned

- **Core concept:** a Private DNS Zone resolves names only within VNets it's explicitly linked to — never from the public internet.
- **Naming rules:** Azure blocks zone names that collide with reserved platform domains (`azure.com`, `windows.net`, `microsoft.com`, `trafficmanager.net`, `core.windows.net`).
- **Record types:** an **A record** points to a fixed IP; a **CNAME record** points to another name and automatically follows changes to that target.
- **VNet Links** are required before any VM can resolve a zone — **VNet peering does NOT automatically share DNS zone links.**
- **Auto-registration** automatically creates/updates A records for VMs in a linked VNet.
- **AWS anchor:** Private DNS Zone ≈ Route 53 **Private Hosted Zone**; VNet Link ≈ **VPC Association**; Azure's auto-registration has no built-in AWS equivalent (closest is **AWS Cloud Map**).

## Hands-On Results

Built end-to-end in the Azure Portal:

1. `rg-dns-lab` → `vnet-dns-lab` (`10.0.0.0/16`) with `default` (`10.0.0.0/24`) and `AzureBastionSubnet` (`10.0.1.0/26`) subnets
2. VM (no public IP) + Azure Bastion for secure access
3. Private DNS Zone `internal.corp`, linked to `vnet-dns-lab` at creation time (auto-registration **on**)
4. Records added: `app1` (A → `10.0.0.4`), `app2` (CNAME → `microsoft.com`)

**Verified live from the VM via Bastion:**

| Command | Result |
|---|---|
| `nslookup app1.internal.corp` | Resolved directly to `10.0.0.4` (A record) |
| `nslookup app2.internal.corp` | Resolved through the CNAME chain to `microsoft.com` → `150.171.109.183` (A) + IPv6 (AAAA) |

No Portal validation errors occurred this session — every step passed validation on the first attempt.

## Next Steps

- (Optional) Revisit the Terraform version of this lab later for an extra IaC rep — skipped this session since Terraform fundamentals are already solid from prior labs
- Tear down `rg-dns-lab` once done, per usual workflow

See `notes.md` for the full tutorial + step-by-step redo guide, and `commands.md` for every CLI command used.