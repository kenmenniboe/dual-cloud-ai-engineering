# AWS IAM & CLI

**Category:** `week-02-security-identity`

Hands-on build covering AWS Identity and Access Management (IAM): users, groups, policies, password/MFA security, CLI access, roles, and auditing tools — run end-to-end against a real AWS account, in both the Console and the CLI.

## What I Learned

- **IAM fundamentals** — root vs. IAM users, why root should only be used for setup, groups vs. users, IAM as a global service
- **Policies** — JSON structure (`Effect`, `Action`, `Resource`), least privilege, managed vs. inline, how group and direct attachments stack (permissions are additive, not overriding)
- **Account security** — password policy options, MFA mechanics and device types (virtual, U2F key, hardware fob)
- **Access methods** — Console vs. CLI vs. SDK, access keys, CloudShell, and that IAM enforces identical permissions across all three
- **Roles** — how a role differs from a user (assumed by a service, temporary auto-rotated credentials, no password), and why EC2/Lambda/CloudFormation use roles instead of hardcoded keys
- **Auditing** — Credential Report (account-wide hygiene snapshot) vs. Last Accessed, formerly "Access Advisor" (per-user actual usage)

## Hands-On Build — Results

| Item | Result |
|---|---|
| IAM user | `glory_jr` created, console + CLI access, MFA enabled |
| Group | `Admin_group` — `AdministratorAccess` + `Billing` policies |
| Password policy | Length/complexity/expiration/reuse rules set on the account |
| Access keys | Generated, configured as CLI profile `glory_jr` (kept separate from an existing `default` profile) |
| Permission parity test | Confirmed removing group membership blocks the CLI identically to the console, in real time |
| Custom policy | `IAMReadNamesOnly` (`iam:ListUsers`, `iam:GetUser`) — built via Visual Editor, attached directly to the user |
| IAM Role | `DemoRoleForEC2` — trusts `ec2.amazonaws.com`, holds `IAMReadOnlyAccess`, not yet attached to an instance |
| Auditing | Credential Report pulled; Last Accessed reviewed for `glory_jr` |

## Key Gotchas Hit

- **Billing access needs a separate root-level switch.** Attaching the `Billing` policy to a user alone isn't enough — root has to activate "IAM User and Role Access to Billing Information" first, once, account-wide.
- **"Access Advisor" is now called "Last Accessed"** in the current console. Same feature, same data — just a relabeled tab.

Full write-up: [`notes.md`](./notes.md) · Commands used: [`commands.md`](./commands.md)