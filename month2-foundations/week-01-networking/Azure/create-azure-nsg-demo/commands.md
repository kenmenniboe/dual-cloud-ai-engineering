# Commands — Azure NSG Session

**Date:** Tuesday, June 10, 2026

---

## No CLI Commands Used This Session

This lab was completed entirely via the **Azure Portal (GUI)**.

---

## Equivalent Azure CLI Commands (For Reference)

If you want to replicate this lab via CLI in a future session:

### Create an NSG
```bash
az network nsg create \
  --resource-group First-Demo-RG \
  --name mydemo-NSG \
  --location eastus
```

### Add a Custom Inbound Rule (Allow RDP)
```bash
az network nsg rule create \
  --resource-group First-Demo-RG \
  --nsg-name mydemo-NSG \
  --name Allow-RDP \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --destination-port-range 3389
```

### Associate NSG to a Subnet
```bash
az network vnet subnet update \
  --resource-group First-Demo-RG \
  --vnet-name First-Demo-Vnet \
  --name Public-Subnet-01 \
  --network-security-group mydemo-NSG
```

### View NSG Rules
```bash
az network nsg rule list \
  --resource-group First-Demo-RG \
  --nsg-name mydemo-NSG \
  --output table
```

---

> 💡 **Tip:** Try recreating this lab using the CLI commands above as a follow-up exercise!