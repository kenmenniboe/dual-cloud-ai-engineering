# Notes – Terraform Azure VNet Demo (AZ-104)

---

## 1. What is Terraform?

Terraform is an **Infrastructure as Code (IaC)** tool. Instead of manually clicking through the Azure Portal to build resources, you write configuration files and Terraform calls Azure's API to build everything automatically.

**Key advantages:**
- Reusable — write once, deploy anywhere (dev, staging, prod)
- Repeatable — same result every time
- Consistent — no human error from clicking

---

## 2. The `.tf` File — How Terraform Knows to Use Azure

Terraform reads `.tf` config files to understand what to build and where. The `providers.tf` file tells Terraform which cloud provider to use.

```hcl
terraform {
  required_version = ">=1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.86.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

**Two separate jobs in this file:**
- `required_providers` block → tells Terraform to **download** the Azure plugin
- `provider "azurerm"` block → tells Terraform how to **configure and use** the plugin

`azurerm` = Azure Resource Manager (the plugin that speaks Azure's API)

Without this file, Terraform has no idea which cloud to connect to.

---

## 3. The Full Terraform Lifecycle

### Step 1 — Authenticate to Azure
```bash
az login
```
Before Terraform can talk to Azure, you need to authenticate using the Azure CLI. This opens a browser login window and retrieves your subscription details.

**Output:**
```
Subscription: Azure subscription 1
Tenant: Default Directory
```

If you have multiple subscriptions, you select the correct one by number. Pressing Enter accepts the default (marked with `*`).

---

### Step 2 — Initialize the Project
```bash
terraform init
```
Downloads the Azure provider plugin and sets up the local `.terraform` folder.

**Output:**
```
Finding hashicorp/azurerm versions matching ">= 3.86.0"...
Installing hashicorp/azurerm v4.75.0...
Terraform has been successfully initialized!
```

**Files created:**
- `.terraform/` folder — stores the downloaded provider plugin
- `.terraform.lock.hcl` — locks the exact provider version so the team always uses the same one

Run `terraform init` once at project start, or again any time you add a new provider.

---

### Step 3 — Plan (Dry Run)
```bash
terraform plan -out tfplan
```
Reads your `.tf` files, compares them to what exists in Azure, and shows exactly what it would create, change, or destroy — **without touching anything**.

`-out tfplan` saves the plan to a file called `tfplan` so `terraform apply` executes exactly that plan with no surprises.

**Symbols in plan output:**
- `+` = create
- `-` = destroy
- `~` = modify

**Plan output (after changing region to East US):**
```
+ azurerm_resource_group.rg          location = "eastus"
+ azurerm_virtual_network.vnet       address_space = ["10.0.0.0/16"]
+ azurerm_subnet.subnet-frontend     address_prefixes = ["10.0.0.0/24"]
+ azurerm_subnet.subnet-backend      address_prefixes = ["10.0.1.0/24"]

Plan: 4 to add, 0 to change, 0 to destroy.
Saved the plan to: tfplan
```

> **Important:** If you edit a `.tf` file after saving a plan, the `tfplan` is outdated. Always re-run `terraform plan -out tfplan` before applying.

---

### Step 4 — Apply (Build It)
```bash
terraform apply "tfplan"
```
Executes the saved plan and builds the real infrastructure in Azure.

**Build order:**
1. Resource Group (everything else depends on it)
2. Virtual Network (subnets depend on it)
3. Both Subnets (in parallel where possible)

Terraform figures out the dependency order automatically — it knows a subnet can't exist without a VNet, and a VNet can't exist without a Resource Group.

**Output:**
```
azurerm_resource_group.rg: Creation complete after 24s
azurerm_virtual_network.vnet: Creation complete after 5s
azurerm_subnet.subnet-backend-servers: Creation complete after 5s
azurerm_subnet.subnet-frontend-servers: Creation complete after 10s

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

---

### Step 5 — Destroy
```bash
terraform destroy -auto-approve
```
Tears down all resources Terraform built. `-auto-approve` skips the confirmation prompt.

**Destroy order (reverse of build):**
1. Subnets first
2. VNet second
3. Resource Group last

Terraform destroys in reverse dependency order — it can't delete a Resource Group while resources still live inside it.

**Output:**
```
Destroy complete! Resources: 4 destroyed.
```

---

## 4. IP Addressing — VNet vs Subnets

| Resource | CIDR | IPs Available |
|---|---|---|
| VNet `vnet-spoke` | `10.0.0.0/16` | ~65,500 |
| Subnet frontend | `10.0.0.0/24` | ~251 |
| Subnet backend | `10.0.1.0/24` | ~251 |

The VNet is the **big container** (`/16`). The subnets are **smaller segments carved out of it** (`/24`). Subnets must fit within the VNet's address space.

---

## 5. Key Concepts Summary

| Concept | What it means |
|---|---|
| IaC | Write code to build infrastructure instead of clicking in a portal |
| Provider | The plugin that lets Terraform talk to a specific cloud (Azure = `azurerm`) |
| `terraform init` | Downloads the provider, sets up the project |
| `terraform plan` | Dry run — preview changes before anything is built |
| `terraform apply` | Executes the plan and builds real infrastructure |
| `terraform destroy` | Tears down everything Terraform built |
| `.terraform.lock.hcl` | Pins the exact provider version for the whole team |
| `-out tfplan` | Saves the plan to a file so apply uses exactly what was previewed |
| `-auto-approve` | Skips the confirmation prompt on destroy |
| State management | Terraform remembers what it built and only changes what's different |

---

## 6. Gotchas Encountered

**Error: `Please run 'az login' to setup account`**
- Cause: Terraform couldn't authenticate to Azure
- Fix: Run `az login` before `terraform plan`

**Stale tfplan after editing `.tf` file**
- Cause: Changed `location` from `westeurope` to `eastus` after saving the plan
- Fix: Re-run `terraform plan -out tfplan` to generate a fresh plan before applying