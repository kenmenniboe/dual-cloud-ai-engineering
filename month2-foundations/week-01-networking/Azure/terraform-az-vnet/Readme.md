# Terraform – Creating an Azure VNet (AZ-104 Demo)

## What I Learned
Used Terraform to build a real Azure Virtual Network from scratch using Infrastructure as Code (IaC). Instead of clicking through the Azure Portal, I wrote `.tf` config files and let Terraform talk directly to Azure's API.

## Resources Built
| Resource | Name | Details |
|---|---|---|
| Resource Group | `rg-demo-vnet-001` | East US |
| Virtual Network | `vnet-spoke` | `10.0.0.0/16` |
| Subnet (frontend) | `subnet-frontend-servers` | `10.0.0.0/24` |
| Subnet (backend) | `subnet-backend-servers` | `10.0.1.0/24` |

## Commands Used
```bash
az login
terraform init
terraform plan -out tfplan
terraform apply "tfplan"
terraform destroy -auto-approve
```

## Key Takeaway
Terraform manages the full lifecycle of cloud infrastructure — create, update, and destroy — in a repeatable, reusable way. The `.tf` file is the single source of truth.