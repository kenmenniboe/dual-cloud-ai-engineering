# Azure VPN Gateway — Point-to-Site (P2S) — AZ-104 Day 2

Reference guide covering the full P2S VPN Gateway topic: concepts, and the complete hands-on build with every error and fix placed exactly where it happened.

## Table of Contents
- [Overview](#overview)
- [Module 1 Connection Types](#module-1-connection-types)
- [Module 2 GatewaySubnet](#module-2-gatewaysubnet)
- [Module 3 VPN Gateway Resource](#module-3-vpn-gateway-resource)
- [Module 4 P2S Configuration](#module-4-p2s-configuration)
- [Module 5 Certificate Based Authentication](#module-5-certificate-based-authentication)
- [Module 6 Client Setup](#module-6-client-setup)
- [Module 7 Connect and Verify](#module-7-connect-and-verify)
- [Module 8 Troubleshooting and Exam Traps](#module-8-troubleshooting-and-exam-traps)
- [Hands On Build Full Redo Guide](#hands-on-build-full-redo-guide)
  - [Step 1 Create VNet and Subnets](#step-1-create-vnet-and-subnets)
  - [Step 2 Create VPN Gateway](#step-2-create-vpn-gateway)
  - [Step 3 Generate Certificates](#step-3-generate-certificates)
  - [Step 4 Export Root Certificate Public Key](#step-4-export-root-certificate-public-key)
  - [Step 5 Configure P2S on the Gateway](#step-5-configure-p2s-on-the-gateway)
  - [Step 6 Attempt Native Windows Client Connection](#step-6-attempt-native-windows-client-connection)
  - [Step 7 Switch to Azure VPN Client App](#step-7-switch-to-azure-vpn-client-app)
  - [Step 8 Pivot to Manual Native IKEv2 Connection](#step-8-pivot-to-manual-native-ikev2-connection)
  - [Step 9 Registry Fix and Retry](#step-9-registry-fix-and-retry)
  - [Step 10 Final Error and Decision to Stop](#step-10-final-error-and-decision-to-stop)
- [Architecture Diagram](#architecture-diagram)
- [Acronyms](#acronyms)

---

## Overview

Point-to-Site (P2S) VPN lets a single device (e.g., a laptop) connect directly into an Azure VNet over an encrypted tunnel, without any on-prem VPN hardware. Today's lab built a full P2S setup end-to-end: VNet + GatewaySubnet → VPN Gateway → certificate trust chain → P2S config → client-side connection.

> [!NOTE]
> The Azure-side build was independently re-verified correct at every stage. The unresolved issues in this guide are all **client-side**, tied specifically to running the connecting device as a Windows 11 ARM64 VM under UTM.

---

## Module 1 Connection Types

| Type | Use case | Hardware needed |
|---|---|---|
| **Site-to-Site (S2S)** | Whole office network ↔ Azure, permanent | On-prem VPN device |
| **Point-to-Site (P2S)** | Single device ↔ Azure (e.g., remote worker laptop) | None |
| **VNet-to-VNet** | Two Azure VNets, connected via VPN Gateway (not Peering) | None |

> [!TIP]
> **AWS comparison:** AWS attaches a Virtual Private Gateway (VGW) directly at the VPC level — no dedicated subnet required. Azure's insistence on a dedicated `GatewaySubnet` (see Module 2) is the opposite approach, and a common trip-up point coming from AWS.

**Exam scenarios covered:**
- Remote worker, no on-prem hardware → **P2S**
- Physical VPN appliance, whole-office permanent connection → **S2S**
- Two VNets, different regions, via VPN Gateway feature (not Peering) → **VNet-to-VNet**

---

## Module 2 GatewaySubnet

- Must be named **exactly** `GatewaySubnet` — Azure looks for this literal name
- Minimum size `/29`, but **`/27` or larger recommended** — smaller sizes can block future SKU upgrades or ExpressRoute coexistence
- Hosts the gateway's own backend instances (minimum 2, for HA) — not for VMs or other workloads

> [!WARNING]
> Undersizing the GatewaySubnet (e.g., `/29`) can force a rebuild later if you need to upgrade SKU or add ExpressRoute coexistence. Size generously up front.

---

## Module 3 VPN Gateway Resource

| Setting | Value for P2S | Notes |
|---|---|---|
| Gateway type | `VPN` | (vs. `ExpressRoute`) |
| VPN type | `Route-based` | **Policy-based cannot do P2S at all** — classic exam trap |
| SKU | `VpnGw1AZ`+ | See SKU note below |
| Generation | Auto-selected by SKU | Newer Portal versions no longer show this as a separate field |

> [!IMPORTANT]
> **SKU naming correction (verified live during this session):** As of **January 2025**, Azure blocked creating the old non-AZ SKUs (`VpnGw1`, `VpnGw2`, etc.) through the Portal entirely. **`VpnGw1AZ` and up are now the only options** for new gateways. Non-AZ SKUs fully retire **September 30, 2026**. `VpnGw1AZ` is functionally and price-wise identical to the old `VpnGw1` — no real trade-off, just newer naming (zone-redundant by design).
>
> Also confirmed: **`Basic` SKU supports P2S, but only via SSTP** — no IKEv2, no OpenVPN. Don't confuse "Basic doesn't support P2S" (wrong) with "Basic has a limited protocol set" (right).

---

## Module 4 P2S Configuration

| Setting | This lab's value | Notes |
|---|---|---|
| Address pool | `172.16.201.0/24` | Must **not overlap** VNet or on-prem ranges |
| Tunnel type | `IKEv2` (later added `OpenVPN (SSL)`) | Can select more than one |
| Authentication type | `Azure certificate` | vs. RADIUS / Azure AD |
| Revoked certificates | (blank) | Only used to block a specific client cert |
| Additional routes to advertise | (blank) | For reaching ranges beyond the VNet (e.g., peered VNets) |

> [!NOTE]
> `azurevpnconfig.xml` (needed for the **Azure VPN Client** app) is only included in the downloaded client package when **OpenVPN** is one of the enabled tunnel types. With IKEv2 alone, you only get the `Generic` folder (for manual/native client config).

---

## Module 5 Certificate Based Authentication

- **Root certificate**: the trust anchor. Generated once; only its **public key** is uploaded to Azure.
- **Client certificate**: generated *from* the root (signed by it); installed on each connecting device, **with its private key**.
- Azure only ever holds the root's public key — it can *verify* certs signed by the root, but can never *mint* new trusted certs itself. The root's private key never leaves your machine.

> [!WARNING]
> `New-SelfSignedCertificate` is a **Windows-only** PowerShell cmdlet (depends on the Windows PKI/Certificate Store APIs). It does not work in PowerShell Core on macOS, even after installing `pwsh` via Homebrew. Certificate generation for this lab required a Windows environment — used a Windows 11 ARM64 UTM VM.

---

## Module 6 Client Setup

Three separate artifacts, each moving a different direction:

| Artifact | Direction | Contains |
|---|---|---|
| Root cert public key | → uploaded to Azure | Public key only |
| Client cert | → installed on connecting device | Full cert + private key |
| VPN client package | ← downloaded from Azure | Pre-configured connection profile(s) |

**Downloaded package folder structure** (with IKEv2 + OpenVPN both enabled):
```
vpnclientconfiguration/
├── AzureVPN/
│   └── azurevpnconfig.xml      → for the Azure VPN Client app
├── Generic/
│   ├── VpnSettings.xml         → contains <VpnServer> FQDN, for manual native config
│   └── VpnServerRoot.cer_0     → root cert for native client trust
└── OpenVPN/
    └── vpnconfig.ovpn
```

> [!TIP]
> A file showing with a browser icon (e.g., `azurevpnconfig` looking like `.html`) is usually just a Windows file-association display quirk, not the wrong file type. Verify the real extension with `Get-ChildItem` before assuming it's wrong.

---

## Module 7 Connect and Verify

1. Client shows **Connected** status
2. `ipconfig /all` → look for a new adapter with an IP from the P2S address pool
3. Azure Portal → Gateway → **Metrics** → `P2S Connection Count` should show active sessions
4. Reachability test: `ping <private-VM-IP>`

> [!NOTE]
> **Connected tunnel + failed ping ≠ broken VPN.** This almost always means an NSG or Windows Firewall is blocking ICMP *inside* the VNet — the same pattern already seen in the Bastion/NSG lab. Check NSG rules before assuming the tunnel itself is broken.

---

## Module 8 Troubleshooting and Exam Traps

| Trap | Why it bites |
|---|---|
| Policy-based VPN type selected | Silently can't do P2S at all |
| Basic SKU + IKEv2 | Basic only speaks SSTP for P2S |
| Address pool overlaps VNet range | Routing conflicts |
| Client cert not signed by the uploaded root | Trust chain breaks — auth rejected |
| Client cert expired | `New-SelfSignedCertificate` defaults to ~1 year validity |
| **Stale VPN client package** | Change P2S config after clients already have the package → must re-download and reinstall |
| NSG attached to `GatewaySubnet` | Can block gateway management traffic |
| Ping fails, tunnel shows Connected | Almost always NSG/Firewall, not the VPN |
| Azure AD auth + native OS VPN client | Azure AD P2S auth **only** works via the dedicated Azure VPN Client app |

---

## Hands On Build Full Redo Guide

Every Portal field value and CLI command used, in the exact order run — including every validation failure and error, placed right where it happened.

### Step 1 Create VNet and Subnets

**Basics tab**
- Resource group: `rg-vpn-p2s-lab` (new)
- Name: `vnet-p2s-lab`
- Region: lab default region

**IP Addresses tab**
- Address space: `10.0.0.0/16`
- Subnet `subnet-workload`: `10.0.0.0/24`
- **+ Add a gateway subnet**: name locked to `GatewaySubnet`, range `10.0.1.0/27`

**Security tab**
- Azure Firewall: `Disable`
- Azure Bastion: `Disable` — P2S itself gives private access; no jump host needed this time
- DDoS Protection Plan: `Basic` (default, free) — `Standard` (~$2,944/mo) is production-only overkill for a torn-down lab

> [!TIP]
> **Private subnet decision point:** the newer VNet creation flow shows a checkbox — *"Enable private subnet (no default outbound access)."* This is **not** a blanket "always uncheck" setting. Check it when the subnet's VMs never need outbound internet (e.g., reached only inbound via VPN, as in this lab) — it's the more secure choice. Leave it unchecked if VMs need to call out (Windows Update, package installs) without a NAT Gateway. For `GatewaySubnet` specifically, this setting is moot — the gateway's connectivity comes from its own explicit Public IP, not the subnet's default outbound rule.
>
> This lab: **checked** for `subnet-workload` (inbound-only via VPN).

**Review + create** → Create

`![Screenshot: VNet IP Addresses tab with both subnets configured](images/screenshot-placeholder.png)`

---

### Step 2 Create VPN Gateway

**Basics tab**
- Resource group: `rg-vpn-p2s-lab` · Name: `vpngw-p2s-lab` · Region: Central US
- Gateway type: `VPN`
- VPN type: `RouteBased`
- SKU: `VpnGw1AZ`
- Virtual network: `vnet-p2s-lab`
- Subnet: `GatewaySubnet (10.0.1.0/27)` (auto-detected)
- Public IP address: `Create new` → `pip-vpngw-p2s-lab`, SKU `Standard`
- Enable active-active mode: `Disabled`
- Enable Advanced Connectivity: `Disabled`
- Configure BGP: `Disabled`

**Tags tab**: `env=lab`

**Review + create** → Create *(provisioning takes 30–45 minutes)*

> [!IMPORTANT]
> **Portal validation / correction hit here:** initially expected a plain `VpnGw1` SKU option to exist in the dropdown. It doesn't — confirmed via search that Azure blocked creating non-AZ SKUs (`VpnGw1`–`VpnGw5`) in the Portal as of **January 2025**. `VpnGw1AZ` is the correct — and only — choice, and is functionally/price identical to the old `VpnGw1`. No rebuild needed; proceeded with `VpnGw1AZ` as selected.

`![Screenshot: Gateway Basics tab fully filled in with VpnGw1AZ selected](images/screenshot-placeholder.png)`

---

### Step 3 Generate Certificates

While the Gateway provisions (30–45 min), generate certs in parallel.

> [!WARNING]
> First attempted on the Mac host directly. `New-SelfSignedCertificate` requires the Windows PKI Certificate Store APIs and **does not work** in PowerShell on macOS, even via `pwsh`. Switched to a Windows 11 ARM64 UTM VM for all certificate work and the eventual client connection.

Commands run in **PowerShell (Admin)** on the Windows VM — see [`commands.md`](./commands.md) for the exact blocks:
- Generate root cert (`P2SRootCert`)
- Generate client cert (`P2SChildCert`), signed by the root

---

### Step 4 Export Root Certificate Public Key

1. `certmgr.msc` → **Personal → Certificates** → `P2SRootCert` → **All Tasks → Export**
2. **No, do not export the private key**
3. Format: **Base-64 encoded X.509 (.CER)**
4. Save as `P2SRootCert.cer`
5. Open in Notepad → copy the Base64 block between (excluding) the `BEGIN CERTIFICATE` / `END CERTIFICATE` lines

`![Screenshot: Certificate Export Wizard, private key export declined](images/screenshot-placeholder.png)`

---

### Step 5 Configure P2S on the Gateway

Gateway → **Point-to-site configuration**:
- Address pool: `172.16.201.0/24`
- Tunnel type: `IKEv2`
- Authentication type: `Azure certificate`
- Root certificates → **+ Add**: name `P2SRootCert`, paste the Base64 data from Step 4
- Revoked certificates: left blank
- Additional routes to advertise: left blank
- **Save**

---

### Step 6 Attempt Native Windows Client Connection

1. Point-to-site configuration → **Download VPN client** → extract on the Windows VM
2. Ran the `WindowsAmd64` / `VpnClientSetupAmd64` installer
3. Windows Settings → VPN → select connection → **Connect**

> [!WARNING]
> **Error:** `Unable to execute custom script (to update your routing table). Required files could be missing.`
>
> **Cause (confirmed via Microsoft Q&A):** known, documented ARM64 incompatibility. The native client's post-connect routing update relies on `CMROUTE.dll`, which fails to execute correctly on ARM processors.
>
> **Verified via `ipconfig /all`:** no VPN adapter present at all — a genuine failed connection, not a cosmetic script error.
>
> **Next step:** switch to the Azure VPN Client app, which uses a different mechanism with no `CMROUTE.dll` dependency.

`![Screenshot: CMROUTE.dll routing script error dialog](images/screenshot-placeholder.png)`

---

### Step 7 Switch to Azure VPN Client App

1. **Microsoft Store** → install **Azure VPN Client**
2. Re-added **OpenVPN (SSL)** as a second tunnel type on the Gateway's P2S config (alongside IKEv2) and re-downloaded the client package — this is what generates the `AzureVPN` folder with `azurevpnconfig.xml`
3. Azure VPN Client → **+** → **Import** → `AzureVPN\azurevpnconfig.xml`
4. Server Validation → Certificate Information: corrected from the wrongly-autofilled `DigiCert Global Root G2` to `P2SRootCert`

> [!WARNING]
> **Error:** `The client certificate must include an issuer. Please ensure the certificate is correctly configured with a valid issuer before proceeding.`
>
> **Cause:** `P2SRootCert` was only ever in the **Personal** certificate store, never marked as a **Trusted Root** — so Windows couldn't resolve the issuer chain for the client cert.
>
> **Fix:**
> 1. `certmgr.msc` → **Trusted Root Certification Authorities** → **All Tasks → Import** → select `P2SRootCert.cer` → accept the self-signed security warning
> 2. Re-export the client cert with `-ChainOption BuildChain` (see `commands.md`) so the full chain is now included
> 3. Re-import that new `.pfx` — **do not** check "Enable strong private key protection"
>
> ✅ **Resolved** — issuer then displayed correctly, and `P2SChildCert` became selectable under Client Authentication.

5. Client Authentication → Certificate Information: selected `P2SChildCert` → **Save**

> [!WARNING]
> **Error:** `VPN connection could not be saved. VPN connection NoName could not be saved. Platform Error Code: 1`
>
> **Cause:** undocumented Azure VPN Client app bug. Confirmed via search to be a long-standing, unresolved issue reported since 2021 with no confirmed root cause from Microsoft.
>
> **Fix:** none found. Pivoted to Windows' native "Add a VPN connection" wizard instead — a different code path that avoids both this bug and the Step 6 `CMROUTE.dll` issue.

`![Screenshot: Azure VPN Client full form, Client Authentication section with P2SChildCert selected](images/screenshot-placeholder.png)`

---

### Step 8 Pivot to Manual Native IKEv2 Connection

1. `Get-Content` the `Generic\VpnSettings.xml` file → copied the full `<VpnServer>` FQDN
2. **Settings → Network & Internet → VPN → Add a VPN connection**
   - VPN provider: `Windows (built-in)`
   - Connection name: `vpngw-p2s-manual`
   - Server name or address: FQDN from step 1
   - VPN type: `IKEv2`
   - Type of sign-in info: `Certificate`
3. **Save** → select connection → **Connect**

> [!WARNING]
> **Error:** `The network connection between your computer and the VPN server could not be established because the remote server is not responding`
>
> **Cause (Microsoft-documented):** occurs when the local RAS/IKEv2 stack needs a registry key set to disable a certificate request payload behavior some VPN gateways don't handle well by default.

---

### Step 9 Registry Fix and Retry

Fix commands (PowerShell Admin) — see `commands.md` — set `HKLM\SYSTEM\CurrentControlSet\Services\RasMan\IKEv2\DisableCertReqPayload` = `1`, then **reboot the VM**.

Retried: **Settings → VPN → vpngw-p2s-manual → Connect**

✅ Got past the "remote server not responding" error — progressed to a new failure (Step 10).

---

### Step 10 Final Error and Decision to Stop

> [!WARNING]
> **Error:** `Negotiating using configured protocol is disable. Edit connection properties and select different protocol for negotiation and try again.`
>
> **Attempted fix:** `ncpa.cpl` → connection **Properties → Security** tab → explicitly set **Type of VPN: IKEv2** (not "Automatic") and **Authentication: EAP → Microsoft: Smart Card or other certificate**.
>
> **Result:** ❌ same error persisted. Could not find this exact error string documented anywhere despite a thorough search.

> [!IMPORTANT]
> **Decision point:** after three separate, largely undocumented client-side bugs — all specific to this Windows 11 ARM64 + UTM environment — stopped troubleshooting the client connection for this session. **Azure-side configuration re-verified correct at every layer** (Gateway status, GatewaySubnet, P2S config, root cert trust, client cert chain). Full end-to-end connectivity test deferred to a retry from a native x64 Windows machine or macOS's native IKEv2 client.

`![Screenshot: "Negotiating using configured protocol is disable" error dialog](images/screenshot-placeholder.png)`

---

## Architecture Diagram

![P2S VPN Architecture Diagram](images/architecture-diagram.svg)

---

## Acronyms

| Acronym | Meaning |
|---|---|
| P2S | Point-to-Site (VPN) |
| S2S | Site-to-Site (VPN) |
| VPN | Virtual Private Network |
| IKEv2 | Internet Key Exchange version 2 |
| SSTP | Secure Socket Tunneling Protocol |
| VNet | Virtual Network (Azure) |
| NSG | Network Security Group |
| SKU | Stock Keeping Unit (Azure's term for a resource tier/size) |
| CIDR | Classless Inter-Domain Routing (address block notation) |
| FQDN | Fully Qualified Domain Name |
| RAS | Remote Access Service (Windows VPN/dial-up subsystem) |
| EAP | Extensible Authentication Protocol |
| EAP-TLS | EAP — Transport Layer Security (cert-based EAP method; shown in Windows as "Smart Card or other certificate") |
| PFX | Personal Information Exchange (cert + private key bundle format, `.pfx`) |
| DER/CER | Distinguished Encoding Rules (binary cert format) / generic cert file extension |
| CA | Certificate Authority |
| PPP | Point-to-Point Protocol |
| CMAK | Connection Manager Administration Kit (builds the native Windows VPN installer package) |
| ARM64 | A 64-bit ARM processor architecture *(not to be confused with Azure Resource Manager, also abbreviated ARM)* |
| VGW | Virtual (Private) Gateway — AWS's equivalent VPN attachment point |