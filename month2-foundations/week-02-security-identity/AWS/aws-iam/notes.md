# AWS IAM & CLI — Notes

Detailed reference guide covering AWS Identity and Access Management (IAM): concepts, an Azure comparison for each, and a full copy-paste redo guide for the hands-on build.

## Table of Contents

- [Acronyms and Terminology](#acronyms-and-terminology)
- [Module 1: IAM Fundamentals](#module-1-iam-fundamentals)
- [Module 2: IAM Policies](#module-2-iam-policies)
- [Module 3: Password Policy and MFA](#module-3-password-policy-and-mfa)
- [Module 4: Access Methods (Console vs CLI vs SDK)](#module-4-access-methods-console-vs-cli-vs-sdk)
- [Module 5: IAM Roles](#module-5-iam-roles)
- [Module 6: Security Auditing (Credential Report and Last Accessed)](#module-6-security-auditing-credential-report-and-last-accessed)
- [Architecture Diagram](#architecture-diagram)
- [Hands-On Redo Guide](#hands-on-redo-guide)
  - [Task 1: Create Your IAM User](#task-1-create-your-iam-user)
  - [Task 2: Password Policy and MFA Setup](#task-2-password-policy-and-mfa-setup)
  - [Task 3: Access Keys and CLI Setup](#task-3-access-keys-and-cli-setup)
  - [Task 4: Permission Parity Test](#task-4-permission-parity-test)
  - [Task 5: Build a Custom Policy](#task-5-build-a-custom-policy)
  - [Task 6: Create an IAM Role for EC2](#task-6-create-an-iam-role-for-ec2)
  - [Task 7: Audit Yourself](#task-7-audit-yourself)
- [Best Practices Recap](#best-practices-recap)

---

## Acronyms and Terminology

| Term | Meaning |
|---|---|
| **IAM** | Identity and Access Management — controls who can do what in an AWS account |
| **MFA** | Multi-Factor Authentication — a password plus a physical/virtual device |
| **TOTP** | Time-based One-Time Password — the rotating 6-digit code an authenticator app generates |
| **U2F** | Universal 2nd Factor — the standard behind physical security keys like a YubiKey |
| **ARN** | Amazon Resource Name — the unique identifier for any AWS resource |
| **JSON** | JavaScript Object Notation — the format IAM policies are written in |
| **CLI** | Command Line Interface — a terminal tool for issuing AWS commands |
| **SDK** | Software Development Kit — language-specific libraries for calling AWS APIs from application code |
| **CSV** | Comma-Separated Values — the format of the IAM Credentials Report |
| **RBAC** | Role-Based Access Control — Azure's permission model, the rough equivalent of IAM policies |
| **IAM Identity Center** | Formerly "AWS SSO" — a more advanced alternative to plain IAM users, not used in this session |
| **EC2** | Elastic Compute Cloud — AWS's virtual server service |

---

## Module 1: IAM Fundamentals

**Concept.** IAM controls *who* can do *what*. Every account starts with a **root user** — unrestricted, meant only for initial account setup. Day-to-day, you create **IAM users** (one per physical person) and organize them into **groups**. Groups can only contain users, never other groups; a user can belong to zero, one, or many groups. IAM is a **global** service — identities aren't tied to a region.

**Azure anchor.** IAM's rough equivalent is **Microsoft Entra ID** (formerly Azure AD) — also a directory that spans the whole tenant, not scoped to a resource group or region. Entra ID Groups play the same role as IAM Groups for assigning permissions in bulk.

---

## Module 2: IAM Policies

**Concept.** A **policy** is a JSON document defining permissions: `Effect` (Allow/Deny), `Action` (which API calls), `Resource` (what it applies to). Policies attach to users, groups, or roles. Permissions are **additive** — a user's effective access is the sum of everything attached to them, from any source (group or direct). Wildcards (`*`) group related calls: `Action: "*"` on `Resource: "*"` is full admin; `Get*`/`List*` covers every matching read-only call.

**Azure anchor.** Azure RBAC role definitions are the equivalent — also JSON, with `Actions`/`NotActions` instead of `Action`, assigned at a scope via a role assignment. AWS managed policies (`AdministratorAccess`, `IAMReadOnlyAccess`) map to Azure built-in roles (`Owner`, `Reader`).

---

## Module 3: Password Policy and MFA

**Concept.** Two independent layers:
- **Password policy** — account-wide rules (minimum length, character complexity, expiration, reuse prevention). Defends against brute-force guessing.
- **MFA** — something you know (password) + something you have (device). Defeats a stolen/phished password alone.

MFA device types: virtual (authenticator app — Google Authenticator single-account, Authy multi-account), U2F security key (e.g. YubiKey — supports multiple root/IAM accounts on one physical key), hardware key fob (e.g. Gemalto), and a GovCloud-specific fob (SurePassID).

**Azure anchor.** Password rules live in Entra ID password policies; the "something you have" layer is Microsoft Authenticator or a FIDO2 security key, typically enforced via a Conditional Access policy rather than a single toggle.

---

## Module 4: Access Methods (Console vs CLI vs SDK)

**Concept.** Three ways to reach AWS: **Console** (username/password + MFA), **CLI** (terminal commands, protected by an Access Key ID + Secret Access Key), **SDK** (language libraries embedded directly in application code, same access keys). IAM enforces one unified permission model — whatever a user's policies allow applies identically across all three access paths.

**Azure anchor.** Azure Portal (console), Azure CLI/PowerShell (terminal, via `az login` or a service principal), and Azure SDKs per language. AWS CloudShell maps to **Azure Cloud Shell** — a browser terminal pre-authenticated with your portal session.

---

## Module 5: IAM Roles

**Concept.** A **Role** is structurally like a user but is *assumed* by an AWS service (EC2, Lambda, CloudFormation, etc.) rather than logged into by a person. No password — a service assumes the role and receives short-lived, auto-rotated credentials. This avoids hardcoding long-lived access keys onto a resource.

**Azure anchor.** Directly maps to **Managed Identity** (system- or user-assigned), attached to a resource and paired with an RBAC role assignment.

---

## Module 6: Security Auditing (Credential Report and Last Accessed)

**Concept.** Two tools verify least privilege is actually happening:
- **Credential Report** — account-wide CSV: every user's password/MFA/access-key hygiene.
- **Last Accessed** (formerly "Access Advisor") — per-user: which services their permissions cover, and when each was actually last used. Used to spot granted-but-unused access and tighten policies.

**Azure anchor.** No 1:1 tool, but **Entra ID Access Reviews** (periodic recertification) plus sign-in/activity logs cover the same two questions: is this credential healthy, and is this access actually used?

---

## Architecture Diagram

![AWS IAM account architecture diagram showing the root user, the glory_jr IAM user inside Admin_group, a directly-attached custom policy, the DemoRoleForEC2 role, the account password policy, billing console access gated by root, CLI access via a named profile, and the audit tools](images/architecture-diagram.svg)

Root creates the account setup (IAM user, group, password policy) and is the only identity that can toggle billing access on. `glory_jr` sits in `Admin_group` (inherited `AdministratorAccess` + `Billing`) and also has the `IAMReadNamesOnly` policy attached directly. Access keys connect the local CLI to the account under a named profile. `DemoRoleForEC2` sits ready for a future EC2 instance to assume. The Credential Report and Last Accessed tab audit the whole setup.

---

## Hands-On Redo Guide

### Task 1: Create Your IAM User

1. **IAM → Users → Create user**
   - User name: `glory_jr`
   - ☑ Provide user access to the AWS Management Console
   📸 *Screenshot placeholder: user details screen*
2. **Console access options**
   - "I am creating this user for myself"
   - Console password: **Custom password** → set your own
   - ☐ Uncheck "Users must create a new password at next sign-in"
3. **Set permissions → Add user to group → Create group**
   - Group name: `Admin_group`
   - Attach policy: `AdministratorAccess`
   📸 *Screenshot placeholder: group creation with policy search*
4. Permissions boundary → leave unset → **Next**
5. Tags → optional, skip or add → **Next**
6. **Review → Create user**
7. Note your console sign-in URL and remember your custom password (no one-time secret to download since it wasn't auto-generated)

> [!IMPORTANT]
> **Error hit: attached the `Billing` policy but still couldn't view billing info as the IAM user.**
> **Cause:** Billing console access has a *second*, separate gate — a root-only, account-wide switch. It's off by default regardless of what IAM policies a user holds.
> **Fix (must be done as root):**
> 1. Sign in as root
> 2. Account name (top right) → **Account**
> 3. Scroll to **"IAM User and Role Access to Billing Information"** → Edit
> 4. Check **"Activate IAM Access"** → Update
> 5. Sign back in as the IAM user — billing should now load

[↑ back to top](#aws-iam--cli--notes)

### Task 2: Password Policy and MFA Setup

> [!NOTE]
> MFA was already enabled on both root and the IAM user from a prior session — no MFA setup needed here, only the password policy.

**IAM → Account settings → Password policy → Edit**
- Minimum password length: `12` (raised from the AWS default of 8)
- ☑ Require uppercase letter
- ☑ Require lowercase letter
- ☑ Require at least one number
- ☑ Require at least one non-alphanumeric character
- ☑ Enable password expiration → `90` days
- Administrator reset: your choice (tighter = require it)
- Allow users to change their own password: your choice
- Prevent password reuse: remember last `5` passwords
- **Save changes**

📸 *Screenshot placeholder: password policy edit screen*

[↑ back to top](#aws-iam--cli--notes)

### Task 3: Access Keys and CLI Setup

**Console: IAM → Users → glory_jr → Security credentials → Create access key**
- Use case: **Command Line Interface (CLI)**
- ☑ "I understand the above recommendation..."
- Copy the **Access Key ID** and **Secret Access Key** immediately — the secret is shown only once

📸 *Screenshot placeholder: access key creation confirmation*

> [!TIP]
> Use a **named profile** instead of overwriting your default AWS CLI profile. This machine already had two other profiles configured (`default`, region `us-east-1`, and one for another identity) — a named profile keeps them all intact.

**Terminal:**

```bash
aws configure --profile glory_jr
```

- AWS Access Key ID: *[paste]*
- AWS Secret Access Key: *[paste]*
- Default region name: `us-east-1`
- Default output format: `json`

**Verify:**

```bash
aws iam list-users --profile glory_jr
```

[↑ back to top](#aws-iam--cli--notes)

### Task 4: Permission Parity Test

1. **Console:** IAM → User groups → `Admin_group` → remove `glory_jr`
2. **CLI:** re-run `aws iam list-users --profile glory_jr` → now returns an Access Denied error
3. **Console:** IAM → User groups → `Admin_group` → add `glory_jr` back
4. **CLI:** re-run the same command → succeeds again

> [!NOTE]
> This proves IAM has one unified permission model — console, CLI, and SDK all check the exact same policies, in real time. There's no separate "CLI access" to configure or cache.

[↑ back to top](#aws-iam--cli--notes)

### Task 5: Build a Custom Policy

**IAM → Policies → Create policy → Visual editor**
- Service: `IAM`
- Actions: `ListUsers`, `GetUser` (under Read/List) — nothing else
- Resources: All resources
- Name: `IAMReadNamesOnly`

Generated JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:ListUsers",
        "iam:GetUser"
      ],
      "Resource": "*"
    }
  ]
}
```

**Attach it directly:** IAM → Users → `glory_jr` → Permissions → Add permissions → Attach policies directly → `IAMReadNamesOnly` → Add permissions

📸 *Screenshot placeholder: user permissions tab showing the direct attachment, no "via group" label*

> [!NOTE]
> Since `glory_jr` is still in `Admin_group`, this doesn't visibly change what the user can do — the point of the exercise is the mechanism (build + attach directly), not a visible permission change.

[↑ back to top](#aws-iam--cli--notes)

### Task 6: Create an IAM Role for EC2

**IAM → Roles → Create role**
- Trusted entity type: **AWS service**
- Use case: **EC2**
- Attach policy: `IAMReadOnlyAccess`
- Role name: `DemoRoleForEC2`
- Trust policy principal: `ec2.amazonaws.com` (confirm before creating)

📸 *Screenshot placeholder: role trust policy showing ec2.amazonaws.com*

> [!NOTE]
> This role isn't attached to any running instance yet — that happens when an EC2 instance is launched, in a future EC2 lab.

[↑ back to top](#aws-iam--cli--notes)

### Task 7: Audit Yourself

**IAM → Credential report → Download credential report**
- CSV with two rows: `root` and `glory_jr`
- Check: `password_enabled`, `password_last_used`, `mfa_active`, `access_key_1_active`, `access_key_1_last_used_date`

**IAM → Users → glory_jr → Last Accessed**

> [!IMPORTANT]
> AWS renamed **Access Advisor** to **Last Accessed** in the current console. Same feature, same data — just a relabeled tab.

- Shows every service `glory_jr`'s policies cover, with a last-accessed timestamp per service. On a brand-new account, most will read "Not accessed in the tracking period" except the handful actually used (IAM, etc.) — expected, not a bug.

📸 *Screenshot placeholder: Last Accessed tab*

[↑ back to top](#aws-iam--cli--notes)

---

## Best Practices Recap

- Use root only for initial account setup — never day-to-day
- One IAM user per physical person; manage permissions at the **group** level, not per-user
- Apply **least privilege** everywhere — grant only what's needed, verify with Last Accessed
- Enforce a strong **password policy** + **MFA**, especially on root
- Use **Roles**, not hardcoded access keys, for AWS services (EC2, Lambda, etc.)
- Access keys are secrets — generate your own, never share, use named CLI profiles to avoid clobbering existing ones
- Audit regularly with the **Credential Report** and **Last Accessed**
- Billing console access needs a separate root-level activation, independent of IAM policy

[↑ back to top](#aws-iam--cli--notes)