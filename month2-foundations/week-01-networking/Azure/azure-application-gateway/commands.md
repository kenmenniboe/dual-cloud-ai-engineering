# Commands — Azure Application Gateway Session

All commands run via Azure Cloud Shell during troubleshooting steps.

## VMSS Custom Script Extension (nginx install)

```bash
sudo apt update && sudo apt install -y nginx && echo "Hello from $(hostname) - IP: $(hostname -I)" | sudo tee /var/www/html/index.html
```

## Diagnostics — isolating client-side vs. Azure-side connectivity

```bash
curl -v http://<gateway-public-IP> --max-time 10
```

## Key Vault + SSL Certificate — CLI workaround for the RBAC Portal listener bug

```bash
# Get the certificate's Key Vault secret ID
az keyvault certificate show --vault-name <kv-name> --name <cert-name> --query "sid" -o tsv

# Link the cert to the Application Gateway directly (bypasses the broken Portal picker)
az network application-gateway ssl-cert create \
  --gateway-name <gateway-name> \
  --resource-group <rg-name> \
  --name <cert-name> \
  --key-vault-secret-id <secret-id-from-above>
```

## Managed Identity — verify and fix silent Portal attachment failure

```bash
# Check current identity attachment (returned empty in this session — confirmed the bug)
az network application-gateway show \
  --name <gateway-name> \
  --resource-group <rg-name> \
  --query identity -o json

# Get the managed identity's resource ID
az identity show \
  --name <identity-name> \
  --resource-group <rg-name> \
  --query id -o tsv

# Attach the identity to the gateway via CLI
az network application-gateway identity assign \
  --gateway-name <gateway-name> \
  --resource-group <rg-name> \
  --identity <identity-resource-id>

# Re-verify attachment succeeded
az network application-gateway show \
  --name <gateway-name> \
  --resource-group <rg-name> \
  --query identity -o json
```

## Reference — general tier upgrade command (not used directly; Portal's WAF blade was used instead)

```bash
az network application-gateway update \
  --name <gateway-name> \
  --resource-group <rg-name> \
  --sku-name WAF_v2 \
  --sku-tier WAF_v2
```

## Reference — Stop/Start (V1/V2 constraint noted, not exercised hands-on this session)

```bash
az network application-gateway stop --name <gateway-name> --resource-group <rg-name>
az network application-gateway start --name <gateway-name> --resource-group <rg-name>
```