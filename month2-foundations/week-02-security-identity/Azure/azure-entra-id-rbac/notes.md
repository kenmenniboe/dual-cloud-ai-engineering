# Microsoft Entra ID and Azure RBAC: Reference Notes

AZ-104 domain: **Manage Azure identities and governance**. These notes cover users, groups, licensing, external users, SSPR, and role-based access control (RBAC). A guided console tour and two hands-on labs follow the concepts.

---

## Table of contents

- [The big picture](#the-big-picture)
- [How the pieces connect in the portal](#how-the-pieces-connect-in-the-portal)
- [Current portal changes to know](#current-portal-changes-to-know)
- **Concepts**
  - [Module 1 Entra ID vs AD DS, tenants vs subscriptions](#module-1-entra-id-vs-ad-ds-tenants-vs-subscriptions)
  - [Module 2 Users](#module-2-users)
  - [Module 3 Groups](#module-3-groups)
  - [Module 4 Editions and licenses](#module-4-editions-and-licenses)
  - [Module 5 External users with B2B collaboration](#module-5-external-users-with-b2b-collaboration)
  - [Module 6 Self-service password reset](#module-6-self-service-password-reset)
  - [Module 7 Entra roles vs Azure roles](#module-7-entra-roles-vs-azure-roles)
  - [Module 8 Role assignments and built-in roles](#module-8-role-assignments-and-built-in-roles)
  - [Module 9 Scopes, inheritance and effective access](#module-9-scopes-inheritance-and-effective-access)
- **Hands-on**
  - [Lab overview](#lab-overview)
  - [Part 0 Console tour](#part-0-console-tour)
    - [T1 Tenant overview](#t1-tenant-overview)
    - [T2 The scope tree](#t2-the-scope-tree)
    - [T3 Access through IAM](#t3-access-through-iam)
  - [Lab 1 Build the identities](#lab-1-build-the-identities)
    - [Step 1 Check for a premium trial](#step-1-check-for-a-premium-trial)
    - [Step 2 Create three test users](#step-2-create-three-test-users)
    - [Step 3 Create two security groups](#step-3-create-two-security-groups)
    - [Step 4 Invite a guest user](#step-4-invite-a-guest-user)
    - [Step 5 Redeem the guest invitation](#step-5-redeem-the-guest-invitation)
    - [Step 6 External collaboration settings](#step-6-external-collaboration-settings)
    - [Step 7 SSPR and the authentication methods policy](#step-7-sspr-and-the-authentication-methods-policy)
  - [Lab 2 Grant and test access](#lab-2-grant-and-test-access)
    - [Step 1 Create a resource group](#step-1-create-a-resource-group)
    - [Step 2 Assign Contributor to the group](#step-2-assign-contributor-to-the-group)
    - [Step 3 Check access before signing in](#step-3-check-access-before-signing-in)
    - [Step 4 Sign in as the test user](#step-4-sign-in-as-the-test-user)
    - [Step 5 Build inside the boundary](#step-5-build-inside-the-boundary)
    - [Step 6 Test what Contributor blocks](#step-6-test-what-contributor-blocks)
  - [Teardown](#teardown)
- [Troubleshooting log](#troubleshooting-log)
- [Selection cheat sheet](#selection-cheat-sheet)
- [Acronyms](#acronyms)

---

## The big picture

![Big picture](images/diagrams/00-big-picture.svg)

Every access decision in Azure answers two questions. **Who are you?** is authentication, handled by Microsoft Entra ID. **What are you allowed to do?** is authorization, handled by Azure RBAC (Role-Based Access Control). One sentence ties the whole topic together:

> **A person from the tenant gets a role at a spot in the scope tree.**

Modules 1–6 build the *person* (users, groups, guests, licenses, sign-in methods). Modules 7–9 decide the *role* and the *spot*.

## How the pieces connect in the portal

![Where everything lives](images/diagrams/01-where-everything-lives.svg)

Azure keeps two lists that work together. The **tenant** lives in the Microsoft Entra admin center (`entra.microsoft.com`). It answers "who exists?": every user, group and guest, plus the settings attached to people (licenses, SSPR) and the Entra roles that grant power over the directory.

The **scope tree** lives in the Azure portal (`portal.azure.com`). It answers "where do things live, and who pays?": management groups hold subscriptions, subscriptions hold resource groups, and resource groups hold resources. Each subscription trusts exactly one tenant, which is how the portal knows whose sign-in to accept.

The two lists meet on the **Access control (IAM)** blade, which exists at every level of the scope tree. Adding a role assignment there means picking a user or group *from the tenant* and giving it a role *at that scope*.

> [!NOTE]
> The Entra admin center menu has no subscriptions, resource groups or Azure roles. The Azure portal's scope tree has no user management. The interface itself shows the two separate systems.

## Current portal changes to know

Older course videos and study guides may show screens that no longer exist. These were checked against the live portal in November 2026.

| Change | What it means |
|---|---|
| Azure AD → **Microsoft Entra ID** | Same service, new name. The exam uses "Entra". Azure AD Connect is now **Microsoft Entra Connect**. |
| Classic Service Administrator and Co-Administrator **retired** (August 31, 2024) | The Classic administrators tab is gone. The subscription creator becomes RBAC **Owner**. |
| Legacy per-user MFA and SSPR method lists **retired** (September 30, 2025) | Sign-in and reset methods live in one **Authentication methods policy**. Security questions are the only method still set in the SSPR blade. |
| License assignment moved to the **Microsoft 365 admin center** | Entra **Licenses → All products** shows *"Adding, removing, and reprocessing licensing assignments is only available within the M365 Admin Center."* The concepts (group-based licensing, Reprocess) are unchanged. |
| Azure AD B2C closed to new customers (May 1, 2025) | Customer sign-up for apps (CIAM) is now **Microsoft Entra External ID**. |
| Mandatory Azure MFA | The Azure portal requires MFA for every user. Phase 2 extends this to Azure CLI, PowerShell and IaC tools. |

---

## Module 1 Entra ID vs AD DS, tenants vs subscriptions

![Tenant and subscriptions](images/diagrams/m1-tenant-subscriptions.svg)

### The big idea

Microsoft Entra ID is Microsoft's cloud identity service. It answers "who are you?" for Azure, Microsoft 365 and thousands of web apps. Picture a farm's front gate: the guard checks your badge and lets you onto the property. Entra ID is that guard. The keys to individual barns are a separate system, Azure RBAC.

For about twenty years, companies answered "who are you?" with **AD DS (Active Directory Domain Services)**. It ran on Windows Server domain controllers inside the company's building. PCs joined the domain, passwords were checked with **Kerberos**, apps looked people up with **LDAP (Lightweight Directory Access Protocol)**, and admins organized people into **OUs (Organizational Units)** and pushed settings with **GPOs (Group Policy Objects)**. It assumed everyone sat inside the office network.

When work moved to the internet, those protocols didn't travel well, so Entra ID uses web sign-in protocols instead: **OAuth 2.0 (Open Authorization)**, **OIDC (OpenID Connect)** and **SAML (Security Assertion Markup Language)**. Microsoft runs the service, so there are no servers to patch.

> [!IMPORTANT]
> Entra ID is **not** "AD moved to the cloud". It has no domain controllers, no OUs (the directory is flat), no GPOs, and no Kerberos or LDAP.

When an organization signs up, Microsoft creates a **tenant**, the organization's own private instance of Entra ID, holding its users, groups and apps. A **subscription** is different: it's the container where Azure resources live and the account that gets billed. The tenant is the employee list; subscriptions are company credit cards. A company can have many cards, but each card belongs to exactly one company.

### Key points

A tenant can hold many subscriptions, but **each subscription trusts exactly one tenant**, and that's where it gets its list of people. That's why one staff account works across both a Prod and a Dev subscription. The tenant answers "who"; the subscription answers "where resources live and who pays".

Because a subscription's permissions point at people in its tenant, **moving a subscription to another tenant wipes its access**. Resources keep running, but every RBAC role assignment is deleted, since those identities don't exist in the new tenant. After a merger, the role assignments must be re-created. The subscription's **Change directory** button is where this move starts.

Every tenant starts with a built-in `name.onmicrosoft.com` domain that **can never be renamed or removed**. To sign in with a real email address, you add a custom domain and prove ownership with a DNS (Domain Name System) **TXT** or **MX (Mail Exchanger)** record. You add a new domain; you don't rename the old one.

Companies that still run AD DS use **Microsoft Entra Connect** (or the lighter **Entra Cloud Sync**) to copy users up to Entra ID, so the same password works everywhere. This is **hybrid identity**. On-premises AD remains the source of truth.

Older apps that only speak Kerberos or LDAP can't use Entra ID directly. **Microsoft Entra Domain Services** provides Microsoft-managed domain controllers in Azure for those lift-and-shift apps.

### Menniboe Farm story

Menniboe Farm signs up and receives the tenant `menniboefarm.onmicrosoft.com`, then verifies `menniboefarm.com` so staff sign in with their real email. It creates Prod and Dev subscriptions, both trusting the same tenant. With no office servers, the farm goes cloud-only and skips AD DS.

---

## Module 2 Users

![Users](images/diagrams/m2-users.svg)

### The big idea

A user is a digital identity record, like an employee's badge file at the front office. It holds who the person is (display name, sign-in name, job title, department) and lets them sign in. Groups, licenses and access all attach to these records.

Every user has two traits. **User type** is what kind of person they are: a **Member** is inside your organization, and a **Guest** is an invited outsider. **Source** is where the record came from: created in Entra ID (**cloud-only**) or copied from on-premises AD DS (**synced**). The source decides who's allowed to edit the record.

### Key points

Every user signs in with a **UPN (User Principal Name)** that looks like an email address, such as `ana@menniboefarm.com`. UPN and display name are the only required fields; Azure can generate a temporary password that the user changes at first sign-in. The domain after the @ must be one the tenant owns.

**Where a user came from decides where you edit them.** Cloud-only users are edited in the portal. For synced users, on-premises AD owns name, job title and department, so those fields are greyed out in Entra ID; you edit them on-premises and the next sync carries the change up.

A user needs a **usage location** (for example, United States) before a license can be assigned, because Microsoft services vary by country. **Usage location** (a dropdown under *Settings*) is different from **Office location** (free text under *Job information*), and licensing reads only usage location.

**Bulk create, Bulk invite and Bulk delete** use a downloadable CSV (Comma-Separated Values) template, one row per person.

Deleting a user is a **soft delete for 30 days**. The user moves to **Deleted users** and can be restored with properties intact; after 30 days they're permanently deleted. While deleted, the UPN is renamed with the Object ID prefix so the original name is freed. For temporary absences, **Block sign-in** keeps the account intact.

**User Administrator** is the least-privilege role for managing users. Global Administrator is far more power than onboarding needs.

### Menniboe Farm story

Each spring the farm bulk-creates seasonal pickers with department `Harvest` and usage location `US`. In the fall it blocks their sign-in instead of deleting them, so the accounts can be switched back on next season.

---

## Module 3 Groups

![Groups](images/diagrams/m3-groups.svg)

### The big idea

A group lets you make an access decision once and have it apply to everyone in it. Change membership, and access follows. In practice, admins give access to groups, not to individual users.

Two choices define a group. **Group type** is what it's for: a **Security group** grants access to resources, apps and licenses; a **Microsoft 365 group** gives a team a shared mailbox, calendar, SharePoint site and Teams team. **Membership type** is how people get in: **Assigned** (added by hand) or **Dynamic** (a rule adds and removes members automatically).

### Key points

Security groups grant access, and Microsoft 365 groups share collaboration tools. Microsoft 365 groups can include guests, but they hold users only, not devices or other groups.

A dynamic rule such as `(user.department -eq "Harvest")` keeps a group current on its own. Because the rule owns the membership, **you can't add members to a dynamic group by hand**. Dynamic membership requires **Entra ID P1** for its members, and updates can take a few minutes.

**Dynamic device** rules (for example, all Windows devices) work only in **Security groups**, because Microsoft 365 groups can't hold devices. For any group scenario: decide what it's for (access or devices → Security; mailbox or Teams → Microsoft 365), then how members get in (by hand → Assigned; by rule → Dynamic).

**Only Security groups can nest.** Nesting keeps large organizations tidy but makes it harder to see who actually has access.

**Owners** manage a group's membership without an admin role. A group that will hold an Entra admin role must be marked **role-assignable at creation**; this needs P1 and can't be changed later. A deleted Microsoft 365 group can be restored for 30 days; **a deleted Security group can't be restored**.

### Menniboe Farm story

A dynamic Security group `grp-harvest` with the rule `user.department -eq "Harvest"` picks up spring pickers automatically. A second dynamic Security group with a device rule collects every Windows laptop. Office staff share a Microsoft 365 group for their inbox and Teams workspace.

---

## Module 4 Editions and licenses

![Licensing](images/diagrams/m4-licensing.svg)

### The big idea

Entra ID comes in editions. **Free** comes with every Azure subscription. **Premium P1** adds automation and access policy. **Premium P2** adds advanced protection for admin accounts and risky sign-ins. Each higher edition includes everything below it. A **license** connects a person to a paid edition or product, and licenses can be handed out to a group so new members receive them automatically.

### Key points

| Edition | Adds |
|---|---|
| **Free** | Users, groups, basic SSO (Single Sign-On), security defaults, up to 50,000 directory objects |
| **Premium P1** | Dynamic groups, group-based licensing, role-assignable groups, CA (Conditional Access), SSPR for regular users, password writeback |
| **Premium P2** | Everything in P1, plus PIM (Privileged Identity Management), ID Protection, access reviews |

The requirement decides the license. "Automatically", "conditional" or "reset their own password" points to **P1**. "Just-in-time admin access" or "risky sign-ins" points to **P2**. PIM grants admin powers only when needed and only for a limited time. ID Protection detects suspicious sign-ins.

Licenses can be assigned **directly** or through **group-based licensing** (P1). A user can hold the same license both ways. To remove an inherited license, remove the user from the group.

With group-based licensing, a user with **no usage location** shows as an error on the group while everyone else is licensed. **When one user fails and the rest succeed, check that user's usage location first.** Other causes are running out of licenses or two licenses with conflicting service plans. After fixing the cause, select **Reprocess**. License assignment and reprocessing now happen in the **Microsoft 365 admin center**.

A license bundles **service plans** (Exchange, Teams, SharePoint, and others) that can be switched off individually.

> [!WARNING]
> A tenant created by signing up for Azure with a **personal email** gets Entra ID Free, and its premium trial runs through a Microsoft checkout that asks for **payment details**. At the time of these notes, it became a paid subscription after 30 days unless cancelled.

### Menniboe Farm story

Microsoft 365 licenses are assigned to the dynamic `grp-harvest` group. Pickers bulk-created with department `Harvest` and usage location `US` are licensed within minutes. One picker missing a usage location shows as an error on the group until the field is set and the group is reprocessed.

---

## Module 5 External users with B2B collaboration

![B2B guests](images/diagrams/m5-b2b-guests.svg)

### The big idea

**B2B (Business-to-Business) collaboration** lets outsiders use your resources with **the account they already have**, so you never manage their password. In your tenant, they appear as users with **userType = Guest**. Their employer vouches for who they are; you decide what they can reach, through groups and RBAC like any member.

### Key points

A guest signs in with a home identity: another Entra tenant, an **MSA (Microsoft Account)**, Google, or an email **OTP (One-Time Passcode)**. When their own organization disables them, their access to you stops too.

Guests are invited from **Users → New user → Invite external user**, or in bulk with a CSV file. Until redeemed, the invitation shows **Pending acceptance**, and the guest can't get in. After redemption it shows **Accepted**, and the **Reset redemption status** option lets the guest redeem again with a different account without deleting them. A guest UPN has the form `email_domain#EXT#@tenant.onmicrosoft.com`, where **#EXT#** marks an external identity.

**External collaboration settings** (Entra ID → External Identities) control the whole tenant:

| Setting | Options | Default |
|---|---|---|
| Guest user access | Same as members / Limited / Most restrictive | Limited |
| Guest invite settings | Anyone including guests / Members and specific admin roles / Only specific admin roles / No one | Anyone (most inclusive) |
| Guest self-service sign up via user flows | Yes / No | No |
| External user leave settings | Yes / No | Yes |
| Collaboration restrictions | Any domain / Deny listed domains / Allow only listed domains | Any domain |

The **Guest Inviter** role lets a non-admin send invitations. **Cross-tenant access settings** add inbound and outbound rules for specific partner tenants, such as trusting their MFA, and they're also checked when an invitation is sent.

**B2B is for partners; Microsoft Entra External ID is for customers.** Letting the public sign up for your app is **CIAM (Customer Identity and Access Management)**. Azure AD B2C (Business-to-Consumer) closed to new customers on May 1, 2025.

### Menniboe Farm story

A crop consultant from Fieldwise is invited as a guest and signs in with her Fieldwise account. Adding `fieldwise.com` to the collaboration allow list limits invitations to approved partners. When her contract ends, her guest account is deleted; her Fieldwise account is untouched.

---

## Module 6 Self-service password reset

![SSPR](images/diagrams/m6-sspr.svg)

### The big idea

**SSPR (Self-Service Password Reset)** lets users reset a forgotten password or unlock their account at any hour, after proving who they are with methods they registered earlier. Configuration lives in two places: the **Password reset** blade decides *who* can use it and *how strict* it is, and the **Authentication methods policy** decides *which* methods are allowed. For hybrid companies, **password writeback** sends a cloud reset down to on-premises AD DS.

### Key points

Scope is **None, Selected or All**. **Selected accepts exactly one group**, so two departments need one combined group (or nesting both groups inside it). There's only one SSPR scope per tenant.

Resets require **1 or 2 methods**. Two is safer because a stolen phone alone isn't enough. Registration can be required at sign-in, with users reconfirming every **180 days** by default.

Methods include Microsoft Authenticator, email, mobile phone (**SMS (Short Message Service)** or voice), office phone and security questions. **Security questions work for SSPR only**, never MFA, and they're the only method still configured in the SSPR blade; every other method lives in the Authentication methods policy.

**Admins always get the strict version.** SSPR is always enabled for admin roles, requires two methods, and blocks security questions, whatever the settings say.

**Password writeback** (P1, through Entra Connect or Cloud Sync) keeps hybrid users' passwords in sync with on-premises AD.

Regular users need **P1**. On a Free tenant, the Password reset blade shows only an upgrade page. Users register at `aka.ms/ssprsetup` and reset at `aka.ms/sspr`.

### Menniboe Farm story

SSPR is scoped to one group containing both Harvest and Office staff and requires the Authenticator app. A picker who forgets her password on a Saturday resets it from her phone in minutes instead of waiting until Monday.

---

## Module 7 Entra roles vs Azure roles

![Two role systems](images/diagrams/m7-two-role-systems.svg)

### The big idea

Azure has **two separate permission systems**. **Entra roles** (directory roles) control the directory: users, passwords, groups, apps, licenses. Examples are Global Administrator, User Administrator, Helpdesk Administrator, License Administrator and Guest Inviter. **Azure roles**, managed by **Azure RBAC**, control resources: **VMs (Virtual Machines)**, storage, **VNets (Virtual Networks)**, databases. Every resource request goes through **ARM (Azure Resource Manager)**, which checks Azure roles. They're managed on each scope's **Access control (IAM)** blade, where IAM stands for Identity and Access Management.

On the farm, Entra roles are the front office managing staff files; Azure roles are the keys to barns and tractors.

### How the two worlds relate

**A Global Administrator has no access to Azure resources by default.** This keeps a directory admin's mistake or compromised account from touching production. In the lab tenant, the same account held **Global Administrator** (Entra role) and, separately, **Owner** (Azure role) on each subscription it created.

**Elevate access** is the one bridge: a Global Administrator turns on *Access management for Azure resources* under Entra ID → Properties. This grants **User Access Administrator at root scope ( / )**, covering every subscription and **MG (Management Group)**. Use it to recover an orphaned subscription, then turn it off. The Subscriptions page links to this setting: *"Global administrators can manage all subscriptions in this list by updating their policy setting here."*

**AUs (Administrative Units)** narrow Entra roles to part of the directory, such as Helpdesk Administrator for a "Field Office" AU only. AU-scoped admins need P1. **Restricted management AUs** (GA (General Availability) in June 2025) lock their objects even from tenant-wide admins.

Classic Service Administrator and Co-Administrator roles were retired on August 31, 2024.

### Menniboe Farm story

The office manager holds **User Administrator** to onboard pickers but has no resource access. The IT contractor holds **Contributor** on Prod but can't create users. When the subscription's only Owner leaves, the farm's administrator elevates access, assigns a new Owner, and turns elevation off.

---

## Module 8 Role assignments and built-in roles

![Role assignment anatomy](images/diagrams/m8-role-assignment-anatomy.svg)

### The big idea

A **role assignment** always has three parts: **who** (security principal), **what** (role definition), and **where** (scope). Remove any part and there's no access. Principals are users, groups, service principals (an app's identity), and **MIs (Managed Identities)**, which are identities Azure manages for a resource so it can authenticate without stored secrets.

### What's inside a role definition

A role definition is **JSON (JavaScript Object Notation)**. **Actions** are control-plane operations that manage a resource (create, configure, delete). **DataActions** are data-plane operations on the data inside it (reading a blob). **NotActions** subtracts from the role's own Actions; it's **not a deny**, so another role can still grant the same permission. **AssignableScopes** limits where a custom role can be assigned.

### Built-in roles used most

| Role | Manage resources | Grant access |
|---|---|---|
| **Owner** | Yes | Yes |
| **Contributor** | Yes | No |
| **Reader** | View only | No |
| **User Access Administrator** | No | Yes |
| **Role Based Access Control Administrator** | No | Yes, limitable with conditions |

In the portal, Owner, Contributor, User Access Administrator and Role Based Access Control Administrator appear under **Privileged administrator roles**; narrower roles appear under **Job function roles**.

Service-specific roles narrow scope further: Virtual Machine Contributor, Network Contributor, Storage Account Contributor, and the data-plane roles Storage Blob Data Reader and Contributor. A Contributor on a storage account can configure it but can't read blobs with Entra sign-in until given a Storage Blob Data role.

Custom roles are created from **Access control (IAM) → Add → Add custom role** (clone, start from scratch, or JSON). Azure custom roles need no license; custom Entra roles need P1. Creating a role assignment requires `Microsoft.Authorization/roleAssignments/write`, held only by Owner, User Access Administrator and Role Based Access Control Administrator, which is why a Contributor can't grant access to anyone.

### Menniboe Farm story

The harvest app's VM has a managed identity with **Storage Blob Data Contributor** on the yield-reports container, so it writes reports without stored keys. The IT contractor (Contributor) can manage the storage account but can't read the reports.

---

## Module 9 Scopes, inheritance and effective access

![Scope inheritance](images/diagrams/m9-scope-inheritance.svg)

### The big idea

Scope decides **how far access reaches**. The hierarchy runs from management group to subscription to resource group to resource, and **a role assigned at any level flows down** to everything beneath it, including resources created later. Every tenant has one **Tenant Root Group** at the top. A role at a high scope is a master key, so best practice is the **narrowest scope that does the job**, assigned to **groups**.

### How access adds up

**Inherited access can't be removed at the lower level.** On a resource group, an assignment made at the subscription shows **Scope: Subscription (Inherited)** and has to be removed at the subscription. Direct assignments show **This resource**.

**RBAC is additive.** Effective access is the **union** of direct assignments, group assignments and inherited assignments. Reader on a subscription plus Contributor on one resource group means Contributor in that resource group and Reader everywhere else.

**Deny assignments always win**, even over Owner. Admins can't create them directly; Azure creates them for features such as Azure Managed Applications and deployment stacks with deny settings.

### Checking what someone can do

**Check access** on any IAM blade shows every role and deny assignment affecting a user, group or managed identity at that scope, including inherited ones, and the **Group assignment** column names the group that grants it. **View my access** does the same for yourself. New assignments can take a few minutes to apply. **Resource locks** are governance, not RBAC; a delete lock stops even an Owner.

### Menniboe Farm story

`grp-advisors` holds Reader at the subscription, while `grp-ops` holds Contributor only on `rg-harvest-prod`. A consultant added to both gets Contributor in that one resource group and Reader everywhere else. Removing her from `grp-ops` returns her to Reader without editing a single assignment.

---

## Lab overview

![Lab overview](images/diagrams/lab-overview.svg)

| | |
|---|---|
| **What we build** | A console tour of tenant, scope tree and IAM; three member users, two Security groups and one guest; a resource group with a Contributor assignment to a group, tested by signing in as a member |
| **What it proves** | Identities live in the tenant and access lives in the scope tree; a group's role reaches its members; access stops at the scope boundary; Contributor builds but can't grant access or act above its scope |
| **How it connects** | Part 0 maps the portal, Lab 1 builds the people, Lab 2 gives them a role at one spot and tests the result |
| **Cost** | $0 (Entra ID Free, an empty VNet, and an empty resource group) |
| **Subscription used** | Elite Subscription 1 |

---

## Part 0 Console tour

### T1 Tenant overview

**Why this step:** before building anything, see the tenant itself. Every user, group and setting created later lands inside this one directory.

**Console:** Azure portal → **Microsoft Entra ID → Overview**, or `entra.microsoft.com` → **Entra ID → Overview**.

| Field | Meaning | Lab value |
|---|---|---|
| Name | Tenant display name | Default Directory (the default for a tenant created by an Azure sign-up) |
| Tenant ID | Tenant GUID (Globally Unique Identifier) | *(redacted)* |
| Primary domain | Built-in `onmicrosoft.com` domain | *(redacted)* |
| License | Entra edition | Microsoft Entra ID Free |
| Counters | Users / Groups / Applications / Devices | 1 / 0 / 0 / 0 |

![Tenant overview](images/screenshots/t1-tenant-overview.png)

The **Microsoft Entra Connect** card showed *Not enabled, Sync has never run*, so this is a **cloud-only tenant**, and every user created here is editable in the portal. The alert *"Migrate to the converged Authentication methods policy"* is the Module 6 retirement appearing in a live tenant. The feature highlights map to the modules: Identity Protection and Access reviews (P2), Build a consumer app (External ID), Entra Domain Services (legacy apps). The admin's own card shows **Global Administrator**, an Entra role.

The same tenant in the Entra admin center:

![Entra admin center](images/screenshots/t1-entra-admin-center.png)

| Entra admin center menu | Module |
|---|---|
| Users, Groups | 2, 3 |
| Domain names, Entra Connect, Domain services | 1 |
| External Identities, Cross-tenant synchronization | 5 |
| Password reset, Authentication methods | 6 |
| Roles & admins | 7 |

### T2 The scope tree

**Why this step:** T1 showed the "who". T2 shows the "where", and the field that ties a subscription back to its tenant.

**Console:** Azure portal → **Subscriptions** → select subscription → **Overview**; then **Management groups**; then **Resource groups**.

![Subscriptions list](images/screenshots/t2-subscriptions.png)

![Subscription overview](images/screenshots/t2-subscription-overview.png)

| Field | Meaning | Lab value |
|---|---|---|
| Directory | The tenant this subscription trusts | Default Directory |
| My role | The admin's **Azure** role here | Owner |
| Parent management group | Where the subscription sits in the tree | Tenant Root Group |
| Change directory (button) | Moves the subscription to another tenant, which deletes its role assignments | Not used |

![Management groups](images/screenshots/t2-management-groups.png)

![Resource groups](images/screenshots/t2-resource-groups.png)

The lab tenant's actual tree:

![Lab tenant scope tree](images/diagrams/lab-tenant-scope-tree.svg)

`NetworkWatcherRG` is created automatically by Azure the first time a VNet is created in a region. It's free.

### T3 Access through IAM

**Why this step:** IAM is where the tenant and the scope tree meet. Reading the admin's own Owner assignment shows the three parts of a role assignment and the difference between direct and inherited access.

**Console:** Subscription → **Access control (IAM) → Role assignments**; then **Check access → View my access**; then NetworkWatcherRG → **Access control (IAM) → Role assignments**.

![Subscription IAM](images/screenshots/t3-subscription-iam.png)

| Column | Value | Part of the assignment |
|---|---|---|
| Name / Type | Admin account / User | Who |
| Role | Owner | What |
| Scope | This resource | Where (direct) |

![View my access](images/screenshots/t3-view-my-access.png)

![Inherited on resource group](images/screenshots/t3-rg-inherited.png)

On NetworkWatcherRG, the same assignment shows **Subscription (Inherited)**. Nothing was assigned on the resource group, yet access flowed down from the subscription. Other items on these screens: **Deny assignments (0)**; **Eligible assignments** (PIM, a P2 feature); **Condition → Add** (assignment conditions); **Privileged** (Owner and Contributor count as privileged roles).

---

## Lab 1 Build the identities

### Step 1 Check for a premium trial

**Why this step:** dynamic groups, group-based licensing and SSPR for users need P1. P2 includes P1.

**Console:** Entra admin center → **Billing → Licenses → All products**.

![Licenses with no SKUs](images/screenshots/l1-licenses-no-skus.png)

> [!WARNING]
> **Try / Buy** was greyed out, the list said *"No account skus found"* (no licenses owned), and a banner said license assignment is now only available in the Microsoft 365 admin center.

The trial was found at **Billing → Trials** (*100 licenses for 30 days*):

![Trials page](images/screenshots/l1-trials-page.png)

Selecting **Activate** opened a Microsoft checkout that required payment details and became a 1-year paid subscription unless cancelled before the trial ended:

![Trial checkout](images/screenshots/l1-trial-checkout.png)

**Decision:** the trial was **not activated**, and Lab 1 ran on **Entra ID Free**. Premium features were shown where they live instead of run live. In AZ-104, only dynamic groups, group-based licensing and SSPR depend on P1/P2; everything else in the exam works on Free.

### Step 2 Create three test users

**Why this step:** groups, the guest comparison and Lab 2 all need people. Department powers dynamic-group rules, and usage location is what licensing reads.

**Console:** Entra ID → **Users → All users → + New user → Create new user**

| Display name | Username | Job title | Department | Usage location |
|---|---|---|---|---|
| Ana Harvest | `ana.harvest` | Picker | Harvest | United States |
| Joe Picker | `joe.picker` | Picker | Harvest | *(blank, on purpose)* |
| Mia Office | `mia.office` | Office Manager | Office | United States |

| Tab | Field | Value |
|---|---|---|
| Basics | User principal name | Username + `onmicrosoft.com` domain from the dropdown |
| Basics | Mail nickname | Derive from user principal name (checked) |
| Basics | Display name | From table |
| Basics | Password | Auto-generate (checked); **copy it before creating** |
| Basics | Account enabled | Checked |
| Properties | First / Last name | e.g. Ana / Harvest |
| Properties | User type | Member |
| Properties | Job title, Department | From table |
| Properties | Company name | `Menniboe Farm` |
| Properties → Settings | **Usage location** | From table |
| Assignments | — | Leave empty |
| Review + create | — | Create |

**Error caught before Create:** the country was typed into **Office location** (free text under *Job information*), not **Usage location** (the dropdown under *Settings*), and the review screen showed no usage location:

![Create user review](images/screenshots/l1-create-user-review.png)

**Fix:** Properties tab → clear Office location → set **Usage location** → Review + create shows *Usage location: United States*.

![Users created](images/screenshots/l1-users-created.png)

All users show **User type: Member** and **On-premises sync: No** (cloud-only). The admin account created by a personal Microsoft account has an email-style UPN instead of `name@domain`.

### Step 3 Create two security groups

**Why this step:** access goes to groups, not individuals. `grp-farm-ops` becomes the "who" in Lab 2.

**Console:** Entra ID → **Groups → All groups → + New group**

| Field | grp-harvest | grp-farm-ops |
|---|---|---|
| Group type | Security | Security |
| Group description | Harvest crew - pickers | Farm operations team - manages farm resources |
| Membership type | Assigned | Assigned |
| Owners | Admin account | Admin account |
| Members | Ana Harvest, Joe Picker | Mia Office |

![Membership type options](images/screenshots/l1-membership-type.png)

The dropdown lists **Dynamic User** and **Dynamic Device** even on Free, but dynamic membership requires P1 for its members. Dynamic Device appears because the type is Security. The **"Microsoft Entra roles can be assigned to the group"** switch didn't appear at all, because role-assignable groups need P1.

![Groups created](images/screenshots/l1-groups.png)

Each group has an **Object Id** (GUID). Role assignments store this ID, not the name.

### Step 4 Invite a guest user

**Why this step:** compare a Member (account owned by the tenant) with a Guest (an outsider using their own account).

**Console:** Entra ID → **Users → All users → + New user → Invite external user**

| Tab | Field | Value |
|---|---|---|
| Basics | Email | A second email address you own |
| Basics | Display name | `Fieldwise Consultant` |
| Basics | Send invite message | Checked |
| Basics | Message | `Welcome to the Menniboe Farm crop-data project.` |
| Properties | User type | Guest |
| Properties | Job title / Company | `Crop Consultant` / `Fieldwise` |
| Properties → Settings | Usage location | United States |
| Review + invite | — | Invite (no password field, unlike a member) |

![Guest in users list](images/screenshots/l1-guest-in-users.png)

### Step 5 Redeem the guest invitation

**Why this step:** a guest object exists at invitation, but it only works after redemption.

| Stage | Where | Result |
|---|---|---|
| Before | Guest profile → Overview → **B2B invitation** | Invitation state: **Pending acceptance**, with Resend invitation |
| Redeem | Private browser window → second email → Accept invitation → sign in → **Accept** on the permissions screen | Lands on My Apps |
| After | Refresh guest profile | Invitation state: **Accepted**, with Reset redemption status |

![Guest pending](images/screenshots/l1-guest-pending.png)

![Guest consent screen](images/screenshots/l1-guest-consent.png)

The consent screen lets the guest agree to share profile data with the tenant. *"Default Directory has not provided links to their terms"* appears because no privacy statement is set (Entra ID → Properties).

![Guest My Apps](images/screenshots/l1-guest-myapps.png)

![Guest accepted](images/screenshots/l1-guest-accepted.png)

The guest UPN contains **#EXT#**. **Group memberships, Applications, Assigned roles and Assigned licenses are all 0**: signing in proves who the guest is, but access only comes from groups and roles. **Revoke sessions** appears once real sign-in sessions exist. **Convert to internal user** turns a guest into a member account.

### Step 6 External collaboration settings

**Why this step:** these settings govern guests for the entire tenant. Viewed only; nothing saved.

**Console:** Entra ID → **External Identities → External collaboration settings**

![External collaboration settings](images/screenshots/l1-external-collab.png)

| Setting | Lab tenant value | Note |
|---|---|---|
| Guest user access | Limited access | Safe default; guests can't browse the directory |
| Guest invite settings | Anyone, including guests | Most open; usually tightened to members or Guest Inviter |
| Self-service sign up | No | Invitation only |
| External users can leave | Yes | Recommended |
| Collaboration restrictions | Any domain | "Allow only specified domains" creates a partner allow list |

The banner noted that **Email one-time passcode** for guests moved to **All identity providers**.

### Step 7 SSPR and the authentication methods policy

**Why this step:** SSPR is configured in two places. One is locked on Free; the other isn't.

**Part A:** Entra ID → **Password reset**. On Free, the whole blade is replaced by an upgrade page:

![SSPR locked on Free](images/screenshots/l1-sspr-locked.png)

With P1, the blade contains:

| Page | Key setting |
|---|---|
| Properties | Enabled: None / Selected (one group) / All |
| Authentication methods | Methods required: 1 or 2; security questions |
| Registration | Require at sign-in; reconfirm every 180 days |
| Notifications | Notify users; notify admins on admin reset |
| On-premises integration | Password writeback |

Admins can always use SSPR, even on Free.

**Part B:** Azure portal → **Microsoft Entra ID → Security → Authentication methods → Policies** (or Entra admin center → Entra ID → Authentication methods → Policies).

![Authentication methods policies](images/screenshots/l1-auth-methods-policies.png)

The page states that a user in scope for a method can use it **for both authentication and password reset**: one converged list. No *Manage migration* button appeared because this tenant already runs only on the converged policy.

| Method | Lab tenant |
|---|---|
| Passkey (FIDO2 (Fast IDentity Online 2)) | On, all users |
| Microsoft Authenticator | On, all users |
| SMS | Off |
| Temporary Access Pass | On, all users |
| Hardware OATH (Open Authentication) tokens (Preview) | Off |
| Software OATH tokens | On, all users |
| Voice call | Off |
| Password | On, all users |
| Email OTP | On, all users |
| Certificate-based authentication, Verified ID, QR code | Off |

SMS and voice are off by default because phone codes can be stolen through SIM swapping. Two toolbar buttons are outside AZ-104 scope: **Add external multifactor authentication** (use a third-party MFA provider; greyed out in this Free tenant) and **Add telecom profile** (send SMS and voice codes through your own telephony provider).

---

## Lab 2 Grant and test access

![Lab 2 access boundary](images/diagrams/lab2-access-boundary.svg)

### Step 1 Create a resource group

**Why this step:** a dedicated resource group is the narrowest useful scope (least privilege), and the neighbouring NetworkWatcherRG gives a boundary to test.

**Console:** Azure portal → **Resource groups → + Create**

| Tab | Field | Value |
|---|---|---|
| Basics | Subscription | Elite Subscription 1 |
| Basics | Resource group | `rg-harvest-lab` |
| Basics | Region | East US (stores the group's metadata only) |
| Tags | project / owner | `az104-day1-rbac` / `farm-ops` |
| Review + create | — | Create |

![Resource group created](images/screenshots/l2-rg-created.png)

### Step 2 Assign Contributor to the group

**Why this step:** one role assignment combining all three parts: who = `grp-farm-ops`, what = Contributor, where = `rg-harvest-lab`. Assigning to the group means removing a person from the group removes their access.

**Console:** rg-harvest-lab → **Access control (IAM) → + Add → Add role assignment**

| Tab | Field | Value |
|---|---|---|
| Role | List | **Privileged administrator roles** |
| Role | Role | Contributor |
| Members | Assign access to | User, group, or service principal |
| Members | Members | `grp-farm-ops` |
| Members | Description | `Farm ops team can build and manage resources in the harvest lab` |
| Conditions / Assignment type | — | Defaults (Active) |
| Review + assign | — | Review + assign |

![Role assignments](images/screenshots/l2-role-assignments.png)

| Name | Type | Role | Scope |
|---|---|---|---|
| Admin account | User | Owner | Subscription (Inherited) |
| grp-farm-ops | Group | Contributor | This resource |

The member, Mia, isn't listed. Her access arrives through the group.

### Step 3 Check access before signing in

**Why this step:** Check access adds up direct, group and inherited assignments for one person.

**Console:** scope → **Access control (IAM) → Check access → Check access** → select **Mia Office**

![Check access on rg-harvest-lab](images/screenshots/l2-check-access-rg.png)

![Check access on NetworkWatcherRG](images/screenshots/l2-check-access-networkwatcher.png)

| Scope | Result |
|---|---|
| rg-harvest-lab | Contributor, This resource, **Group assignment: grp-farm-ops** |
| NetworkWatcherRG | Role assignments (0) |

### Step 4 Sign in as the test user

**Why this step:** Check access is Azure's report; signing in is the real test.

**Console:** private browser window → `portal.azure.com` → sign in as Mia with the temporary password.

First sign-in required a **password change** and **MFA registration with no skip option**. Security defaults require MFA registration, and the Azure portal requires MFA for every sign-in.

![Mia portal home](images/screenshots/l2-mia-home.png)

![Mia resource groups](images/screenshots/l2-mia-resource-groups.png)

![Mia subscriptions](images/screenshots/l2-mia-subscriptions.png)

| View | Admin sees | Mia sees |
|---|---|---|
| Resource groups | NetworkWatcherRG, rg-harvest-lab | rg-harvest-lab only |
| Subscriptions | Two subscriptions, My role: Owner | Elite Subscription 1 only, **My role: Resource access**, **Current cost: Unauthorized** |

"Resource access" means access to something inside the subscription without a role on the subscription itself. Reading costs needs a role at subscription scope.

### Step 5 Build inside the boundary

**Why this step:** Contributor promises create and manage. An empty VNet is free.

**Console (as Mia):** **Virtual networks → + Create**

| Tab | Field | Value |
|---|---|---|
| Basics | Subscription / Resource group | Elite Subscription 1 / rg-harvest-lab (the only option offered) |
| Basics | Name / Region | `vnet-harvest-lab` / East US |
| Security | Bastion, Firewall, DDoS (Distributed Denial of Service) Network Protection | All off (each costs money) |
| IP addresses | Address space / subnet | Default `10.0.0.0/16`, default subnet |
| Tags | project | `az104-day1-rbac` |

![VNet created by Mia](images/screenshots/l2-mia-vnet.png)

The VNet was created by Mia's account (the name was typed as `vnet-haverest-lab`; harmless). Azure automatically added **NetworkWatcher_eastus** to NetworkWatcherRG, which is a free platform action.

### Step 6 Test what Contributor blocks

**Why this step:** a good access test checks what the role blocks, not only what it allows.

| Test (as Mia) | Result | Reason |
|---|---|---|
| rg-harvest-lab → IAM → **+ Add** | *Add role assignment (disabled)*, *Add custom role (disabled)* | Contributor lacks `Microsoft.Authorization/roleAssignments/write` |
| **Resource groups → + Create** | *"You do not have permissions to create resource groups under subscription…"* | Creating a resource group is a subscription-level write; Mia's role is one level below |

![IAM add disabled](images/screenshots/l2-mia-iam-disabled.png)

![Create resource group denied](images/screenshots/l2-mia-create-rg-denied.png)

View my access and Check access still worked for Mia: reading who has access is allowed; changing it isn't.

---

## Teardown

Reverse order of creation.

| Step | Console | Verify |
|---|---|---|
| 1 | Mia's window → Sign out → close | — |
| 2 | **Resource groups → rg-harvest-lab → Delete resource group** → type the name → Delete | All resources shows only the two Network Watchers; the VNet and the group's role assignment are gone with the scope |
| 3 | **Users → All users** → select Ana, Joe, Mia, Fieldwise Consultant (not the admin) → Delete | **Deleted users** lists all four with a permanent deletion date 30 days out |
| 4 | **Deleted users** → select all four → Delete permanently | — |
| 5 | Microsoft Authenticator on the phone → remove the Mia Office entry | — |
| 6 | **Groups → All groups** → select both groups → Delete | **0 groups found**; Security groups can't be restored |
| 7 | Entra ID → Overview | Users 1, Groups 0, License: Microsoft Entra ID Free |

![Resource group deleting](images/screenshots/td-rg-deleting.png)

![All resources after delete](images/screenshots/td-all-resources.png)

![Deleted users](images/screenshots/td-deleted-users.png)

![Groups empty](images/screenshots/td-groups-empty.png)

![Tenant back to start](images/screenshots/td-tenant-overview-end.png)

Left in place on purpose: **NetworkWatcherRG** with its Network Watchers (free, platform-managed).

---

## Troubleshooting log

| # | Symptom | Cause | Fix / outcome |
|---|---|---|---|
| 1 | Licenses → All products: Try / Buy greyed out, "No account skus found" | Tenant created by an Azure sign-up with a personal email is on Entra ID Free; license management moved to the Microsoft 365 admin center | Found the trial under **Billing → Trials** |
| 2 | Looked for *Purchase services* but landed on an Azure **billing account** page | Cost Management + Billing (Azure invoices) is separate from Microsoft 365 licensing | Use `admin.microsoft.com` for Microsoft licenses, or Entra **Billing → Trials** |
| 3 | P2 trial **Activate** opened a checkout requiring payment details | Trial converts to a paid 1-year subscription unless cancelled | Not activated; lab ran on Free |
| 4 | New user review showed "Office location: Unites States" and no usage location | Country typed into the wrong field | Properties → clear Office location → set **Usage location** dropdown |
| 5 | "Microsoft Entra roles can be assigned to the group" missing on New group | Role-assignable groups require P1 | None needed; ordinary Security groups used |
| 6 | Password reset blade showed only an upgrade page | SSPR for users requires P1 | Toured the Authentication methods policy instead |
| 7 | No *Manage migration* button in Authentication methods | Tenant already runs only on the converged policy | None needed |
| 8 | Test user couldn't skip MFA registration | Security defaults + mandatory Azure portal MFA | Registered Microsoft Authenticator; removed the entry after teardown |
| 9 | VNet name typed as `vnet-haverest-lab` | Typo | Harmless; deleted with the resource group |

---

## Selection cheat sheet

| Requirement | Answer |
|---|---|
| Legacy app in Azure needs Kerberos/LDAP | Microsoft Entra Domain Services |
| Users sign in with company domain | Add custom domain, verify with TXT/MX |
| Subscription moved to another tenant, nobody can manage it | Role assignments were removed; re-create them |
| Can't edit a user's job title in the portal | User is synced; edit in on-premises AD |
| One user fails group licensing, others succeed | Check that user's usage location, then Reprocess |
| Automatic membership by department | Security group, Dynamic user (P1) |
| Automatic membership of all Windows devices | Security group, Dynamic device (P1) |
| Shared mailbox and Teams for a team | Microsoft 365 group |
| Group must hold an Entra admin role | Role-assignable at creation (P1) |
| Partner signs in with own company account | B2B guest invite |
| Only invite guests from approved domains | Collaboration restrictions: allow list |
| Non-admin must invite guests | Guest Inviter role |
| Public customers sign up for an app | Microsoft Entra External ID |
| SSPR for two departments | One group containing both; Selected scope |
| Cloud reset must work on office PCs | Password writeback (P1) |
| Just-in-time admin access | PIM (P2) |
| Global Administrator can't see subscriptions | Elevate access → User Access Administrator at root |
| Helpdesk resets passwords for one office only | Helpdesk Administrator scoped to an AU |
| Build everything, can't grant access | Contributor |
| Only manage who has access | User Access Administrator or RBAC Administrator |
| Configure storage but read blobs | Add Storage Blob Data role |
| Can't remove an assignment on a resource group | It's inherited; remove at the parent scope |
| Owner blocked on a managed app | Deny assignment |
| Verify a user's real access | Check access on IAM |

---

## Acronyms

| Acronym | Meaning |
|---|---|
| AD DS | Active Directory Domain Services |
| ARM | Azure Resource Manager |
| AU | Administrative Unit |
| B2B / B2C | Business-to-Business / Business-to-Consumer |
| CA | Conditional Access |
| CIAM | Customer Identity and Access Management |
| CLI | Command-Line Interface |
| CSV | Comma-Separated Values |
| DDoS | Distributed Denial of Service |
| DNS | Domain Name System |
| FIDO2 | Fast IDentity Online 2 |
| GA | General Availability |
| GPO | Group Policy Object |
| GUID | Globally Unique Identifier |
| IaC | Infrastructure as Code |
| IAM | Identity and Access Management |
| JSON | JavaScript Object Notation |
| LDAP | Lightweight Directory Access Protocol |
| MFA | Multi-Factor Authentication |
| MG | Management Group |
| MI | Managed Identity |
| MSA | Microsoft Account |
| MX | Mail Exchanger (DNS record) |
| OATH | Open Authentication |
| OAuth | Open Authorization |
| OIDC | OpenID Connect |
| OTP | One-Time Passcode |
| OU | Organizational Unit |
| PIM | Privileged Identity Management |
| RBAC | Role-Based Access Control |
| RG | Resource Group |
| SaaS | Software as a Service |
| SAML | Security Assertion Markup Language |
| SKU | Stock Keeping Unit |
| SMS | Short Message Service |
| SSO | Single Sign-On |
| SSPR | Self-Service Password Reset |
| TXT | Text (DNS record) |
| UPN | User Principal Name |
| VM | Virtual Machine |
| VNet | Virtual Network |
