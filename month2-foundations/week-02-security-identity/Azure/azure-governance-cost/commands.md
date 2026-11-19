# Commands: AZ-104 Governance and Cost

The lab itself was built in the **Azure portal**. This file has:
1. **Commands run during the session**: the Cloud Shell (Bash) teardown checks.
2. **CLI equivalents for a CLI-only redo**: the same lab in Azure CLI. These are labeled and **were not run in this session**. Check them in your own environment first.

> [!NOTE]
> Run in Azure Cloud Shell (Bash) or a local shell after `az login`. Quote names with spaces, for example `"Elite Subscription 1"`.

---

## 1. Commands run during the session

### Teardown verification (first attempt: stopped at the management group check)

```bash
az account set --subscription "Elite Subscription 1" && echo "rg-gov-lab exists: $(az group exists -n rg-gov-lab)" && echo "--- lab management group:" && az account management-group list --query "[?name=='mg-menniboe-lab'].name" -o tsv && echo "--- lab policy assignments:" && az policy assignment list --disable-scope-strict-match --query "[?contains(displayName,'Menniboe') || contains(displayName,'Inherit cc')].displayName" -o tsv && echo "--- locks:" && az lock list --query "[].name" -o tsv && echo "--- budgets:" && az consumption budget list --query "[].name" -o tsv && echo "--- kept action group:" && az monitor action-group list -g rg-cost-alerts --query "[].name" -o tsv
```

Output: `rg-gov-lab exists: false`, then `AuthorizationFailed` on `Microsoft.Management/managementGroups/read` at the tenant root. `&&` stopped the rest of the chain.

### Teardown verification (`;` chaining, so one error can't stop the rest)

```bash
echo "--- lab policy assignments:"; az policy assignment list --disable-scope-strict-match --query "[?contains(displayName,'Menniboe') || contains(displayName,'Inherit cc')].displayName" -o tsv; echo "--- locks:"; az lock list --query "[].name" -o tsv; echo "--- budgets:"; az consumption budget list --query "[].name" -o tsv; echo "--- kept action group:"; az monitor action-group list -g rg-cost-alerts --query "[].name" -o tsv
```

Output: no assignments, no locks, `budget-sub-labs-monthly`, `ag-lab-cost-email`.

---

## 2. CLI equivalents for a CLI-only redo (not run in this session)

### Variables

```bash
SUB="Elite Subscription 1"
MG="mg-menniboe-lab"
RG="rg-gov-lab"
LOC="eastus"
az account set --subscription "$SUB"
SUB_ID=$(az account show --query id -o tsv)
MG_SCOPE="/providers/Microsoft.Management/managementGroups/$MG"
```

### Hierarchy

```bash
# Step 1: management group
az account management-group create --name "$MG" --display-name "Menniboe Lab"

# Step 2: move the subscription under it
az account management-group subscription add --name "$MG" --subscription "$SUB_ID"

# Step 3: resource group with tags
az group create --name "$RG" --location "$LOC" --tags cc=farm-ops env=lab
```

### Azure Policy

```bash
# Look up built-in definition IDs by display name (avoids hard-coding GUIDs)
ALLOWED_LOC_DEF=$(az policy definition list --query "[?displayName=='Allowed locations'].name" -o tsv)
INHERIT_TAG_DEF=$(az policy definition list --query "[?displayName=='Inherit a tag from the resource group if missing'].name" -o tsv)
echo "$ALLOWED_LOC_DEF $INHERIT_TAG_DEF"

# Step 4: Allowed locations (Deny) at the management group, enforcement Default
az policy assignment create \
  --name "allowed-locations-mg" \
  --display-name "Allowed locations - Menniboe Lab" \
  --description "Lab: deny resources outside East US" \
  --scope "$MG_SCOPE" \
  --policy "$ALLOWED_LOC_DEF" \
  --params '{"listOfAllowedLocations":{"value":["eastus"]}}' \
  --enforcement-mode Default

# Step 5: Inherit cc tag (Modify) at the resource group, with a system-assigned identity
az policy assignment create \
  --name "inherit-cc-tag-rg" \
  --display-name "Inherit cc tag - rg-gov-lab" \
  --description "Lab: copy the cc tag from the resource group to new resources" \
  --scope "/subscriptions/$SUB_ID/resourceGroups/$RG" \
  --policy "$INHERIT_TAG_DEF" \
  --params '{"tagName":{"value":"cc"}}' \
  --mi-system-assigned --location "$LOC"

# The portal grants the identity its role automatically; with the CLI, grant it yourself
PRINCIPAL_ID=$(az policy assignment show --name "inherit-cc-tag-rg" --scope "/subscriptions/$SUB_ID/resourceGroups/$RG" --query identity.principalId -o tsv)
az role assignment create --assignee-object-id "$PRINCIPAL_ID" --assignee-principal-type ServicePrincipal \
  --role "Contributor" --scope "/subscriptions/$SUB_ID/resourceGroups/$RG"
```

> [!TIP]
> New assignments can take up to about 30 minutes to start enforcing.

### Tests

```bash
# Step 6: expect RequestDisallowedByPolicy (use a region that isn't Microsoft-restricted, e.g. westus2)
az network vnet create -g "$RG" -n vnet-deny-test -l westus2 --address-prefixes 10.0.0.0/16 --subnet-name default --subnet-prefixes 10.0.0.0/24

# Find the deny in the Activity log
az monitor activity-log list -g "$RG" --offset 1h \
  --query "[?contains(operationName.value,'deny')].{op:operationName.localizedValue,status:status.value,time:eventTimestamp}" -o table

# Step 7: allowed region, then confirm the cc tag was added
az network vnet create -g "$RG" -n vnet-tag-test -l "$LOC" --address-prefixes 10.0.0.0/16 --subnet-name default --subnet-prefixes 10.0.0.0/24
az network vnet show -g "$RG" -n vnet-tag-test --query tags
```

Expected tags: `{ "cc": "farm-ops" }`

### Locks

```bash
# Step 8
az lock create --name lock-nodelete-gov-lab --lock-type CanNotDelete --resource-group "$RG" \
  --notes "Lab: prove CanNotDelete blocks even an Owner"
az lock list --resource-group "$RG" -o table

# Step 9: expect a ScopeLocked error
az network vnet delete -g "$RG" -n vnet-tag-test
```

### Resource provider

```bash
# Step 10 fix
az provider register --namespace Microsoft.Insights
az provider show --namespace Microsoft.Insights --query registrationState -o tsv
```

### Action group and budgets

```bash
# Step 10: action group (Global location by default)
az group create --name rg-cost-alerts --location "$LOC"
az monitor action-group create -g rg-cost-alerts -n ag-lab-cost-email --short-name LabCost \
  --action email notify-lab-email you@example.com
AG_ID=$(az monitor action-group show -g rg-cost-alerts -n ag-lab-cost-email --query id -o tsv)
```

Budgets with alert conditions and action groups are easiest in the portal. For a CLI redo, use the Budgets REST API through `az rest`.

```bash
# Step 12: permanent subscription budget, $10 monthly, three alerts
az rest --method put \
  --url "https://management.azure.com/subscriptions/$SUB_ID/providers/Microsoft.Consumption/budgets/budget-sub-labs-monthly?api-version=2023-05-01" \
  --body "{
    \"properties\": {
      \"category\": \"Cost\",
      \"amount\": 10,
      \"timeGrain\": \"Monthly\",
      \"timePeriod\": { \"startDate\": \"2026-11-01T00:00:00Z\", \"endDate\": \"2027-12-31T00:00:00Z\" },
      \"notifications\": {
        \"actual50\":   { \"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 50,  \"thresholdType\": \"Actual\",     \"contactEmails\": [\"you@example.com\"], \"contactGroups\": [\"$AG_ID\"] },
        \"forecast100\":{ \"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 100, \"thresholdType\": \"Forecasted\", \"contactEmails\": [\"you@example.com\"], \"contactGroups\": [\"$AG_ID\"] },
        \"actual100\":  { \"enabled\": true, \"operator\": \"GreaterThan\", \"threshold\": 100, \"thresholdType\": \"Actual\",     \"contactEmails\": [\"you@example.com\"], \"contactGroups\": [\"$AG_ID\"] }
      }
    }
  }"

# Step 11: resource group budget ($5) - same body with amount 5, two alerts, and this URL:
# https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/rg-gov-lab/providers/Microsoft.Consumption/budgets/budget-rg-gov-lab?api-version=2023-05-01

az consumption budget list --query "[].{name:name,amount:amount,grain:timeGrain}" -o table
```

### Advisor and cost

```bash
# Step 14: cost recommendations
az advisor recommendation list --category Cost -o table
```

### Teardown (reverse order)

```bash
az lock delete --name lock-nodelete-gov-lab --resource-group "$RG"
az consumption budget delete --budget-name budget-rg-gov-lab --resource-group "$RG"
az policy assignment delete --name inherit-cc-tag-rg --scope "/subscriptions/$SUB_ID/resourceGroups/$RG"
az policy assignment delete --name allowed-locations-mg --scope "$MG_SCOPE"
az group delete --name "$RG" --yes
az account management-group subscription remove --name "$MG" --subscription "$SUB_ID"   # moves it back under the root
az account management-group delete --name "$MG"
```

> [!WARNING]
> Keep `rg-cost-alerts`, `ag-lab-cost-email` and `budget-sub-labs-monthly`. They're the permanent lab cost guard.
