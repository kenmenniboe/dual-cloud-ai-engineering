# Azure Application Gateway (AZ-104)

## Summary

Studied Azure Application Gateway end-to-end for AZ-104, following a Udemy course transcript, then built the full stack hands-on in the Portal — going beyond the video's build order and adding two stretch goals (SSL/TLS via Key Vault, and WAF).

**Core concept:** Application Gateway is a Layer 7 (application-layer) load balancer — it reads HTTP/HTTPS content (URL path, hostname) to make routing decisions, unlike the Layer 4 Standard Load Balancer built in an earlier session, which only sees IP/port.

## What Was Covered (Concept Modules)

1. Layer 7 vs. Layer 4 — why Application Gateway exists
2. Core components — Front End IP, Listener, Routing Rule, Backend Pool, HTTP Settings
3. Basic vs. path-based routing rules
4. Cookie-based session affinity
5. VMSS backend gotcha — model vs. instance state (upgrade required to apply changes)
6. V1 vs. V2 SKU constraints (static IP, subnet sharing, stop/start via CLI only)
7. SSL/TLS termination via Key Vault + managed identity
8. WAF (Web Application Firewall) — OWASP rules, geo-filtering
9. Kubernetes integration — AGIC vs. Application Gateway for Containers
10. Service comparison — App Gateway vs. Load Balancer vs. Front Door vs. Traffic Manager

## What Was Built (Hands-On)

Built in **recommended order** (not the video's order) to avoid an unnecessary manual fix-up step:

- VNet with 2 dedicated subnets (`subnet-appgw`, `subnet-workloads`)
- Public IP (Standard SKU)
- Application Gateway (Standard_v2, zone-redundant across 3 AZs)
- VMSS (3 zonal instances, nginx via custom script) — backend pool linked **at creation**, avoiding the "0 targets → manual upgrade" issue seen in the video
- **Stretch goal 1:** TLS termination — Key Vault (RBAC mode) → self-signed cert → user-assigned managed identity → HTTPS listener → HTTP→HTTPS redirect
- **Stretch goal 2:** WAF — WAF_v2 tier upgrade, Prevention-mode policy with OWASP managed rules, associated via the (non-legacy) WAF policy model

## Key Outputs / Results

- Verified backend health: **3/3 targets healthy**, `200 OK` from each nginx instance
- Verified Layer 7 load balancing: confirmed all 3 instance IPs (`10.0.1.4`, `.5`, `.6`) rotating on refresh
- `https://<gateway-IP>` — TLS termination working, self-signed cert served correctly
- `http://<gateway-IP>` — 301 redirect to HTTPS confirmed
- WAF test: `?id=1' OR '1'='1'` → **403 Forbidden** from `Microsoft-Azure-Application-Gateway/v2`, confirming the OWASP rule set blocked the request before it reached the backend

## Real Issues Hit and Resolved

1. **Browser HTTPS-upgrade masking as a gateway problem** — bare IP timed out in browser; isolated using Cloud Shell `curl` (proved Azure-side was fine); fixed by explicitly typing `http://`
2. **Key Vault RBAC + Portal listener picker is broken** — known Portal UI limitation when Key Vault uses RBAC permission model; fixed via Azure CLI (`az network application-gateway ssl-cert create` with the Key Vault secret ID)
3. **Managed identity silently not attached** — Portal's Identity blade save didn't take; confirmed via `az network application-gateway show --query identity` and fixed via CLI (`az network application-gateway identity assign`)
4. **"Direct WAF configuration... has been retired"** — Microsoft retired direct WAF config on the gateway resource (March 2025); fixed by associating a WAF Policy through the dedicated **Web Application Firewall** blade instead of the **Configuration** blade

## Note

> **Analogy used throughout:** Application Gateway = a hotel. Front End IP = the street address. Listener = the front desk. Routing Rule = the front desk's instruction sheet. Backend Pool = the actual rooms/towers. HTTP Settings = house rules for how the bellhop delivers guests. WAF = security screening *before* the front desk, checking every guest regardless of which room they're headed to.