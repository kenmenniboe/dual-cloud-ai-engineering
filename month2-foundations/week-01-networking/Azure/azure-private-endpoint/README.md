# Azure Private Endpoint — Azure SQL Database

## What I Learned

Today's session covered **Azure Private Endpoint / Azure Private Link**, using an Azure SQL Database as the target service, as part of AZ-104 prep.

**Concepts covered:**
- The problem Private Endpoint solves (removing PaaS public exposure)
- The DNS redirect mechanism: CNAME → `privatelink.<zone>` → private A record
- The public access lifecycle: firewall whitelisting → Private Endpoint → fully disabling public access

- **Private Endpoint** (consumer side) vs. **Private Link Service** (provider side, wraps a Standard Load Balancer)
- Which Azure services support Private Endpoint (Key Vault, Storage, App Service, ACR, Redis, Cosmos DB, and more — same NIC + private IP pattern every time)
- Subnet requirements and Private Endpoint **connection approval states** (auto-approved for your own resources; manual approval required for cross-subscription/tenant Private Link Services)

**Hands-on lab:** built the full public → private lifecycle end-to-end in the Portal (see `notes.md` for the complete redo guide).

> [!NOTE]
> Terraform implementation was intentionally skipped this session — Portal only, since prior labs already covered the IaC pattern for this kind of resource.

## Key Outputs / Results

| Test | Result |
|---|---|
| Public connectivity (before lockdown) | ✅ Connected via VS Code MSSQL extension, ran test query |
| Private Endpoint deployment | ✅ Deployed with DNS integration — auto-approved (own resource) |
| Public access disabled | ✅ Confirmed — external connection attempt returned `Error 47073: Deny Public Network Access` |
| DNS resolution from inside VNet | ✅ `nslookup` confirmed CNAME redirect: public FQDN → `privatelink.database.windows.net` → private IP `10.0.0.5` |
| Private connectivity from jumpbox | ✅ Connected via PowerShell `SqlClient`, ran test query successfully, zero internet access required |

**Resources built:** VNet + subnets, Bastion, jumpbox VM, Azure SQL Server + Database (Free offer, LRS backup), Private Endpoint, auto-created NIC, Private DNS Zone (`privatelink.database.windows.net`).

See `notes.md` for the full tutorial/reference guide and `commands.md` for every command used.