# Azure Application Gateway — Reference Guide

## Acronyms

| Acronym | Meaning |
|---|---|
| AGIC | Application Gateway Ingress Controller |
| AKS | Azure Kubernetes Service |
| ARM | Azure Resource Manager |
| CLI | Command Line Interface |
| FQDN | Fully Qualified Domain Name |
| IAM | Identity and Access Management |
| NSG | Network Security Group |
| OSI | Open Systems Interconnection (7-layer network model) |
| OWASP | Open Web Application Security Project |
| RBAC | Role-Based Access Control |
| SKU | Stock Keeping Unit (used by Azure to denote resource tier/version) |
| SSL | Secure Sockets Layer |
| TLS | Transport Layer Security |
| VMSS | Virtual Machine Scale Set |
| VNet | Virtual Network |
| WAF | Web Application Firewall |

---

## Concept 1: Layer 7 vs. Layer 4 Load Balancing

Application Gateway operates at **Layer 7 (application layer)** — it reads the actual HTTP/HTTPS request (URL path, hostname, headers) to make routing decisions.

Standard Load Balancer operates at **Layer 4 (transport layer)** — it only sees IP address + port, with no content awareness.

**Analogy:** Layer 4 is a mailroom clerk sorting packages by zip code only. Layer 7 is a clerk who reads the actual address label ("Attn: Billing" vs "Attn: Support") and routes accordingly — even if both arrived at the same zip code.

This is why Application Gateway can do path-based and host-based routing across multiple apps on a single public IP, which a Load Balancer cannot.

---

## Concept 2: Core Components

| Component | Role |
|---|---|
| Front End IP | The public/private IP or FQDN clients connect to — the "street address" |
| Listener | Watches a specific port + protocol (+ optional hostname) — the "front door" |
| Routing Rule | Links a listener to a backend pool + HTTP settings — the "instruction sheet" |
| Backend Pool | The actual servers (VMs, VMSS, App Service, IPs, FQDNs) handling requests |
| HTTP Settings | Defines how the gateway talks to the backend — port, protocol, affinity, timeouts, probes |

**Full request flow:**
```
Client
  │
  ▼
Front End IP  (street address)
  │
  ▼
Listener       (front desk — port/protocol/hostname match)
  │
  ▼
Routing Rule   (instruction sheet — where does this go?)
  │
  ├──► Backend Pool + HTTP Settings   (normal routing)
  │
  └──► Redirect Configuration          (e.g. HTTP → HTTPS, no backend touched)
```

**Symptom to remember:** if the backend pool exists but has **0 targets**, the gateway still accepts the connection at the listener level — you get a **502 Bad Gateway**, not a timeout or dead connection. This confirms the gateway itself is alive; it just has nowhere to route.

---

## Concept 3: Routing Rule Types

- **Basic rule** — one listener → one backend pool (all traffic same destination)
- **Path-based rule** — one listener → multiple backend pools, chosen by URL path match (e.g. `/product-images/*` → pool A, everything else → default pool B)

**Analogy:** Basic rule = front desk sends every guest to the same tower. Path-based rule = front desk sorts by reservation type ("spa guests → Spa Tower, conference badge → Conference Tower, everyone else → Main Tower").

---

## Concept 4: Cookie-Based (Session) Affinity

Enabled in **HTTP Settings**. Binds a client to the same backend VM for the life of a session — critical for stateful apps (e.g. shopping carts) where a user landing on a different backend VM mid-session would lose state.

---

## Concept 5: VMSS Backend Gotcha — Model vs. Instance State

A VM Scale Set has a **model** (desired config on file) and **instances** (already-running VMs). Adding a backend pool association updates the model — but already-running instances don't pick up the change until they're explicitly refreshed via **Upgrade** (which restarts them).

Same root cause as: a Custom Script Extension only runs on instance creation or restart — not retroactively on already-running instances.

**Workaround used in this session:** link the backend pool **at VMSS creation time** (via the Networking tab's Load Balancing section) instead of adding it afterward — this avoids the manual Upgrade step entirely.

**Analogy:** the VMSS model is a blueprint on file; instances are buildings already built from an older version of that blueprint. Updating the blueprint doesn't retroactively rebuild existing buildings.

---

## Concept 6: V1 vs. V2 SKU — Key Constraints

| Constraint | Detail |
|---|---|
| Public IPs | Only **one** public IP supported — never multiple |
| Dedicated subnet | Required, but **multiple gateways can share** the same subnet |
| V1 internal IP | Can change on restart |
| V2 internal + public IP | Both **static** for the gateway's lifetime |
| Stop/Start | Portal doesn't support it — CLI only: `az network application-gateway stop` / `start` |

---

## Concept 7: SSL/TLS Termination via Key Vault

**Pattern:**
1. Store the cert in Key Vault
2. Give the gateway a **user-assigned managed identity**
3. Grant that identity **Key Vault Secrets User** (not "Certificates User" — Key Vault stores certs internally as secrets)
4. Reference the Key Vault secret ID on the gateway's SSL cert / listener

**Two termination modes:**
- **TLS termination at the gateway** — client↔gateway encrypted; gateway↔backend can stay HTTP (what we built)
- **End-to-end encryption** — encrypted the entire way, client↔gateway *and* gateway↔backend

**HTTP → HTTPS redirect:** built by changing the HTTP listener's routing rule from "Backend pool" target type to **Redirection** (Permanent 301, target = the HTTPS listener). The request never touches a backend VM — the gateway just tells the browser to go to HTTPS instead.

**Analogy:** managed identity = an employee ID badge. The badge alone does nothing until it's programmed with a specific access permission (role) — "can access the safe" (Key Vault Secrets User) — before the employee (Application Gateway) can retrieve what's inside (the cert).

### ⚠️ Real issue #1 — Key Vault RBAC + Portal listener cert picker is broken

**Symptom:** `This key vault doesn't allow access to the managed identity. If using role-based access control permission model instead of policy.` — even with the correct role assigned and waited out.

**Cause:** known Azure Portal UI limitation. The Portal's "Add Listener" cert picker cannot verify a managed identity's access when the Key Vault uses the **RBAC** permission model (works fine under the old Access Policy model).

**Fix:** link the cert to the gateway via CLI first — once linked that way, the Portal picker recognizes it correctly afterward.

```bash
az keyvault certificate show --vault-name <kv-name> --name <cert-name> --query "sid" -o tsv

az network application-gateway ssl-cert create \
  --gateway-name <gateway-name> \
  --resource-group <rg-name> \
  --name <cert-name> \
  --key-vault-secret-id <secret-id-from-above>
```

### ⚠️ Real issue #2 — Managed identity silently not attached

**Symptom:** `ApplicationGatewayKeyVaultSecretRequiresUserAssignedIdentity` even after attaching the identity via the Portal's Identity blade.

**Cause:** the Portal save didn't fully commit the identity attachment at the resource level.

**Fix:** verify and attach via CLI directly.

```bash
az network application-gateway show --name <gateway-name> --resource-group <rg-name> --query identity -o json
# returned empty — confirms nothing attached

az identity show --name <identity-name> --resource-group <rg-name> --query id -o tsv

az network application-gateway identity assign \
  --gateway-name <gateway-name> \
  --resource-group <rg-name> \
  --identity <identity-resource-id>

# re-verify
az network application-gateway show --name <gateway-name> --resource-group <rg-name> --query identity -o json
```

**[Screenshot placeholder: Key Vault RBAC error in Portal listener config]**
**[Screenshot placeholder: `az network application-gateway show --query identity` output confirming attachment]**

---

## Concept 8: WAF (Web Application Firewall)

Feature toggle on top of Application Gateway (requires **WAF_v2** tier) that inspects incoming traffic **before** it reaches the backend — matched against rule sets like OWASP Core Rule Set.

**Protects against:** SQL injection, XSS, HTTP protocol violations, bot/crawler/scanner abuse, DDoS-style patterns, plus **geo-filtering** (allow/block by country).

**Analogy:** if Application Gateway is the hotel front desk routing guests to rooms, WAF is security screening *before* the front desk — checking every single guest regardless of which room they're headed to.

**Modes:** Prevention (actually blocks) vs. Detection (logs only, doesn't block) — must use **Prevention** to see real blocking behavior.

### ⚠️ Real issue #3 — "Direct WAF configuration... has been retired"

**Symptom:** upgrading tier to WAF_v2 via the **Configuration** blade fails with: `Direct WAF configuration on Application Gateway has been retired. To continue, attach an existing WAF policy or create a new one and associate it with your gateway.`

**Cause:** Microsoft fully discontinued the old "WAF settings living directly on the gateway resource" model as of March 15, 2025. New deployments must reference a separate **WAF Policy** resource — the Configuration blade doesn't expose a policy selector at all.

**Fix:** do the tier upgrade + policy association together through the dedicated **Web Application Firewall** blade (left settings menu) — not through **Configuration**.

**Verified block test:**
```
https://<gateway-public-IP>/?id=1' OR '1'='1'
```
→ returned `403 Forbidden`, served directly by `Microsoft-Azure-Application-Gateway/v2` (never reached nginx) — confirms OWASP managed rules caught the SQL-injection pattern.

**[Screenshot placeholder: "Direct WAF configuration...has been retired" error banner]**
**[Screenshot placeholder: 403 Forbidden response from WAF test]**

---

## Concept 9: Kubernetes Integration

Pods are ephemeral — IPs change on every recreation, so the gateway can't track them natively.

- **AGIC (Application Gateway Ingress Controller)** — installed inside the AKS cluster, watches pod creation/deletion, auto-updates the backend pool. Still supported.
- **Application Gateway for Containers** — a **separate product** (not a feature of Application Gateway), built for the newer Gateway API ingress model. **Microsoft's current recommendation** for new deployments over AGIC.

---

## Concept 10: Service Comparison (exam-relevant)

| Service | Layer | Scope | WAF? | Private LB? |
|---|---|---|---|---|
| Application Gateway | 7 | Regional | Yes | Yes |
| Azure Load Balancer | 4 | Regional | No | Yes |
| Front Door | 7 | Global | Yes | No |
| Traffic Manager | DNS-based | Global | No | No |

Two facts worth memorizing: **private (internal) load balancing** is only on App Gateway + Load Balancer. **WAF** is only on App Gateway + Front Door.

---

## Hands-On Build — Full Step-by-Step (Copy-Paste Redo Guide)

**Order used (recommended, not the video's order):** VNet → Public IP → Application Gateway → VMSS (linked at creation) → Verify → SSL/Key Vault → WAF.
This differs from the video (which links the backend pool *after* VMSS creation, requiring a manual Upgrade/restart step) — linking at creation avoids that entirely.

**Naming used in this session** (swap in your own if redoing):
`rg-appgw-demo` · `vnet-appgw-demo` · `subnet-appgw` (10.0.0.0/24) · `subnet-workloads` (10.0.1.0/24) · `pip-appgw-demo` · `appgw-demo` · `pool-nginx-demo` · `httpsettings-01` · `listener-http` / `listener-https` · `rule-http-01` / `rule-https-01` · `vmss-nginx-demo` · `kv-appgw-demo-<initials>` · `cert-appgw-demo` · `id-appgw-demo` · `waf-policy-demo`

---

### Step 1 — Create the VNet with two subnets

1. Portal → **Virtual networks** → **Create**
2. Resource group → **Create new**: `rg-appgw-demo`
3. Name: `vnet-appgw-demo`
4. Region: pick one, use it for every resource below
5. Skip **Security** tab → go to **IP Addresses**
6. Rename the default subnet: `subnet-appgw`, CIDR `10.0.0.0/24`
7. Add a second subnet: `subnet-workloads`, CIDR `10.0.1.0/24`
8. **"Enable private subnet (no default outbound access)" → leave UNCHECKED**
   - **Why:** the VMSS in Step 4 needs outbound internet access for `apt install nginx`. Checking this disables default outbound unless you explicitly add a NAT Gateway or outbound rule — same class of issue as the SNAT problem from the earlier Load Balancer lab.
9. **Review + Create**

---

### Step 2 — Create the Public IP

1. Portal → **Public IP addresses** → **Create**
2. Resource group: `rg-appgw-demo`
3. Name: `pip-appgw-demo`
4. SKU: **Standard** (required — App Gateway v2 only supports Standard SKU public IPs)
5. Assignment: **Static** (Standard SKU forces this)
6. Region: match the VNet
7. **Review + Create**

---

### Step 3 — Create the Application Gateway

1. Portal → **Application Gateways** → **Create**
2. **Basics:**
   - Resource group: `rg-appgw-demo`
   - Name: `appgw-demo`
   - Tier: **Standard V2** (skip WAF v2 and V1 — upgrade to WAF later)
   - Autoscaling: enabled, min 0 / max 10
   - Availability zones: enable **all three**
   - Virtual network: `vnet-appgw-demo` → subnet: `subnet-appgw`
3. **Frontends:**
   - Frontend IP type: **Public**
   - Select existing `pip-appgw-demo`
4. **Backends:**
   - Add backend pool: `pool-nginx-demo` → **"Add backend pool without targets"** (we link real targets in Step 4)
5. **Configuration (routing rule):**
   - Rule name: `rule-http-01`, **priority 100** (lower number = higher priority; leaving gaps like 100/200/300 makes room to insert rules later without renumbering)
   - Listener: `listener-http`, Frontend IP: Public, Protocol: **HTTP**, Port: **80**
   - Backend target: `pool-nginx-demo`
   - Backend settings → create new: `httpsettings-01`, protocol **HTTP**, port **80**, cookie-based affinity **off**
6. Skip Tags → **Review + Create** (~7 minutes to deploy)

---

### Step 4 — Create the VMSS (backend pool linked at creation)

1. Portal → **Virtual machine scale sets** → **Create**
2. **Basics:**
   - Resource group: `rg-appgw-demo`
   - Name: `vmss-nginx-demo`
   - Availability zones: **all 3**
   - Orchestration mode: **Uniform**
   - Image: **Ubuntu Server 24.04 LTS** (Gen2)
   - Authentication: SSH public key (default) — download the private key if you want SSH access later
   - **Scaling section** (folded into Basics in current Portal layout — no separate "Scaling" tab): **Instance count: 3**
3. **Disks:** Standard HDD is fine for a lab
4. **Networking:**
   - Virtual network: **select the existing** `vnet-appgw-demo` (Portal defaults to auto-creating a new one — click **Edit virtual network** and switch it to existing if it shows something like `(New) vnet-...`)
   - Subnet: **select the existing** `subnet-workloads` via **Edit subnet** (never `subnet-appgw` — that's reserved for the gateway)
   - **Load balancing: choose "Azure Application Gateway"** (not "None") → select `appgw-demo` → backend pool `pool-nginx-demo`
   - This single step is what avoids the video's manual "0 targets → Upgrade" fix-up
5. **Advanced tab → Extensions:**
   - **+ Extension** → **Custom Script for Linux** → paste the command from `commands.md` (nginx install)
6. **Review + Create**

> ⚠️ **Error hit here:** generic `Validation failed` with no clear field flagged. **Fix:** click the red validation banner/icon near Review + Create to expand the actual error text (the summary view doesn't show it). In this session the deployment succeeded on retry — most likely a transient SKU/zone availability check with the VM size chosen.

**[Screenshot placeholder: VMSS Networking tab showing correct VNet/subnet + Application Gateway load balancing selection]**

---

### Step 5 — Verify backend health and load balancing

1. `appgw-demo` → **Backend pools** → `pool-nginx-demo` → **Backend health** → confirm **3/3 healthy**, `200 OK` on each
2. Copy the public IP from **Frontend IP configurations** (or `pip-appgw-demo` directly)
3. Paste into browser as `http://<public-IP>` **explicitly with the scheme**

> ⚠️ **Error hit here:** `This site can't be reached... took too long to respond` when pasting the bare IP.
> **Diagnosis:** ran `curl -v http://<public-IP> --max-time 10` from **Azure Cloud Shell** → got a clean `200 OK` with the nginx response. This proved the Azure side was fully working and isolated the problem to the local browser/network.
> **Fix:** typed `http://` explicitly instead of the bare IP — the browser had been silently trying to upgrade the bare IP to HTTPS, which hung because only port 80 was configured at that point.

4. Refresh the page 5-6 times — confirm the hostname/IP rotates across all 3 instances (`10.0.1.4`, `.5`, `.6`), confirming Layer 7 load balancing is working.

**[Screenshot placeholder: Backend health blade showing 3/3 healthy targets]**

---

### Step 6 — Create the Key Vault

1. Portal → **Key vaults** → **Create**
2. Resource group: `rg-appgw-demo`
3. Name: `kv-appgw-demo-<your-initials>` (must be globally unique)
4. Pricing tier: **Standard**
5. **Access configuration tab:** **Azure role-based access control (RBAC)**
6. **Review + Create**

---

### Step 7 — Generate a self-signed certificate

1. Key Vault → **Certificates** → **+ Generate/Import**
2. Method: **Generate**
3. Certificate name: `cert-appgw-demo`
4. Certificate Authority: **Self-signed certificate**
5. Subject: `CN=appgw-demo.local` (placeholder domain — no real custom domain purchased for this lab)
6. Content type: **PKCS #12**
7. **Create**

> ⚠️ **Error hit here:** `The operation is not allowed by RBAC. If role assignments were recently changed, please wait several minutes for role assignments to become effective.`
> **Cause:** under RBAC mode, being the vault's creator/Owner does **not** automatically grant data-plane access to secrets/certs inside it — management-plane and data-plane access are separate in Key Vault RBAC.
> **Fix:**
> 1. Key Vault → **Access control (IAM)** → **+ Add** → **Add role assignment**
> 2. Role: **Key Vault Certificates Officer**
> 3. Assign to: yourself
> 4. Save, wait 2-5 minutes for propagation, retry cert generation

**[Screenshot placeholder: RBAC propagation error message]**

---

### Step 8 — Create the managed identity and grant Key Vault access

1. Portal → **Managed Identities** → **Create**
2. Resource group: `rg-appgw-demo`, Name: `id-appgw-demo`
3. **Review + Create**
4. Key Vault → **Access control (IAM)** → **+ Add** → **Add role assignment**
5. Role: **Key Vault Secrets User** (not "Certificates User" — certs are stored as secrets internally)
6. Assign access to: **Managed identity** → **User-assigned** → select `id-appgw-demo`
7. Save

---

### Step 9 — Attach the identity to the gateway (Portal attempt)

1. `appgw-demo` → **Identity** blade → **User assigned** → **+ Add** → select `id-appgw-demo` → Save

### Step 10 — Add the HTTPS listener (first attempt — hits a known bug)

1. `appgw-demo` → **Listeners** → **+ Add listener**
2. Name: `listener-https`, Frontend IP: Public, Protocol: **HTTPS**, Port: **443**
3. Certificate source: **Key Vault** → attempt to select `kv-appgw-demo-...` / `cert-appgw-demo`

> ⚠️ **Error hit here:** `This key vault doesn't allow access to the managed identity. If using role-based access control permission model instead of policy.`
> **Cause:** known Azure **Portal UI limitation** — the "Add Listener" cert picker cannot verify a managed identity's access when the Key Vault uses RBAC, even with the correct role already assigned (unlike the old Access Policy model, which the Portal UI *can* verify).
> **Fix — link the cert via Azure CLI first, then retry the Portal listener:**
>
> Open **Cloud Shell** and run:
> ```bash
> az keyvault certificate show --vault-name kv-appgw-demo-klm --name cert-appgw-demo --query "sid" -o tsv
> ```
> Copy the returned secret ID, then:
> ```bash
> az network application-gateway ssl-cert create \
>   --gateway-name appgw-demo \
>   --resource-group rg-appgw-demo \
>   --name cert-appgw-demo \
>   --key-vault-secret-id <paste-the-sid-here>
> ```

> ⚠️ **Second error hit here (from the same command):** `ApplicationGatewayKeyVaultSecretRequiresUserAssignedIdentity — Application Gateway ... requires a 'UserAssigned' Identity with 'get' access policy to the referenced KeyVault. Please provide so by using top level 'Identity' property.`
> **Cause:** the Portal's Step 9 save (Identity blade) had **silently not committed** — confirmed by running:
> ```bash
> az network application-gateway show --name appgw-demo --resource-group rg-appgw-demo --query identity -o json
> ```
> which returned **empty**, proving nothing was actually attached at the resource level.
> **Fix — attach the identity via CLI instead:**
> ```bash
> az identity show --name id-appgw-demo --resource-group rg-appgw-demo --query id -o tsv
> ```
> Copy the returned resource ID, then:
> ```bash
> az network application-gateway identity assign \
>   --gateway-name appgw-demo \
>   --resource-group rg-appgw-demo \
>   --identity <paste-the-identity-resource-id-here>
> ```
> Verify it actually attached this time:
> ```bash
> az network application-gateway show --name appgw-demo --resource-group rg-appgw-demo --query identity -o json
> ```
> Should now return a JSON block showing `"type": "userAssigned"` with `id-appgw-demo`'s client/principal IDs.
>
> **Then retry the ssl-cert create command** from above — it should now return `"provisioningState": "Succeeded"`.

**[Screenshot placeholder: Key Vault RBAC listener error in Portal]**
**[Screenshot placeholder: `az network application-gateway show --query identity` — before (empty) and after (populated) ]**

4. **Back in the Portal**, redo the listener: `appgw-demo` → **Listeners** → **+ Add listener** → `listener-https` → Protocol HTTPS, Port 443 → the certificate `cert-appgw-demo` should now appear directly in the dropdown (already linked via CLI — no need to re-select Key Vault/identity) → Save

5. **Add the routing rule:** `appgw-demo` → **Rules** → **+ Add rule**
   - Name: `rule-https-01`, priority **200**
   - Listener: `listener-https`
   - Backend target: `pool-nginx-demo`, Backend settings: `httpsettings-01`
   - Save

6. **Test:** browse to `https://<public-IP>` → expect a self-signed cert warning (expected, since `cert-appgw-demo` is self-signed for a placeholder domain) → click through → should land on the same nginx response as the HTTP test.

---

### Step 11 — HTTP → HTTPS redirect

1. `appgw-demo` → **Rules** → open `rule-http-01`
2. Change target type from **Backend pool** to **Redirection**
3. Redirection type: **Permanent (301)**
4. Redirect target: **Existing listener** → `listener-https`
5. Include query string: on (default)
6. Save

**Test:** browse to `http://<public-IP>` (no S) — confirm it auto-redirects to `https://<public-IP>`.

---

### Step 12 — Create the WAF policy

1. Portal → search **WAF policies** → **Create**
2. Policy for: **Regional (Application Gateway)**
3. Resource group: `rg-appgw-demo`, Name: `waf-policy-demo`
4. **Policy settings:** Mode: **Prevention** (Detection mode only logs — doesn't block, so won't demonstrate a real 403)
5. **Managed rules:** leave the default OWASP rule set enabled
6. Skip Association for now
7. **Review + Create**

---

### Step 13 — Upgrade tier + associate the WAF policy

1. **First attempt (fails):** `appgw-demo` → **Configuration** → Tier: **WAF V2** → **Save**

> ⚠️ **Error hit here:** `Failed to save configuration changes to application gateway 'appgw-demo'. Error: Direct WAF configuration on Application Gateway has been retired. To continue, attach an existing WAF policy or create a new one and associate it with your gateway.`
> **Cause:** Microsoft fully discontinued creating new *direct* WAF configurations (WAF settings living directly on the gateway resource, no separate policy object) as of **March 15, 2025**. The **Configuration** blade doesn't expose a WAF policy selector at all — it can't complete this upgrade path anymore.
> **Fix — use the dedicated Web Application Firewall blade instead, which handles the tier bump + policy association together:**
> 1. `appgw-demo` → **Web Application Firewall** (left Settings menu — not Configuration)
> 2. Associate WAF policy: select `waf-policy-demo`
> 3. Save

2. Verify: `appgw-demo` → **Overview**/**Configuration** → confirm **Tier: WAF V2**

**[Screenshot placeholder: "Direct WAF configuration...has been retired" error banner]**
**[Screenshot placeholder: Web Application Firewall blade with waf-policy-demo associated]**

---

### Step 14 — Test the WAF block

1. Browse to:
   ```
   https://<public-IP>/?id=1' OR '1'='1
   ```
2. **Result:** `403 Forbidden`, served by `Microsoft-Azure-Application-Gateway/v2` directly — the request never reached nginx, confirming the OWASP managed rule set caught the SQL-injection pattern.

**[Screenshot placeholder: 403 Forbidden response from WAF test]**

---

## Diagram — Final Architecture

```
                    ┌─────────────────────────-┐
                    │   Public IP (Standard)   │
                    └────────────┬─────────────┘
                                 │
                    ┌────────────▼─────────────---┐
                    │   Application Gateway v2    │
                    │   (WAF_v2, 3 AZ)            │
                    │                             │
                    │  Listener :80 ──► Redirect  │──► to :443
                    │  Listener :443 (TLS term.)  │
                    │        │                    │
                    │  WAF Policy (Prevention,    │
                    │  OWASP rules)               │
                    │        │                    │
                    │  Routing Rule ──► Backend   │
                    └────────────┬─────────────---┘
                                 │
                    ┌────────────▼─────────────--┐
                    │  Backend Pool              │
                    │  pool-nginx-demo           │
                    └────────────┬─────────────--┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                  ▼
        VMSS instance      VMSS instance      VMSS instance
        (AZ 1, nginx)      (AZ 2, nginx)      (AZ 3, nginx)

   TLS cert retrieved from:
   Key Vault (RBAC) ──► via User-Assigned Managed Identity
                         (Key Vault Secrets User role)
```