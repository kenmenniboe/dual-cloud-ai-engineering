# Azure VPN Gateway — Site-to-Site (S2S), AZ-104

Hands-on lab simulating an on-prem ↔ Azure Site-to-Site VPN using two Azure VNets (no physical hardware required) — the standard way to lab this connection type.

## What I learned

- The difference between **VNet Peering** (private, Microsoft backbone, no encryption needed) and **VPN Gateway S2S** (public internet, IPsec/IKE encrypted tunnel) — and when each applies
- What **IKE** (key negotiation/authentication) and **IPsec** (packet encryption) actually do, using the TLS handshake as an anchor point
- The `GatewaySubnet` requirement: exact name, `/27`+ recommended, no NSG support
- The **Virtual Network Gateway** resource: Gateway type, VPN type (Route-based vs Policy-based), SKU/cost tradeoffs
- The **Local Network Gateway**: a free metadata pointer (public IP + address space of the *other* side) — not a billed resource
- The **Connection** resource: what ties a VNG + LNG together, and why a mismatched shared key is the #1 cause of a stuck "Not connected" tunnel
- A real, current Portal gotcha: **Basic SKU is no longer selectable in the Portal** — CLI/PowerShell only — which pushed this lab to **VpnGw1AZ** instead
- **Azure Bastion Developer SKU**: a free, no-subnet-required option for VM access in dev/test labs (confirmed available in Central US)

## Key outputs

| Resource | Value |
|---|---|
| Resource group | `rg-vpn-s2s-lab` (Central US) |
| VNet-A | `vnet-a` — `10.1.0.0/16` |
| VNet-B | `vnet-b` — `10.2.0.0/16` |
| Gateway A | `vgw-a` — VpnGw1AZ, Route-based |
| Gateway B | `vgw-b` — VpnGw1AZ, Route-based |
| Connection A→B | `connect-a-to-b` — **Connected** |
| Connection B→A | `connect-b-to-a` — **Connected** |

Tunnel status confirmed **Connected** on both sides. Data-plane traffic test (ping across the tunnel via test VMs) was started but **not completed this session**.

## Files in this folder

- [`notes.md`](notes.md) — full reference guide: concepts, exact Portal steps + CLI equivalents, errors/fixes inline, architecture diagram, redo guide
- [`commands.md`](commands.md) — this lab was Portal-only; see note inside
- [`images/architecture-diagram.svg`](images/architecture-diagram.svg) — final architecture

## Known issue at session end

`vm-b` deployed with an unintended **public IP** and **no NSG filtering** — a real security exposure caught mid-lab. Fix steps are documented in `notes.md`, in the step where it happened, and need to be applied before resuming.