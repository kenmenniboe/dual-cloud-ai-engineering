# AWS EC2 Fundamentals — Notes

Reference guide covering the concept modules and the full hands-on lab. Written to be redo-able end to end without re-watching anything.

## Table of Contents

- [Overview](#overview)
- [Module 1: EC2 Instance Types & Families](#module-1-ec2-instance-types--families)
- [Module 2: Security Groups — Stateful Behavior & Diagnostics](#module-2-security-groups--stateful-behavior--diagnostics)
- [Module 3: IAM Roles for EC2 (Instance Profiles)](#module-3-iam-roles-for-ec2-instance-profiles)
- [Module 4: EC2 Purchasing Options](#module-4-ec2-purchasing-options)
- [Module 5: Spot Instances & Spot Fleets Deep Dive](#module-5-spot-instances--spot-fleets-deep-dive)
- [Architecture Diagram](#architecture-diagram)
- [Hands-On Lab](#hands-on-lab)
  - [Phase A: Launch the Base Instance](#phase-a-launch-the-base-instance)
  - [Phase B: Breaking and Fixing the Security Group](#phase-b-breaking-and-fixing-the-security-group)
  - [Phase C: IAM Role, Live](#phase-c-iam-role-live)
  - [Phase D: Spot Instance, Correct Teardown Order](#phase-d-spot-instance-correct-teardown-order)
- [Acronyms](#acronyms)
- [Full Redo Guide (Copy-Paste)](#full-redo-guide-copy-paste)

---

## Overview

> [!NOTE]
> This session started at advanced/exam depth on purpose — prior bastion-host, SG-to-SG trust, and SSH key pair work already covered EC2 101, so the 101-level "launch an instance / basic SSH" content was skipped.

Session scope: instance type taxonomy, Security Group internals, IAM roles/instance profiles, purchasing options, and Spot instances/fleets — each with an Azure anchor, then a full hands-on lab exercising all five.

---

## Module 1: EC2 Instance Types & Families

**Naming convention:** `[family][generation][attributes].[size]`

| Family | Optimized for | AWS letters |
|---|---|---|
| General Purpose | balanced compute/memory/network | M, T |
| Compute Optimized | CPU-heavy: batch, transcoding, HPC, ML training | C |
| Memory Optimized | RAM-bound: in-memory DBs, BI, real-time big-data | R, X1, z1 |
| Storage Optimized | high local-disk IOPS: OLTP, NoSQL, warehousing | I, D, H1 |

**Concrete contrast:** `r5.16xlarge` (16 vCPU / 512 GiB RAM) vs. `c5d.4xlarge` (16 vCPU / 32 GiB RAM) — identical vCPU count, wildly different RAM. That gap is the family distinction in one comparison.

> [!TIP]
> **Azure anchor:** B/D-series ≈ General Purpose, F-series ≈ Compute Optimized, E/M-series ≈ Memory Optimized, L-series ≈ Storage Optimized. Same generational suffix pattern too (`v5`, `v6`…).

**Self-check scenarios covered:**
- Redis in-memory cache → Memory Optimized (R)
- CPU-bound batch transcoding job → Compute Optimized (C), not the memory-heavy option with the same vCPU count
- What does the "5" in `m5.2xlarge` mean → hardware generation
- High-frequency OLTP database → Storage Optimized (I)
- Azure analog to R-series → E-series

---

## Module 2: Security Groups — Stateful Behavior & Diagnostics

**Core mental model:**
- **Allow-only, no explicit deny.** Anything not listed is implicitly denied — there's no "Deny" rule type at all.
- **Stateful.** Allowed inbound traffic gets its response traffic out automatically — no matching outbound rule required (and vice versa).
- **Union, not priority.** Multiple SGs on one instance/ENI = the union of all their rules. Most-permissive-wins; no priority number decides a "winner."
- **SG-to-SG referencing.** A rule's source can be another SG ID instead of a CIDR block — decouples the rule from an IP that might change (e.g. bastion → RDS pattern).
- **Diagnostic signal:** timeout → SG (or routing) is blocking the packet. "Connection refused" → the packet got through fine; the problem is application-layer.

> [!IMPORTANT]
> **Azure anchor:** NSGs are also stateful, but they support explicit **Allow AND Deny** rules ordered by **priority number** (lower wins). AWS SGs have neither explicit deny nor priority ordering — pure allow-list union. This is the single biggest SG-vs-NSG trap on the exam.

**Self-check scenarios covered:**
- SSH inbound allowed, no matching outbound rule → still works (stateful)
- Can an SG contain a Deny rule? → No
- SG-A allows 22, SG-B allows nothing → SSH still works (union)
- Why does bastion → RDS use an SG reference instead of a CIDR? → decouples from IP changes
- curl to an ALB hangs forever → SG/routing block, not an app error

---

## Module 3: IAM Roles for EC2 (Instance Profiles)

**Concept:** Never put long-lived IAM credentials (`aws configure` with an Access Key/Secret Key) on an EC2 instance. Attach an **IAM Role** instead — temporary, auto-rotating credentials via the instance metadata service, nothing to steal.

**Mechanics:**
- Create the IAM Role with the policy the workload needs.
- Attach: Instance → Actions → Security → Modify IAM role.
- CLI/SDK auto-discovers the credentials — no `aws configure` step.
- Detach the role (or remove a policy) and access is revoked — a brief "Access Denied" right after an *attach* is normal (IAM eventual consistency), clears within seconds.

> [!IMPORTANT]
> Anyone with access to the instance (SSH, EC2 Instance Connect) can read credentials stored via `aws configure`. That's the entire reason this pattern is banned — not a style preference.

> [!TIP]
> **Azure anchor:** a **Managed Identity** (system- or user-assigned) attached to a VM is the direct equivalent — same "credential-free access to other cloud APIs" pattern.

**Exam-level nuance:** what the Console calls attaching a "role" is technically attaching an **instance profile** — a container object wrapping the role. Matters most when doing this via CLI/CloudFormation instead of the Console, where the instance profile sometimes has to be created explicitly.

**Self-check scenarios covered:**
- Script on an instance needs S3 access → attach an IAM role
- Why is `aws configure` on a shared instance dangerous → anyone with instance access can exfiltrate the keys
- New policy attached, immediate Access Denied, works 30s later → IAM eventual consistency
- Azure analog → Managed Identity
- What's technically attached to the instance → an instance profile

---

## Module 4: EC2 Purchasing Options

| Option | Commitment | Discount | Best for |
|---|---|---|---|
| On-Demand | None | Baseline | Short-term, unpredictable, spiky |
| Reserved Instances (RI) | 1/3 yr, specific attributes | up to ~72% | Steady-state (e.g. always-on DB) |
| Convertible RI | Same term, swappable attributes | up to ~66% | Steady-state, specs may evolve |
| Savings Plans | 1/3 yr, $/hour spend commitment | up to ~70% | Steady-state, flexible instance size/OS |
| Spot | None, reclaimable (2-min warning) | up to ~90% | Fault-tolerant, flexible timing — never critical jobs/DBs |
| Dedicated Host | On-demand or 1/3 yr | Most expensive | BYOL tied to physical sockets/cores, strict compliance |
| Dedicated Instance | On-demand | — | Isolated hardware, no placement visibility/control |
| Capacity Reservation | Any duration | None by itself | Guaranteed AZ capacity; stack with a regional RI/Savings Plan for a discount |

**RI payment tiers:** No Upfront → Partial Upfront → All Upfront — more upfront cash, bigger discount. RIs are buyable/sellable on the RI Marketplace.

> [!TIP]
> **Azure anchor:** Reserved VM Instances ≈ RI · Savings Plan for Compute ≈ Savings Plans · Spot VMs ≈ Spot Instances · Azure Dedicated Host ≈ Dedicated Host (literal name match) · On-demand Capacity Reservation ≈ Capacity Reservation.

**Self-check scenarios covered:**
- 24/7 DB for a known 2-year project → Reserved Instance
- RI vs. Savings Plan structural difference → specific attributes vs. $/hour spend
- Guaranteed AZ capacity, no discount needed → Capacity Reservation
- Per-socket/per-core BYOL licensing → Dedicated Host (not Dedicated Instance)
- Azure analog to Dedicated Host → Azure Dedicated Host

---

## Module 5: Spot Instances & Spot Fleets Deep Dive

**Mechanics:**
- Set a **max price**; actual spot price floats per AZ/instance type by supply and demand. Keep the instance as long as spot price ≤ max.
- Cross the threshold → **2-minute interruption warning**, then stop/terminate per config.
- **One-time request:** fire-and-forget — interrupted means gone for good.
- **Persistent request:** stays active for its validity window, auto-relaunches after an interruption.

> [!WARNING]
> **Critical ordering rule:** to permanently remove a persistent-request instance, **cancel the spot request first, then terminate the instance**. Terminate first and AWS relaunches to hit target capacity again.

**Spot Fleet allocation strategies:**
- `lowestPrice` — cheapest pool, best for short one-off workloads
- `diversified` — spread across all pools, best for long-running/fault-sensitive workloads
- `capacityOptimized` — least-likely-to-be-interrupted pool
- `priceCapacityOptimized` — highest-capacity pool first, then cheapest within it — recommended default for most workloads

> [!TIP]
> **Azure anchor:** Azure Spot VMs use an **eviction policy** (`Deallocate` or `Delete`) instead of AWS's stop/terminate split — same discount-for-interruptibility trade, different vocabulary. Closest analog to a Spot Fleet: a **VM Scale Set with a Spot mix** across multiple sizes.

**Self-check scenarios covered:**
- Interruption warning length → 2 minutes
- Correct teardown order for a persistent request → cancel, then terminate
- One-time request after interruption → stays terminated, no relaunch
- Balanced allocation strategy for a sensible default → `priceCapacityOptimized`
- Azure Spot VM eviction options → Deallocate or Delete

---

## Architecture Diagram

![EC2 fundamentals session architecture](./diagram.svg)

Shows: SG union behavior (two SGs merging, most-permissive-wins), the IAM role/instance-profile call path to AWS APIs, and the correct Spot teardown order (cancel request → terminate instance).

---

## Hands-On Lab

> [!NOTE]
> All lab resources were terminated/deleted at the end of the session — starting from scratch next time.

### Phase A: Launch the Base Instance

Full launch wizard, every tab covered even where the lab's specific goal didn't strictly need it:

1. **Name and tags** — Name: `ec2-fundamentals-demo`.
2. **AMI** — Quick Start → Amazon Linux → Amazon Linux 2 (free tier), 64-bit (x86).
3. **Instance type** — `t3.micro` (General Purpose, matches Module 1).
4. **Key pair** — Create new: `ec2-fundamentals-demo-key`, RSA, `.pem`.
5. **Network settings** — default VPC/subnet, auto-assign public IP: Enable. New SG `ec2-fundamentals-demo-sg`: inbound SSH (22) from My IP, HTTP (80) from Anywhere.
6. **Configure storage** — default 8 GiB gp3, confirmed Delete on Termination = Yes.
7. **Advanced details** — Purchasing option left On-Demand (Spot comes in Phase D); IAM instance profile left blank (attached fresh in Phase C); Shutdown behavior: Stop; Termination protection: disabled; optional HTTPD user-data bootstrap for a visual "alive" check.
8. **Review and launch** — confirmed summary, launched, waited for `running` state.

📸 *screenshot: Review and launch summary page*

### Phase B: Breaking and Fixing the Security Group

1. **Baseline check** — curl the public IP (HTTPD Hello World, if user data was used) and SSH in — both succeed.
2. **Remove the HTTP rule** — Instance → Security → SG → Edit inbound rules → delete port 80 → Save.
3. **Confirm the timeout** — curl hangs/times out. Matches Module 2's diagnostic: packet never reached the instance.
4. **Verify SSH unaffected** — SSH still works; rules are independent, not all-or-nothing.
5. **Restore the HTTP rule** — re-add HTTP/Anywhere-IPv4, Save; curl works again.
6. **Prove SG union behavior** — created empty `ec2-fundamentals-demo-sg-2`, attached alongside the first; HTTP and SSH both still worked, since an empty second SG can't restrict what the first already allows.

📸 *screenshot: inbound rules before/after showing the deleted and restored HTTP rule*
📸 *screenshot: curl timeout in terminal*

### Phase C: IAM Role, Live

1. **Confirm no credentials exist** — `aws iam list-users` on the instance → `Unable to locate credentials`.

   > [!WARNING]
   > Fixed with an IAM role, never with `aws configure` — see Module 3.

2. **Start the role** — IAM → Roles → Create role → Trusted entity: AWS service → Use case: EC2.
3. **Attach a permissions policy** — `IAMReadOnlyAccess` (deliberately narrow, read-only).
4. **Name and create** — `ec2-fundamentals-demo-role`; confirmed trust policy shows `ec2.amazonaws.com`.
5. **Attach to the instance** — Instance → Actions → Security → Modify IAM role → select role → Update.
6. **Re-test from the instance** — `aws iam list-users` now returns real output.
7. **Prove revocation** — removed `IAMReadOnlyAccess` from the role, waited a few seconds (eventual consistency), re-ran the command → back to `Access Denied`.

📸 *screenshot: terminal showing Unable to locate credentials → successful output → Access Denied*

### Phase D: Spot Instance, Correct Teardown Order

1. **Start a new launch** — same AMI/type/key pair/SG as Phase A.
2. **Configure as a Spot request** — Advanced details → Purchasing option → Request Spot Instances. Request type: **Persistent**. Interruption behavior: Stop. Max price: default (capped at On-Demand).
3. **Verify the Spot request** — EC2 → Spot Requests: state `Active`, type `Persistent`, instance attached and running.
4. **Cancel the request FIRST** — Spot Requests → select → Actions → Cancel request. State → `Cancelled`; instance still running.
5. **Terminate second, confirm no relaunch** — Instances → select → Instance state → Terminate. Confirmed nothing relaunched, since the request was already cancelled. (Reverse order would have triggered an automatic replacement — Module 5, self-check on this exact scenario.)
6. **Full lab cleanup** — terminated the Phase A/B instance, deleted both demo SGs, deleted the IAM role, deleted the key pair.

📸 *screenshot: Spot Requests page showing Cancelled state with instance still running*

---

## Acronyms

| Acronym | Meaning |
|---|---|
| EC2 | Elastic Compute Cloud |
| AMI | Amazon Machine Image |
| SG | Security Group |
| NSG | Network Security Group (Azure) |
| IAM | Identity and Access Management |
| CIDR | Classless Inter-Domain Routing |
| SSH | Secure Shell |
| RSA | Rivest–Shamir–Adleman (key algorithm) |
| OLTP | Online Transaction Processing |
| HPC | High Performance Computing |
| BI | Business Intelligence |
| RI | Reserved Instance |
| BYOL | Bring Your Own License |
| AZ | Availability Zone |
| VPC | Virtual Private Cloud |
| ENI | Elastic Network Interface |
| CLI | Command Line Interface |

---

## Full Redo Guide (Copy-Paste)

Exact field values for a clean redo, top to bottom:

```
Instance name:        ec2-fundamentals-demo
AMI:                  Amazon Linux 2 (64-bit x86)
Instance type:        t3.micro
Key pair name:        ec2-fundamentals-demo-key (RSA, .pem)
Security group name:  ec2-fundamentals-demo-sg
  Inbound: SSH (22) from My IP
  Inbound: HTTP (80) from Anywhere (0.0.0.0/0)
Storage:               8 GiB gp3, Delete on Termination = Yes
Purchasing option:     On-Demand (Phase A/B/C) — Spot/Persistent for Phase D re-launch
IAM role name:         ec2-fundamentals-demo-role
  Trusted entity: AWS service → EC2
  Policy: IAMReadOnlyAccess
Second SG (union test): ec2-fundamentals-demo-sg-2 (empty, no rules)
Spot request type:      Persistent, Interruption behavior: Stop, Max price: default
```

See [commands.md](./commands.md) for every CLI command used, grouped by workflow stage.