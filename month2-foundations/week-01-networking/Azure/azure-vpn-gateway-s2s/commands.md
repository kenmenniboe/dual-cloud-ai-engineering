# Commands — Azure VPN Gateway S2S

No CLI or PowerShell commands were run in this session — this lab was completed **entirely through the Azure Portal**.

That was a deliberate choice made mid-session: the original plan was to use the **Basic** VPN Gateway SKU, but current Microsoft documentation confirmed Basic SKU is no longer selectable in the Portal (CLI/PowerShell only). Rather than break the Portal-only workflow, the lab switched to **VpnGw1AZ** instead — see `notes.md` [Section 7.4](notes.md#74-virtual-network-gateway--a) for the full context.

## Reference: CLI equivalents (untested this session)

Grouped by workflow stage. Verify syntax against current `az` docs before running — not run or validated in this lab.

### Gateway (Basic SKU — the CLI-only path)

```bash
az network vnet-gateway create \
  --name vgw-a \
  --resource-group rg-vpn-s2s-lab \
  --vnet vnet-a \
  --gateway-type Vpn \
  --vpn-type RouteBased \
  --sku Basic \
  --public-ip-address vgw-a-pip
```

### Local Network Gateway

```bash
az network local-gateway create \
  --name lng-b \
  --resource-group rg-vpn-s2s-lab \
  --gateway-ip-address <vgw-b-public-ip> \
  --local-address-prefixes 10.2.0.0/16
```

### Connection

```bash
az network vpn-connection create \
  --name connect-a-to-b \
  --resource-group rg-vpn-s2s-lab \
  --vnet-gateway1 vgw-a \
  --local-gateway2 lng-b \
  --shared-key "<shared-key>"
```