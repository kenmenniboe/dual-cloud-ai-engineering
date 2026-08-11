# Azure VPN Gateway — Point-to-Site (P2S)

**AZ-104 Day 2** — hands-on lab: single-user certificate-based P2S connectivity into a private VNet.

## What I learned
- Point-to-Site (P2S) vs. Site-to-Site (S2S) vs. VNet-to-VNet connection types, and when to use each
- `GatewaySubnet` requirements (exact naming, `/27`+ sizing)
- VPN Gateway resource fundamentals: Gateway type, VPN type, SKU tiers, and the Jan 2025 retirement of non-AZ SKUs (`VpnGw1` → `VpnGw1AZ`)
- P2S configuration: address pool, tunnel types (IKEv2 / OpenVPN / SSTP), authentication types (Certificate / RADIUS / Azure AD)
- Certificate-based P2S auth: root cert (public key → Azure) vs. client cert (private key → device), and Windows certificate trust-chain requirements
- Client-side VPN setup across three different mechanisms: the native Windows VPN client, the Azure VPN Client app, and manual native IKEv2 configuration
- Real-world troubleshooting of platform-specific client bugs (full log in `notes.md`)

## Key outputs / results
- ✅ Resource group, VNet (`vnet-p2s-lab`), workload subnet + `GatewaySubnet` created and correctly sized
- ✅ VPN Gateway (`vpngw-p2s-lab`, `VpnGw1AZ`, Route-based) provisioned successfully
- ✅ Root + client self-signed certs generated; root cert public key uploaded and trusted by the gateway
- ✅ P2S configuration (address pool, IKEv2 + OpenVPN tunnel types, certificate auth) saved and verified in the Portal
- ⚠️ Full end-to-end client connection **not completed** — blocked by a string of Windows 11 ARM64 (UTM VM) client-side compatibility bugs, documented step-by-step in `notes.md`. Azure-side configuration was independently re-verified correct at every stage before stopping.

## Environment
- Client device used for cert generation + connection attempts: Windows 11 ARM64 VM (UTM, Apple Silicon Mac host)
- Cert generation required Windows — macOS's PowerShell can't run `New-SelfSignedCertificate` (Windows-only PKI module dependency)

## Next steps
- Redo the client connection test from a genuinely native x64 Windows machine, or macOS's native IKEv2 client, to isolate whether the remaining errors are ARM64/VM-specific
- Day 3 candidate: Site-to-Site (S2S), building on this same Gateway/SKU knowledge

See `notes.md` for the full module-by-module tutorial, the complete copy-paste redo guide with every error inline, and the architecture diagram. See `commands.md` for every command used, grouped by stage.