# Notes: AWS Account Setup + Billing Alarm + AWS CLI Install

---

## Why This Matters
AWS charges by usage. A billing alarm is your financial safety net — it sends an email when your estimated charges cross a set threshold. Think of it as a smoke detector for your AWS bill.

---

## Concepts Covered

### Root User vs IAM User
- **Root user** — original account login, full unrestricted access
- **IAM user** — sub-user with permissions you define
- **Best practice:** Use root only for initial setup, then switch to an IAM user for daily tasks
- **Risk:** If root credentials are compromised, the attacker has full, unrestricted account access

---

### Custom IAM Sign-In URL
- Default sign-in URL includes your 12-digit account ID (hard to remember and share)
- You can create a custom alias to replace it

**Steps:**
1. Go to **IAM** in the AWS Console
2. On the IAM dashboard, find **Account Alias** on the right side
3. Click **Create**
4. Enter your alias name (e.g. `kenneth-aws-lab`)
5. Click **Save**

Your new sign-in URL becomes:
```
https://kenneth-aws-lab.signin.aws.amazon.com/console
```

> ⚠️ One alias per account only

---

### IAM User Access to Billing
By default, IAM users cannot see billing — even admins get "Access Denied."
Root must manually enable it first.

**Steps:**
1. Click your **account name** (top right of console)
2. Click **Account**
3. Scroll to **IAM user and role access to Billing information**
4. Click **Edit** → check **Activate IAM Access**
5. Click **Update**

---

### Billing Preferences
Before creating a CloudWatch alarm, billing alerts must be turned on.

**Steps:**
1. Go to **Billing** in the console
2. Click **Billing Preferences**
3. Enable:
   - ✅ Receive PDF Invoice by Email
   - ✅ Receive Free Tier Usage Alerts
   - ✅ **Receive Billing Alerts** ← required for CloudWatch alarms

---

## Creating a Billing Alarm in CloudWatch

### ⚠️ Switch to us-east-1 First
AWS billing metrics are only stored in **US East (N. Virginia) — us-east-1**.
You will not see billing data in any other region.

**Steps:**
1. Go to **CloudWatch** in the console
2. Make sure region is set to **us-east-1** (top right)
3. Click **Alarms** → **Create Alarm**
4. Click **Select Metric** → **Billing** → **Total Estimated Charge**
5. Select **EstimatedCharges** → click **Select Metric**
6. Set your **threshold** (e.g. $10)
7. Click **Next** → create a new **SNS topic**
8. Enter your **email address**
9. Give the alarm a **name**
10. Click **Create Alarm**
11. **Check your email and confirm the SNS subscription** ✅

> ⚠️ The alarm will NOT fire until you confirm the subscription email from AWS

### What is SNS?
**SNS (Simple Notification Service)** is the AWS service that sends the email notification.
A **topic** is like a notification channel. You subscribe your email to it.
When the alarm triggers, SNS sends you the alert.

---

## Installing AWS CLI v2 on macOS

AWS CLI lets you manage AWS services directly from your terminal — no console needed.

### Option 1: Homebrew (Recommended for macOS)
```bash
# Step 1: Update Homebrew
brew update

# Step 2: Install AWS CLI
brew install awscli

# Step 3: Verify the install
aws --version
# Expected output: aws-cli/2.x.x Python/3.x.x Darwin/...
```

### Option 2: Official .pkg Installer
1. Download from: https://awscli.amazonaws.com/AWSCLIV2.pkg
2. Double-click the `.pkg` file and follow the prompts
3. Verify: `aws --version`

### Configure AWS CLI
After installing, connect it to your AWS account:
```bash
aws configure
```
You'll be prompted for:
- **AWS Access Key ID** — from your IAM user
- **AWS Secret Access Key** — from your IAM user
- **Default region** — e.g. `us-east-1`
- **Default output format** — e.g. `json`

> ⚠️ Access keys are created in IAM → Users → Security Credentials

---

## Quick Reference

| Action | Where |
|---|---|
| Create IAM alias | IAM → Dashboard → Account Alias |
| Enable IAM billing access | Account → IAM user and role access to Billing |
| Enable billing alerts | Billing → Billing Preferences |
| Create billing alarm | CloudWatch (us-east-1) → Alarms → Create Alarm |
| Verify AWS CLI install | Terminal → `aws --version` |
| Configure AWS CLI | Terminal → `aws configure` |