# Azure Front Door — AZ-104

## Summary

Studied Azure Front Door end-to-end: what it is, its core components, how its routing
logic decides which origin serves a request, tier differences, and rule sets — then
built and verified a working lab in the Portal.

## What I learned

- **Positioning**: Front Door is the only one of Azure's 4 load-balancing options that
  is both **global** and **Layer 7** (HTTP-aware), with built-in CDN + WAF. Load
  Balancer (L4, regional), Application Gateway (L7, regional), and Traffic Manager
  (DNS-based, global) each cover a different corner of that matrix.
- **Core components**: endpoint (public FQDN) → origin group (collection of origins)
  → origin (backend), gated by health probes, with an optional rule set to override
  default routing.
- **Routing funnel** (in order): health probes filter unhealthy origins → priority
  picks the highest healthy tier → latency sensitivity filters by response time →
  weight splits remaining traffic proportionally → session affinity (optional) pins
  a user to one origin.
- **Tiers**: Standard covers routing/CDN/WAF for public origins. Premium is required
  only when an origin has no public endpoint (Private Link support) — the deciding
  factor, not price.
- **Rule sets**: condition + action, evaluated only for matching traffic. URL redirect
  sends the *browser* to the origin directly (leaves Front Door's network — breaks if
  the origin locks down to Front Door-only access). Route/origin-group override and
  header modification stay inside Front Door instead.

## Hands-on build (Standard tier)

- Two Linux App Services (`jelledruyts/inspectorgadget` container) in different
  regions — Central US and Canada Central.
- One Front Door Standard profile, one origin group with both App Services as
  same-priority, same-weight origins → confirmed round-robin distribution.
- HTTPS-only redirect confirmed on the default route.
- A rule set (geo-match condition → URL redirect action) confirmed working —
  address bar visibly switched from the Front Door endpoint to the origin's raw URL.

## Key outputs / results

- Front Door endpoint went live at `<endpoint-name>.z01.azurefd.net`.
- Confirmed traffic actually passed through Front Door via the `X-Azure-FDID` and
  `X-Forwarded-Host` response headers (not visible when hitting an origin directly).
- Round-robin confirmed via a `curl` loop with `Connection: close` (forces a fresh
  connection each request) — got a 4:2 split across 6 requests, both origins serving
  traffic as expected for equal weight.
- Rule set redirect confirmed via a real browser address-bar change to the origin's
  `.azurewebsites.net` domain.

## Errors hit and fixed

1. **Wrong Docker image name** (`alexeiled/inspector-gadget`, doesn't exist) →
   `ImageNotFoundFailure` in the log stream → fixed by using the correct image,
   `jelledruyts/inspectorgadget:latest`.
2. **`Microsoft.Cdn` not registered** on the subscription → blocked Front Door
   creation → fixed by registering the resource provider under
   Subscription → Resource providers.
3. **Rule set didn't fire immediately** after editing the destination host →
   resolved itself after normal AFD propagation delay (back-to-back changes can
   take up to ~30 minutes).

Full step-by-step redo guide (including exact Portal field values, every command,
and where each fix applies) is in `notes.md`. All CLI commands are in `commands.md`.

## Deferred to a future session

- **Module 6 — Private Link + AKS**: exposing a fully private origin through Front
  Door Premium. Needs its own AKS cluster and a Premium-tier profile; not built this
  session.