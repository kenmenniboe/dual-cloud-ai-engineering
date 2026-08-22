# AWS Free Tier Credit Challenge — Notes

Full reference guide for the "Explore AWS" $100 bonus-credit program: five activities, $20 each, on an AWS account created on or after July 15, 2025 (the current credit-based Free Tier model).

## Table of Contents

- [Overview](#overview)
- [Module 1: AWS Budgets](#module-1-aws-budgets)
  - [Concept](#budgets-concept)
  - [Step 1: Navigate to Budgets](#budgets-step-1-navigate-to-budgets)
  - [Step 2: Choose the budget setup method](#budgets-step-2-choose-the-budget-setup-method)
  - [Step 3: Pick the template](#budgets-step-3-pick-the-template)
  - [Step 4: Enter details](#budgets-step-4-enter-details)
  - [Step 5: Review and create](#budgets-step-5-review-and-create)
- [Module 2: Amazon Bedrock](#module-2-amazon-bedrock)
  - [Concept](#bedrock-concept)
  - [Step 1: Confirm region](#bedrock-step-1-confirm-region)
  - [Step 2: Open the playground](#bedrock-step-2-open-the-playground)
  - [Step 3: Select a model](#bedrock-step-3-select-a-model)
  - [Step 4: Submit the Anthropic use-case form](#bedrock-step-4-submit-the-anthropic-use-case-form)
  - [Step 5: Run a prompt](#bedrock-step-5-run-a-prompt)
- [Module 3: AWS Lambda](#module-3-aws-lambda)
  - [Concept](#lambda-concept)
  - [Step 1: Create the function](#lambda-step-1-create-the-function)
  - [Step 2: Configure permissions and Function URL](#lambda-step-2-configure-permissions-and-function-url)
  - [Step 3: Write and deploy the code](#lambda-step-3-write-and-deploy-the-code)
  - [Step 4: Test the Function URL](#lambda-step-4-test-the-function-url)
- [Module 4: Amazon EC2](#module-4-amazon-ec2)
  - [Concept](#ec2-concept)
  - [Step 1: Launch wizard walkthrough](#ec2-step-1-launch-wizard-walkthrough)
  - [Step 2: Verify and terminate](#ec2-step-2-verify-and-terminate)
- [Module 5: Aurora PostgreSQL](#module-5-aurora-postgresql)
  - [Concept](#aurora-concept)
  - [Aurora vs. RDS architecture diagram](#aurora-vs-rds-architecture-diagram)
  - [Step 1: Launch express configuration](#aurora-step-1-launch-express-configuration)
  - [Step 2: Connect and verify](#aurora-step-2-connect-and-verify)
  - [Step 3: Delete the cluster](#aurora-step-3-delete-the-cluster)
- [End-of-session cleanup checklist](#end-of-session-cleanup-checklist)
- [Acronyms](#acronyms)

---

## Overview

> [!IMPORTANT]
> This account was created **after July 15, 2025**, so it's on AWS's newer credit-based Free Tier model, not the legacy 12-month/750-hours-per-month model. That distinction matters for almost every module below — several older tutorials assume the legacy model and give wrong guidance for accounts created after that date.

- $100 in credits granted at sign-up
- Up to $100 more available by completing 5 activities (this session): **Budgets, Bedrock, Lambda, EC2, RDS/Aurora** — $20 each
- Free Plan lasts 6 months or until credits run out, whichever comes first
- Credits generally post to the **Explore AWS** widget within ~10 minutes of completing each activity
- Region used throughout this session: **us-east-1 (N. Virginia)**

---

## Module 1: AWS Budgets

### Budgets Concept

AWS Budgets is a proactive cost-monitoring tool — set a threshold (dollar amount or usage), get alerted when actual *or forecasted* spend crosses it.

Contrast with **CloudWatch billing alarms** (used in earlier labs):

| | CloudWatch Billing Alarm | AWS Budgets |
|---|---|---|
| Scope | One metric: `EstimatedCharges` | Purpose-built cost tool, multiple budget types |
| Thresholds | One value | Multiple thresholds per budget (e.g. 50%/80%/100%) |
| Forecasting | No | Yes — alerts before you even hit the limit |
| Setup | Manual alarm, must enable billing alerts first | Guided templates in Billing Console |

> [!TIP]
> **Knowledge check:** You want AWS to alert you the moment ANY charge appears on a new account — which budget template fits?
> **Answer: Zero spend budget** — it assumes a $0 target and alerts as soon as spend exceeds roughly $0.01. A regular *Monthly cost budget* requires picking a dollar threshold instead, which is the wrong fit when the goal is "tell me the instant anything is spent."

### Budgets Step 1: Navigate to Budgets

Billing and Cost Management console → left nav → **Budgets** → **Create budget**

### Budgets Step 2: Choose the budget setup method

Two radio options:
- **Use a template (simplified)** ← selected
- *Customize (advanced)* — lets you hand-pick budget type (Cost/Usage/Savings Plans/Reservation), a specific amount, period, start month, filter scope (service/tag/linked account/region), multiple alert thresholds, and optional **Budget Actions** (auto-attach an IAM policy or stop EC2/RDS instances on breach). Not needed for this activity, but useful once running real workloads.

### Budgets Step 3: Pick the template

Under the template list → **Zero spend budget**

### Budgets Step 4: Enter details

- **Budget name:** `free-tier-zero-spend`
- **Email recipients:** your email (required, at least one)

### Budgets Step 5: Review and create

Confirms budget type (Zero spend), amount ($0), name, recipient → **Create budget**

![Screenshot: Zero spend budget confirmation](./screenshots/budgets-created.png)

**Verify:** Budget appears in the Budgets list within a minute; Explore AWS widget shows the $20 credit within ~10 minutes; an email arrives the instant any real spend occurs.

[↑ Back to top](#table-of-contents)

---

## Module 2: Amazon Bedrock

### Bedrock Concept

Amazon Bedrock gives unified API access to foundation models (FMs) from multiple providers — Anthropic, Amazon Nova, Meta Llama, Mistral, DeepSeek, and others — with no infrastructure to manage. Billed per token, on demand.

> [!NOTE]
> As of late 2025, AWS retired the old per-model "Model access" request page — access to foundation models is enabled by default on new accounts. **Exception:** Anthropic models still require a one-time usage form on first invocation per account, submitted right inside the playground. Some third-party models also auto-subscribe on first use, which can take a few minutes and occasionally throws a transient error on the very first attempt.

> [!TIP]
> **Knowledge check:** You select a Claude model in the Bedrock playground and hit Run for the first time on this account — what happens?
> **Answer:** You're prompted for a one-time use-case form before it runs. It doesn't run immediately, and it isn't a separate "Model access" page (that flow was retired).

### Bedrock Step 1: Confirm region

Top-right corner of the console → **US East (N. Virginia) — us-east-1** (broadest model catalog).

### Bedrock Step 2: Open the playground

Console search bar → **Bedrock** → left nav, under **Playgrounds** → **Chat / Text**

### Bedrock Step 3: Select a model

**Select model** →
- Provider: **Anthropic**
- Model: current Claude model (Sonnet or Haiku)
- **Apply**

### Bedrock Step 4: Submit the Anthropic use-case form

First-time Claude invocation on this account triggers a one-time form:

| Field | Value used |
|---|---|
| Company name | Menniboe Farm |
| Company website URL | (a working personal/portfolio URL) |
| Industry | Education |
| Intended users | Internal users (employees, staff, team members) |
| Use case description | *"Individual learning project. Self-directed cloud/AI engineering study — using Bedrock's Claude models hands-on to learn foundation model concepts and the Bedrock API/console workflow as part of a certification-focused study plan. No production data, PII, or IP involved."* |

Submit → clears instantly.

### Bedrock Step 5: Run a prompt

In the playground text panel:
```
Explain what Amazon Bedrock is in one sentence.
```
Click **Run**. Response appears below, with input/output token counts and latency shown — that's the real per-call cost signal (fractions of a cent for a short prompt).

![Screenshot: Bedrock playground response](./screenshots/bedrock-response.png)

> [!WARNING]
> If you get a transient `AccessDeniedException` right after submitting the use-case form, wait a minute and re-run — that's the model subscription finishing in the background, not a real failure.

**Verify:** Explore AWS widget shows the Bedrock $20 credit within ~10 minutes.

[↑ Back to top](#table-of-contents)

---

## Module 3: AWS Lambda

### Lambda Concept

Lambda is serverless compute — upload code, define the trigger, AWS handles provisioning/scaling/patching. Billed per invocation + execution time to the millisecond.

A bare Lambda function isn't browser-reachable by itself. A **Function URL** — a built-in HTTPS endpoint mapped directly to the function — makes it a "web app" for this activity without needing API Gateway.

> [!TIP]
> **Knowledge check:** Which Lambda feature turns a function into a browser-reachable "web app" without setting up API Gateway?
> **Answer: Function URL**

### Lambda Step 1: Create the function

Console search bar → **Lambda** → **Create function**

Creation method (radio options):
- **Author from scratch** ← selected
- *Use a blueprint* — pre-built sample code for common triggers (S3, DynamoDB) — not used
- *Container image* — deploy from ECR — not used
- *Browse serverless app repository* — deploy a packaged app — not used

Basic information:
- **Function name:** `hello-lambda-webapp`
- **Runtime:** Python 3.13
- **Architecture:** x86_64 (default)

### Lambda Step 2: Configure permissions and Function URL

**Permissions:**
- **Execution role:** Create a new role with basic Lambda permissions ← selected (auto-scopes an IAM role to CloudWatch Logs write access only)

**Advanced settings** (expanded):
- ☑ **Enable function URL**
  - **Auth type:** NONE (public, no signed requests — needed to hit it from a browser)
  - CORS — not configured (only needed for cross-origin browser JS calls)
- Tags — skipped
- VPC — none (only needed to reach private resources like an RDS instance inside a VPC)
- Code signing — skipped (for verifying deployment packages in regulated environments)

**Create function**

### Lambda Step 3: Write and deploy the code

**Code** tab → inline editor → replace boilerplate with:

```python
import json

def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'text/html'},
        'body': '<h1>Hello from Lambda!</h1><p>AWS Free Tier credit demo.</p>'
    }
```

Click **Deploy**.

### Lambda Step 4: Test the Function URL

**Configuration** tab → **Function URL** → copy the URL (`https://xxxx.lambda-url.us-east-1.on.aws/`) → open in a browser.

![Screenshot: Rendered Lambda web page](./screenshots/lambda-webpage.png)

**Result:** page rendered "Hello from Lambda! / AWS Free Tier credit demo." — confirmed working.

> [!NOTE]
> Lambda's 1M-requests/month tier is part of AWS's permanent Always Free allowance — this function costs nothing ongoing beyond the demo itself. Auth type NONE does mean the URL is genuinely public, worth remembering if it isn't torn down afterward.

**Verify:** Explore AWS widget shows the Lambda $20 credit within ~10 minutes.

[↑ Back to top](#table-of-contents)

---

## Module 4: Amazon EC2

### EC2 Concept

> [!IMPORTANT]
> On accounts created on or after July 15, 2025, Free Tier eligible instance types are **t3.micro, t3.small, t4g.micro, t4g.small, c7i-flex.large, m7i-flex.large** — not t2.micro (legacy-account-only). More importantly, newer accounts get **no separate monthly EC2-hour pool** — usage draws straight from the $100–$200 credit balance instead. That's why this activity explicitly requires launching **and terminating** the instance.

> [!TIP]
> **Knowledge check:** Which instance type is Free Tier eligible on an account created after July 15, 2025?
> **Answer: t3.micro** (t2.micro is a legacy-account-only type — a reasonable instinct from older guides, but wrong for this account.)

### EC2 Step 1: Launch wizard walkthrough

Console search bar → **EC2** → **Instances** → **Launch instance**

| Section | Selections |
|---|---|
| **Name and tags** | Name: `free-tier-credit-demo`. Additional tags — skipped. |
| **Application and OS Images (AMI)** | Quick Start → **Amazon Linux 2023 AMI** (ships with SSM Agent preinstalled). Architecture: 64-bit (x86). |
| **Instance type** | **t3.micro** (console-tagged "Free tier eligible") |
| **Key pair** | Create new key pair → Type: ED25519, Format: .pem |
| **Network settings** | Default VPC, default subnet. Auto-assign public IP: **Enable**. Firewall: new security group, inbound SSH (port 22) from **My IP** only (not 0.0.0.0/0). Advanced network config — skipped. |
| **Configure storage** | 8 GiB, gp3, Delete on termination: ☑ checked, default KMS encryption. |
| **Advanced details** | Purchasing option: On-Demand. IAM instance profile: none (key pair used instead). Shutdown behavior: Stop. Termination protection: disabled. Detailed monitoring: off. **Credit specification: Standard** (not Unlimited — avoids silent CPU-burst billing). Tenancy: Shared. |

**Launch instance**

### EC2 Step 2: Verify and terminate

Instances list → state transitions **Pending → Running**.

![Screenshot: Running t3.micro instance](./screenshots/ec2-running.png)

Once confirmed: **Instance state → Terminate instance**.

**Verify:** Explore AWS widget shows the EC2 $20 credit within ~10 minutes.

[↑ Back to top](#table-of-contents)

---

## Module 5: Aurora PostgreSQL

### Aurora Concept

Compared to the RDS PostgreSQL setup built for the SonarQube stack:

| | Standard RDS | Aurora |
|---|---|---|
| Storage | Single EBS volume tied to one instance | Distributed, self-healing storage — 6 copies across 3 AZs |
| Read replicas | Each holds a full copy of the data | Replicas share the same storage layer — much lower lag |
| Capacity model | Fixed instance size | Fixed, or **Aurora Serverless v2** — auto-scales in ACUs (~2 GiB memory each), including to 0 when idle |
| Free Tier | db.t3.micro / db.t4g.micro, several engines | **Provisioned Aurora is not Free Tier eligible.** Aurora PostgreSQL **Serverless** is, as of March 2026 — up to 4 ACUs / 1 GiB storage per cluster |

> [!NOTE]
> AWS also introduced an **Express Configuration** flow for Aurora PostgreSQL in March 2026: two clicks, ready in seconds, no VPC to configure (uses a built-in internet access gateway instead), and IAM authentication set up by default in place of a password. This is a real departure from the manual VPC/security-group/subnet-group setup used for the SonarQube RDS instance.

> [!TIP]
> **Knowledge check:** Compared to the RDS PostgreSQL setup in the SonarQube stack, what's different about Aurora's Express Configuration flow?
> **Answer:** It skips VPC entirely — connects via a built-in internet access gateway instead.

### Aurora vs. RDS architecture diagram

![Standard RDS vs Aurora storage architecture](./diagram.svg)

### Aurora Step 1: Launch express configuration

Console search bar → **RDS** → left nav → **Dashboard** → **Create** (rocket icon)

**Create with express configuration** dialog:
- **DB cluster identifier:** `aurora-free-tier-demo`
- **Engine:** Aurora PostgreSQL (fixed for this flow)
- **Capacity range:** left at/below **4 ACUs max** to stay inside the Free Plan cap

Everything else is preconfigured automatically: no VPC/subnet/security-group prompts, IAM authentication for the admin user (no password to set).

**Create database** → success banner, status flips to **Available** within seconds.

### Aurora Step 2: Connect and verify

**Connectivity & security** tab → three connection options:
- **Code snippets** — pre-generated connection code (Python/Node.js/Go/etc.) using an IAM auth token
- **CloudShell** ← used for this test — launches a browser shell with `psql` pre-filled
- **Endpoints** — for tools like pgAdmin; generates a 15-minute temporary IAM token as the password

Launched CloudShell, ran:
```sql
SELECT version();
```
Aurora PostgreSQL version string returned — connectivity confirmed.

![Screenshot: CloudShell connected to Aurora](./screenshots/aurora-cloudshell.png)

> [!NOTE]
> The traditional multi-tab **Standard create** path (Engine options → Templates → Instance configuration → Storage → Connectivity → Monitoring → Additional configuration) still exists alongside Express Configuration — that's the one for Multi-AZ, custom parameter groups, or VPC placement on a real workload. Express Configuration is the fast, Free-Tier-safe path for this specific credit activity.

### Aurora Step 3: Delete the cluster

**Actions → Delete** → declined the final-snapshot prompt (to avoid leftover snapshot storage).

**Verify:** Explore AWS widget shows the RDS/Aurora $20 credit within ~10 minutes.

[↑ Back to top](#table-of-contents)

---

## End-of-session cleanup checklist

| Module | Action taken |
|---|---|
| Budgets | Kept — Zero spend budget is a permanent, no-cost guardrail |
| Bedrock | Nothing to clean up — playground prompts don't create persistent resources |
| Lambda | Deleted the function (also removes the public Function URL); deleted the auto-created execution IAM role separately from **IAM → Roles** (not removed automatically with the function) |
| EC2 | Terminated the instance (root EBS volume auto-deleted); deleted the custom security group and key pair |
| Aurora | Deleted the cluster, declined the final snapshot |

[↑ Back to top](#table-of-contents)

---

## Acronyms

| Acronym | Meaning |
|---|---|
| ACU | Aurora Capacity Unit — ~2 GiB memory + proportional CPU/networking, the scaling unit for Aurora Serverless v2 |
| AMI | Amazon Machine Image — template used to launch an EC2 instance |
| CLI | Command Line Interface |
| EBS | Elastic Block Store — persistent block storage attached to EC2/RDS instances |
| FM | Foundation Model — a large pretrained model (e.g. Claude) served via Bedrock |
| gp3 | General Purpose SSD v3 — the default EBS/Aurora volume type used in this session |
| IAM | Identity and Access Management |
| PEM | Privacy-Enhanced Mail — file format used for the EC2 SSH key pair (`.pem`) |
| RDS | Relational Database Service |
| SDK | Software Development Kit |
| SG | Security Group — a virtual firewall controlling inbound/outbound traffic |
| SSM | AWS Systems Manager — used here for Session Manager, an alternative to SSH |
| VPC | Virtual Private Cloud |

[↑ Back to top](#table-of-contents)