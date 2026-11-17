# Commands: Microsoft Entra ID and Azure RBAC

The lab was done entirely in the **Azure portal and Microsoft Entra admin center** (see `notes.md` for every console step). This file holds the **CLI equivalents** for a CLI-only redo, grouped by workflow stage, plus the repo commands.

> [!IMPORTANT]
> Azure CLI sign-in requires MFA (Mandatory Azure MFA, Phase 2). In zsh-based shells, wrap passwords and JSON in **single quotes** so characters like `!` aren't expanded.

> [!NOTE]
> `az ad` commands manage Entra ID through Microsoft Graph. Properties that `az ad user create` doesn't expose (department, job title, usage location) are set with `az rest` calls to Graph.

---

## Table of contents

- [Setup](#setup)
- [Part 0 Console tour equivalents](#part-0-console-tour-equivalents)
- [Lab 1 Users](#lab-1-users)
- [Lab 1 Groups](#lab-1-groups)
- [Lab 1 Guest invitation](#lab-1-guest-invitation)
- [Lab 1 Authentication methods policy](#lab-1-authentication-methods-policy)
- [Lab 2 Resource group and role assignment](#lab-2-resource-group-and-role-assignment)
- [Lab 2 Test as the member user](#lab-2-test-as-the-member-user)
- [Elevate access recovery](#elevate-access-recovery)
- [Teardown](#teardown)
- [Verify teardown](#verify-teardown)
- [Repo commands](#repo-commands)

---

## Setup

```bash
az login
az account list -o table
az account set --subscription "Elite Subscription 1"

# Tenant default domain (used for the UPNs below)
DOMAIN=$(az rest --method get --url 'https://graph.microsoft.com/v1.0/domains' --query "value[?isDefault].id" -o tsv)
echo "$DOMAIN"
```

## Part 0 Console tour equivalents

```bash
# T1: tenant details
az account show --query "{tenant:tenantId, subscription:name}" -o table
az rest --method get --url 'https://graph.microsoft.com/v1.0/organization?$select=displayName,verifiedDomains'

# T2: subscriptions and management groups
az account list --query "[].{name:name, state:state, tenant:tenantId}" -o table
az account management-group list -o table
az group list -o table

# T3: role assignments at subscription scope, including inherited
az role assignment list --all --include-inherited \
  --query "[].{principal:principalName, type:principalType, role:roleDefinitionName, scope:scope}" -o table
```

## Lab 1 Users

```bash
# Create the three members (temporary passwords; users change them at first sign-in)
az ad user create --display-name 'Ana Harvest' --user-principal-name "ana.harvest@$DOMAIN" \
  --password '<TEMP-PASSWORD>' --force-change-password-next-sign-in true
az ad user create --display-name 'Joe Picker' --user-principal-name "joe.picker@$DOMAIN" \
  --password '<TEMP-PASSWORD>' --force-change-password-next-sign-in true
az ad user create --display-name 'Mia Office' --user-principal-name "mia.office@$DOMAIN" \
  --password '<TEMP-PASSWORD>' --force-change-password-next-sign-in true

# Set Properties-tab fields through Microsoft Graph
az rest --method patch --url "https://graph.microsoft.com/v1.0/users/ana.harvest@$DOMAIN" \
  --body '{"givenName":"Ana","surname":"Harvest","jobTitle":"Picker","department":"Harvest","companyName":"Menniboe Farm","usageLocation":"US"}'
# Joe: usage location left blank on purpose
az rest --method patch --url "https://graph.microsoft.com/v1.0/users/joe.picker@$DOMAIN" \
  --body '{"givenName":"Joe","surname":"Picker","jobTitle":"Picker","department":"Harvest","companyName":"Menniboe Farm"}'
az rest --method patch --url "https://graph.microsoft.com/v1.0/users/mia.office@$DOMAIN" \
  --body '{"givenName":"Mia","surname":"Office","jobTitle":"Office Manager","department":"Office","companyName":"Menniboe Farm","usageLocation":"US"}'

# Verify (usageLocation must be selected explicitly)
az rest --method get \
  --url 'https://graph.microsoft.com/v1.0/users?$select=displayName,userType,department,usageLocation,onPremisesSyncEnabled' \
  --query "value[].{name:displayName, type:userType, dept:department, usage:usageLocation}" -o table
```

## Lab 1 Groups

```bash
az ad group create --display-name grp-harvest  --mail-nickname grp-harvest \
  --description 'Harvest crew - pickers'
az ad group create --display-name grp-farm-ops --mail-nickname grp-farm-ops \
  --description 'Farm operations team - manages farm resources'

# Members
az ad group member add --group grp-harvest  --member-id $(az ad user show --id "ana.harvest@$DOMAIN" --query id -o tsv)
az ad group member add --group grp-harvest  --member-id $(az ad user show --id "joe.picker@$DOMAIN"  --query id -o tsv)
az ad group member add --group grp-farm-ops --member-id $(az ad user show --id "mia.office@$DOMAIN"  --query id -o tsv)

# Owner (the signed-in admin)
ME=$(az ad signed-in-user show --query id -o tsv)
az ad group owner add --group grp-harvest  --owner-object-id "$ME"
az ad group owner add --group grp-farm-ops --owner-object-id "$ME"

# Verify
az ad group list --query "[].{name:displayName, id:id}" -o table
az ad group member list --group grp-harvest --query "[].displayName" -o tsv
```

## Lab 1 Guest invitation

```bash
# Replace with a second email address you own
az rest --method post --url 'https://graph.microsoft.com/v1.0/invitations' \
  --body '{"invitedUserEmailAddress":"second.email@example.com","invitedUserDisplayName":"Fieldwise Consultant","inviteRedirectUrl":"https://myapps.microsoft.com","sendInvitationMessage":true}'

# Invitation state: PendingAcceptance -> Accepted
az rest --method get \
  --url "https://graph.microsoft.com/v1.0/users?\$filter=userType eq 'Guest'&\$select=displayName,userType,externalUserState" \
  --query "value[].{name:displayName, type:userType, state:externalUserState}" -o table
```

## Lab 1 Authentication methods policy

```bash
# Read-only: which methods are enabled (same list as Security > Authentication methods > Policies)
az rest --method get --url 'https://graph.microsoft.com/v1.0/policies/authenticationMethodsPolicy' \
  --query "authenticationMethodConfigurations[].{method:id, state:state}" -o table
```

## Lab 2 Resource group and role assignment

```bash
az group create --name rg-harvest-lab --location eastus \
  --tags project=az104-day1-rbac owner=farm-ops

GID=$(az ad group show --group grp-farm-ops --query id -o tsv)
RGID=$(az group show --name rg-harvest-lab --query id -o tsv)

az role assignment create --assignee-object-id "$GID" --assignee-principal-type Group \
  --role Contributor --scope "$RGID" \
  --description 'Farm ops team can build and manage resources in the harvest lab'

# Role assignments on the resource group, including inherited (the admin's Owner)
az role assignment list --resource-group rg-harvest-lab --include-inherited \
  --query "[].{principal:principalName, type:principalType, role:roleDefinitionName, scope:scope}" -o table

# Check access equivalent: Mia's effective assignments, including through groups
az role assignment list --assignee "mia.office@$DOMAIN" --all --include-groups --include-inherited \
  --query "[].{role:roleDefinitionName, scope:scope}" -o table
```

## Lab 2 Test as the member user

```bash
# Sign in as Mia (MFA registration required on first sign-in)
az logout
az login --username "mia.office@$DOMAIN"

az group list -o table            # Expect: rg-harvest-lab only

# Allowed: build inside the boundary (empty VNet, free)
az network vnet create --resource-group rg-harvest-lab --name vnet-harvest-lab --location eastus \
  --address-prefixes 10.0.0.0/16 --subnet-name default --subnet-prefixes 10.0.0.0/24 \
  --tags project=az104-day1-rbac

# Blocked: grant access (expect AuthorizationFailed)
az role assignment create --assignee "ana.harvest@$DOMAIN" --role Reader \
  --scope $(az group show --name rg-harvest-lab --query id -o tsv)

# Blocked: act above scope (expect AuthorizationFailed on resourcegroups/write)
az group create --name rg-mia-test --location eastus

az logout
az login   # back to the admin account
```

## Elevate access recovery

```bash
# Global Administrator only: grants User Access Administrator at root scope "/"
az rest --method post --url '/providers/Microsoft.Authorization/elevateAccess?api-version=2016-07-01'

# After fixing access, remove the root assignment
az role assignment delete --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role 'User Access Administrator' --scope '/'
```

## Teardown

```bash
# 1. Resource group (removes the VNet and the group's Contributor assignment)
az group delete --name rg-harvest-lab --yes

# 2. Users (soft delete, restorable for 30 days)
for U in ana.harvest joe.picker mia.office; do az ad user delete --id "$U@$DOMAIN"; done
GUEST=$(az ad user list --filter "userType eq 'Guest'" --query "[?displayName=='Fieldwise Consultant'].id" -o tsv)
az ad user delete --id "$GUEST"

# 3. Permanently delete from Deleted users
az rest --method get --url 'https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user' \
  --query "value[].{name:displayName, id:id}" -o table
for ID in $(az rest --method get --url 'https://graph.microsoft.com/v1.0/directory/deletedItems/microsoft.graph.user' --query "value[].id" -o tsv); do
  az rest --method delete --url "https://graph.microsoft.com/v1.0/directory/deletedItems/$ID"
done

# 4. Groups (Security groups are not restorable)
az ad group delete --group grp-harvest
az ad group delete --group grp-farm-ops
```

## Verify teardown

```bash
az group list -o table                                   # NetworkWatcherRG only
az resource list -o table                                # Network Watchers only
az ad user list --query "[].displayName" -o tsv          # Admin account only
az ad group list --query "[].displayName" -o tsv         # Empty
az role assignment list --all --query "[?principalType=='Group']" -o table   # Empty
```

## Repo commands

```bash
# Scaffold
mkdir -p week-02-security-identity/azure-entra-id-rbac/images/{diagrams,screenshots} && touch week-02-security-identity/azure-entra-id-rbac/{README.md,notes.md,commands.md}

# Commit and push
git add week-02-security-identity/azure-entra-id-rbac && git commit -m "Add AZ-104 Entra ID and RBAC notes and labs" && git push
```
