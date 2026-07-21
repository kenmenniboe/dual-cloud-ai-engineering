# Azure Firewall — hub-and-spoke lab (AZ-104)

**Date:** Jul 21, 2026
**Course:** Udemy AZ-104 — Azure Firewall demo (built from scratch instead of following the wizard shortcut)

## What I did

Built a hub-and-spoke network manually to understand what Azure Firewall actually does, rather than letting the portal wizard create everything automatically.

**Resources built:**
- `Hub-VNet` (`10.0.0.0/16`)
  - `AzureFirewallSubnet` (`10.0.1.0/26`)
  - `AzureBastionSubnet` (`10.0.2.0/26`)
- Azure Firewall (Standard tier) + Firewall Policy (`hub-fw-policy`)
- `Spoke-VNet` (`10.1.0.0/16`) with `workload-subnet`, peered to Hub
- Route table forcing `0.0.0.0/0` → Firewall's private IP (forced tunneling)
- Azure Bastion (Standard tier, deployed in Hub — reachable across peered spokes)
- Test VM (`test-vm`, no public IP) in `workload-subnet`
- Application rule allowing `ubuntu.com` + `*.ubuntu.com` over `https:443,http:80`

## Key result

Confirmed Azure Firewall's Application rules work end-to-end:

| Test | Destination | Result |
|---|---|---|
| `curl -v https://ubuntu.com` | Matched rule | ✅ Allowed |
| `curl -v http://ubuntu.com` | Matched rule | ✅ Allowed (301 redirect) |
| `curl -v https://github.com` | No matching rule | ❌ Blocked (deny by default) |

## Biggest takeaways

1. **`*.ubuntu.com` only matches subdomains, not the bare domain.** Needed both `ubuntu.com` and `*.ubuntu.com` in the same rule to cover the apex domain and its subdomains — this is what caused the first failed test.
2. **Azure Firewall inspects the TLS SNI field**, not the encrypted payload — that's how it matches FQDN rules on HTTPS traffic without decrypting anything.
3. **VNet peering "allow forwarded traffic" must be enabled on both sides** whenever a firewall or NVA sits between two peered VNets — otherwise the destination VNet rejects traffic whose source IP doesn't match a direct peer.
4. **Azure Bastion Standard tier can reach VMs across peered VNets** — no need for a separate Bastion per spoke.

## Errors hit and fixed

- `SSL_ERROR_SYSCALL` on `curl https://ubuntu.com` → rule only listed `*.ubuntu.com`, not the apex `ubuntu.com` → added both.
- Peering setup initially missing "allow forwarded traffic" → would have blocked Firewall-forwarded packets between spokes.

See `notes.md` for the full step-by-step walkthrough and `commands.md` for the CLI commands used.