# Commands used — Azure Firewall lab

Everything in this lab was built through the Azure Portal (deliberately, to see each field/setting). The only CLI usage was validation testing from the test VM via Bastion.

## Testing / validation (from test-vm, connected via Azure Bastion)

```bash
# First attempt — failed (rule only covered *.ubuntu.com, not the apex domain)
curl -v https://ubuntu.com

# After fixing the Application rule to include both ubuntu.com and *.ubuntu.com
curl -v https://ubuntu.com

# HTTP test — confirms Host-header based matching on unencrypted traffic
curl -v http://ubuntu.com

# Negative test — confirms deny-by-default for any FQDN with no matching rule
curl -v https://github.com
```

## Firewall Policy — Application rule field values (portal, not CLI)

For reference, since these were typed into portal fields rather than run as commands:

```
Destination (FQDN):   ubuntu.com,*.ubuntu.com
Protocol:              https:443,http:80
Source:                10.1.0.0/16
```