# Notes: Connecting to Private RDS Outside of Fargate (Bastion Host)

A reference guide for securely reaching a private RDS instance from a local machine, using a bastion host as a jump point. Built on top of the existing AWS Fargate + SonarQube lab (VPC, RDS, ECS already in place).

---

## 1. Why RDS Is Private

RDS instances for production-style workloads are placed in a **private subnet** — no public IP, no route to an Internet Gateway (IGW). This removes the entire attack surface of internet bots scanning for open database ports (5432 for Postgres, 3306 for MySQL).

**Consequence:** only resources *inside* the VPC (e.g. ECS Fargate tasks) can reach it. External humans need an authorized pathway in.

**Analogy:** RDS is a locked filing cabinet in a windowless back room. ECS containers are employees with badge access. A human at home needs a front desk (bastion), a secure tunnel (SSM), or a side door (CloudShell) to get in.

---

## 2. Security Groups (SGs) — The Gatekeeper

- SGs control inbound/outbound traffic per resource.
- **Rules are additive, not exclusive.** Multiple rules stack; they don't replace each other.
- Best practice: scope SG sources as narrowly as possible.
  - ❌ `0.0.0.0/0` on a database port = anyone on the internet can attempt to connect = active bot scanning target within minutes.
  - ✅ Specific SG as source (e.g. `ecs-tasks-sg`, `bastion-sg`) or a `/32` IP for SSH.

**RDS's SG in this lab ends up with two separate rules:**
| Type | Port | Source |
|---|---|---|
| PostgreSQL | 5432 | `ecs-tasks-sg` (existing, for Fargate/SonarQube) |
| PostgreSQL | 5432 | `bastion-sg` (new, for human/admin access) |

Each rule is independently revocable — deleting the bastion rule later kills bastion access without touching the running app.

---

## 3. The Bastion Host Pattern

A bastion host is a small EC2 instance (`t2.micro`/`t3.micro`, Amazon Linux 2023) that:
- Lives in the **public subnet** of the same VPC as RDS (needs an IGW route to be reachable from the internet)
- Has a **public IP** and accepts inbound SSH (port 22) — locked to **my IP only**, never `0.0.0.0/0`
- Is the *only* resource that bridges "internet-reachable" and "VPC-internal"

**Connection flow:**
```
Mac --SSH (internet)--> Bastion --psql (inside VPC)--> RDS
```

The Mac itself has **no network route** to RDS's private IP at all, regardless of what client software is installed locally — the bastion is what provides that route, because it lives inside the VPC.

**Analogy:** calling a spouse's office extension — you can't dial the internal line directly from home; you call the office's public number (bastion), get the front desk, and the call routes internally (bastion → RDS).

---

## 4. Key Pairs (`.pem` files)

- The `.pem` file is the **private half** of an SSH key pair; AWS stores the public half on the instance (`~/.ssh/authorized_keys`).
- **Never commit `.pem` files to git** — even old commits remain in history permanently. Add `*.pem` to `.gitignore`.
- Store keys in `~/.ssh/` and set permissions: `chmod 400`.
- The `.pem` file used must match the **exact key pair selected at instance launch** — using a `.pem` from a different/older lab causes `Permission denied (publickey...)`.

---

## 5. IAM Setup (CLI/Console Auth)

- Always use an **IAM user's** access keys, never **root account** keys — even for short-lived throwaway demos. Root keys have zero permission boundaries (can affect billing, delete users, close the account, etc.).
- Generate access keys: IAM → Users → [user] → Security credentials → Create access key → CLI use case.
- Configure locally:
  ```bash
  aws configure
  ```
- Verify:
  ```bash
  aws sts get-caller-identity
  ```
  Should return the IAM user's ARN, not a root ARN.

---

## 6. Step-by-Step Walkthrough

### A. Identify existing VPC, public subnet, RDS endpoint (Console)
1. VPC console → Your VPCs → find VPC from Fargate lab, note VPC ID
2. VPC console → Subnets → find subnet with Route Table showing `0.0.0.0/0 → igw-...` (confirms it's truly public)
3. RDS console → Databases → [instance] → Connectivity & security tab → note Endpoint + attached SG

📸 *Screenshot placeholder: VPC subnet route table showing IGW route*

### B. Launch the Bastion EC2 Instance
1. EC2 console → Launch instance
2. Name: `bastion-host`
3. AMI: Amazon Linux 2023
4. Instance type: `t2.micro` / `t3.micro` (free tier)
5. Key pair: create new or reuse existing (download `.pem`)
6. Network settings:
   - VPC: Fargate lab's VPC
   - Subnet: the confirmed public subnet
   - Auto-assign public IP: **Enable**
   - Security group: create new (`bastion-sg`), inbound SSH (22) source = **My IP**
7. Launch

📸 *Screenshot placeholder: EC2 launch wizard network settings panel*

### C. Link Bastion SG to RDS SG
1. RDS console → Databases → [instance] → Connectivity & security → click VPC security group link
2. Inbound rules → Edit inbound rules → Add rule
3. Type: PostgreSQL (auto-fills 5432), Source: select `bastion-sg` (security group, not IP)
4. Save rules

📸 *Screenshot placeholder: RDS SG inbound rules showing both ecs-tasks-sg and bastion-sg entries*

### D. SSH Into the Bastion
```bash
chmod 400 ~/.ssh/bastion-key.pem
ssh -i ~/.ssh/bastion-key.pem ec2-user@<bastion-public-ip>
```
- `ec2-user` = default username for Amazon Linux AMIs
- First connection prompts to confirm host fingerprint — type `yes`

### E. Install PostgreSQL Client on Bastion
```bash
sudo dnf install -y postgresql15
```
- Client only (no server needed) — bastion is just a relay, not a database host
- Amazon Linux 2023 uses `dnf`; Amazon Linux 2 would use `yum`

### F. Connect to RDS from the Bastion
```bash
psql -h <rds-endpoint> -U <master-username> -d <database-name> -p 5432
```
- Prompts for password (no characters echoed — this is normal)
- Successful connection shows TLS version/cipher info

### G. Verify Connection
```sql
\dt
```
Lists tables in the database. Confirmed real SonarQube schema (`projects`, `issues`, `users`, `quality_gates`, etc.).

> Note: `--More--` at the bottom of long output means you're in a pager — press `space` to scroll, `q` to quit.

📸 *Screenshot placeholder: psql session showing \dt output with SonarQube tables*

---

## 7. Errors Encountered & Fixes

**1. `Identity file ... not accessible: No such file or directory`**
- Cause: wrong/forgotten path to `.pem` file
- Fix: `find ~ -iname "*.pem" 2>/dev/null` to locate it, then move to `~/.ssh/`

**2. `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`**
- Cause: used a `.pem` from a different/older key pair than the one attached to this instance
- Fix: confirm the **Key pair name** on the EC2 instance details page matches the `.pem` file being used

**3. `password authentication failed for user "sonarqube"`**
- Cause: password typo (psql shows zero feedback while typing, not even asterisks)
- Fix: retype carefully and retry; secondary `no pg_hba.conf entry` message was a side effect, not the root cause — the connection itself reached RDS fine

---

## 8. Revocation Pattern

To cut off bastion access later without affecting the running app:
- Delete only the `bastion-sg` inbound rule on RDS's security group
- Leave the `ecs-tasks-sg` rule untouched
- SonarQube on Fargate keeps running uninterrupted

---

## 9. SSM Session Manager (Keyless Alternative)

An alternative to the traditional bastion pattern:
- Uses **SSM Agent** on the instance, which reaches out to AWS Systems Manager over HTTPS (443) — outbound only
- **No inbound SSH (port 22) required** — can be closed entirely
- **No public IP or public subnet required** — instance can live fully private
- **No `.pem` key file** — access controlled by IAM permissions, centrally auditable via CloudTrail
- Requirements: SSM Agent installed (pre-installed on Amazon Linux 2023) + IAM instance role granting SSM permissions
- Same downstream pattern still applies: get a shell via SSM → run `psql` from inside that shell → reach RDS

**Comparison:**

| | Bastion (SSH) | SSM Session Manager |
|---|---|---|
| Subnet | Public | Public or fully private |
| Inbound port | 22 (SSH) | None |
| Auth | `.pem` key file | IAM permissions |
| Audit trail | SSH logs only | CloudTrail |
| Public IP needed | Yes | No |

---

