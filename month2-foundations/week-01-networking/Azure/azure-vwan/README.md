# Azure Virtual WAN — Conceptual Walkthrough

## Summary

Conceptual (no-deploy) walkthrough of Azure Virtual WAN, followed by a quick Private Link Service recap. Full hub deployment was intentionally skipped — not worth the cost/time at AZ-104 "basics" depth.

Covered:
- What Virtual WAN is and the scaling problem it solves vs. traditional Hub-and-Spoke
- Core building blocks: Virtual WAN resource, Virtual Hub, Hub VNet Connections, and the three independent gateway types (VPN, ExpressRoute, P2S)
- Basic vs Standard SKU feature differences
- vWAN vs traditional Hub-and-Spoke, side by side
- Routing basics: default route table (automatic any-to-any) vs custom route tables (traffic segmentation, e.g. forcing Production through Azure Firewall)
- Private Link Service recap — the provider-side counterpart to the Private Endpoint lab already completed (publishing a service behind a Standard Load Balancer for cross-tenant private access)

## Key Outputs

- 6 modules completed, 7 exam-style scenario questions answered
- One live misconception caught and corrected: Virtual WAN resource vs. VPN Gateway vs. ExpressRoute Gateway (see `notes.md` → Module 2 warning callout)
- Architecture diagram: `diagram.svg`
- Full self-test quiz bank for redo: `notes.md` → Quiz Review section

## Files

- `notes.md` — full mini-tutorial, diagram, quiz review, acronyms
- `diagram.svg` — vWAN architecture diagram

No `commands.md` this session — no CLI commands were used (conceptual only, no lab).