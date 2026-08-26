# EC2 Storage — Notes & Redo Guide

AWS SAA track. Reference guide for EC2 storage: EBS, Snapshots, AMIs, Instance Store, Multi-Attach, Encryption, and EFS — with Azure anchors for the AZ-104 track.

## Table of Contents

- [Acronyms & Glossary](#acronyms--glossary)
- [Module 1: EBS Volume Fundamentals](#module-1-ebs-volume-fundamentals)
- [Module 2: EBS Behavior — Delete on Termination](#module-2-ebs-behavior--delete-on-termination)
- [Module 3: EBS Volume Types](#module-3-ebs-volume-types)
- [Module 4: EBS Snapshots](#module-4-ebs-snapshots)
- [Module 5: AMI (Amazon Machine Image)](#module-5-ami-amazon-machine-image)
- [Module 6: EC2 Instance Store](#module-6-ec2-instance-store)
- [Module 7: EBS Multi-Attach](#module-7-ebs-multi-attach)
- [Module 8: EBS Encryption](#module-8-ebs-encryption)
- [Module 9: EFS (Elastic File System)](#module-9-efs-elastic-file-system)
- [Module 10: EBS vs EFS vs Instance Store](#module-10-ebs-vs-efs-vs-instance-store)
- [Final Architecture Diagram](#final-architecture-diagram)
- [Hands-On Redo Guide](#hands-on-redo-guide)
  - [Stage 1: Create & Attach an EBS Volume](#stage-1-create--attach-an-ebs-volume)
  - [Stage 2: Verify Delete on Termination](#stage-2-verify-delete-on-termination)
  - [Stage 3: Snapshot & Cross-AZ Migration](#stage-3-snapshot--cross-az-migration)
  - [Stage 4: Encrypt an Existing Volume](#stage-4-encrypt-an-existing-volume)
  - [Stage 5: Build & Launch from a Custom AMI](#stage-5-build--launch-from-a-custom-ami)
  - [Stage 6: Deploy EFS Across Two AZs](#stage-6-deploy-efs-across-two-azs)
  - [Stage 7: Clean Up All Resources](#stage-7-clean-up-all-resources)
- [Quiz Recap](#quiz-recap)

---

## Acronyms & Glossary

| Acronym | Meaning |
|---|---|
| **EBS** | Elastic Block Store — network-attached block storage volume |
| **EFS** | Elastic File System — managed NFS file system |
| **NFS** | Network File System — protocol EFS uses under the hood |
| **AMI** | Amazon Machine Image — a template for launching EC2 instances |
| **AZ** | Availability Zone |
| **IOPS** | Input/Output Operations Per Second — a storage performance unit |
| **SSD / HDD** | Solid State Drive / Hard Disk Drive |
| **KMS** | Key Management Service — manages the keys used for EBS/EFS encryption |
| **AES-256** | Advanced Encryption Standard, 256-bit — the cipher AWS uses for EBS encryption |
| **FSR** | Fast Snapshot Restore — forces full snapshot initialization to remove first-use latency |
| **POSIX** | Portable Operating System Interface — the standard file system model EFS uses |
| **SG** | Security Group |

---

## Module 1: EBS Volume Fundamentals

**Concept:** An EBS volume is a *network drive* attached to an EC2 instance — not a physical disk inside the server.

- Persists independently of the instance (data survives termination, unless Delete on Termination is set)
- **AZ-locked**: a volume created in one AZ can only attach to an instance in that same AZ
- One instance at a time (baseline rule — exception is Multi-Attach, see [Module 7](#module-7-ebs-multi-attach))
- Capacity (size + IOPS) is provisioned in advance and billed accordingly
- Can be detached/reattached on demand, or left unattached

**Analogy:** A network USB stick — you "unplug" it from one machine and "plug it into" another, except it's over the network, not physical.

**Azure anchor:** Azure Managed Disks — attached to a VM, provisioned size, tied to a region and (unless zone-redundant) a specific zone.

> [!IMPORTANT]
> Volumes are AZ-locked on attach. If you ever try to attach a volume to an instance in a different AZ, the console will reject it — this is one of the most common exam traps.

---

## Module 2: EBS Behavior — Delete on Termination

**Concept:** Controls whether an attached EBS volume is deleted when its EC2 instance is terminated. Set **per volume**.

- **Root volume** → enabled by default → deleted with the instance
- **Secondary/additional volumes** → disabled by default → survive termination, become "available"
- Toggle at launch (Advanced details → Storage) or after launch via console/CLI

**Analogy:** Root volume = a rental locker cleared automatically at checkout unless you opt out. Secondary volume = a locker you brought yourself — still yours after you leave.

**Azure anchor:** Azure defaults the *opposite* way — disks are **not** deleted when you delete a VM unless you explicitly opt in.

---

## Module 3: EBS Volume Types

Six types across two families.

| Family | Type | Boot volume? | Best for |
|---|---|---|---|
| SSD | gp2 / gp3 | Yes | General purpose — balances price/performance |
| SSD | io1 / io2 (Block Express) | Yes | Mission-critical, low-latency, high-throughput (databases) |
| HDD | st1 | No | Big data, data warehousing, log processing (throughput-heavy) |
| HDD | sc1 | No | Infrequently accessed / archive data (cheapest) |

**Key number:** gp3 decouples IOPS/throughput from size — baseline 3,000 IOPS / 125 MB/s, scalable independently up to 16,000 IOPS / 1,000 MB/s. gp2 links IOPS to size (3 IOPS/GB, capped at 16,000 IOPS).

**Analogy:** gp2/gp3 = reliable sedan. io1/io2 = race car (extreme, consistent performance). st1 = moving truck (throughput). sc1 = storage unit (cheap, rarely opened).

**Azure anchor:** Standard HDD ≈ sc1 · Standard SSD ≈ gp2/gp3 · Premium SSD/v2 ≈ io1/io2 · Ultra Disk ≈ io2 Block Express.

---

## Module 4: EBS Snapshots

**Concept:** A point-in-time backup of a volume. Detaching first isn't required but is recommended for consistency.

**Key exam idea:** snapshots are **not** AZ-locked (unlike the volumes they came from) — this is what makes them the mechanism to move a volume across AZs or regions.

Three features to know cold:

- **EBS Snapshot Archive** — ~75% cheaper storage tier; restore takes **24–72 hours**
- **Recycle Bin** — deleted snapshots/AMIs land here instead of being destroyed; retention configurable **1 day–1 year**
- **Fast Snapshot Restore (FSR)** — forces full initialization so a volume from the snapshot has zero latency on first use; **expensive**, use deliberately

**Analogy:** A snapshot is a video game save file — not tied to one console, can be loaded on a different one (a different AZ).

**Azure anchor:** Azure Disk Snapshots (full or incremental); soft-delete is the Recycle Bin equivalent.

> [!TIP]
> To migrate a volume from AZ-a to AZ-b: snapshot it, then "Create volume from snapshot" and pick AZ-b as the target. No cross-AZ copy step needed for the snapshot itself.

---

## Module 5: AMI (Amazon Machine Image)

**Concept:** A template for launching EC2 instances — packages OS, software config, and monitoring agents so new instances boot pre-configured.

**Sources:** Public AMI (AWS-provided) · Your own AMI (self-built/maintained) · AWS Marketplace AMI (third-party).

**Build process:**
1. Launch an instance
2. Customize it
3. **Stop** the instance (data integrity)
4. Create the image (generates EBS snapshots behind the scenes)
5. Launch new instances from it, anywhere in the region

**Key exam fact:** AMIs are region-scoped but not AZ-locked — launch into any AZ in that region freely. Using it in a *different region* requires an explicit copy.

**Analogy:** A pre-loaded hard drive image flashed onto new machines instead of installing everything by hand.

**Azure anchor:** Azure Managed Images / Azure Compute Gallery (Shared Image Gallery).

---

## Module 6: EC2 Instance Store

**Concept:** A physical disk **hardware-attached** to the underlying server — not a network drive.

- Massive I/O performance (millions of IOPS vs. tens of thousands on EBS)
- **Ephemeral** — data is lost on stop or termination
- You are responsible for redundancy/backup if the host fails
- Good for: buffers, caches, scratch/temp data
- Bad for: anything that must outlive the instance

**Analogy:** The local scratch disk on your own gaming PC — blazing fast, gone if the machine is wiped.

**Azure anchor:** Azure Temporary Storage (`D:\` on Windows, `/dev/sdb` on Linux) — same ephemeral behavior.

> [!WARNING]
> Never use Instance Store for anything you need to survive a stop/terminate — there is no recovery path.

---

## Module 7: EBS Multi-Attach

**Concept:** Attach the **same EBS volume** to multiple EC2 instances simultaneously — the deliberate exception to the "one instance at a time" rule.

- Only **io1 / io2** volumes
- **Same AZ only** — does not bypass the AZ-lock rule
- Up to **16 instances** at a time
- Each instance gets full read/write access — concurrent writes are possible
- Requires a **cluster-aware file system** (regular XFS/EXT4 won't coordinate safely)

**Use cases:** clustered Linux applications for high availability (e.g., Teradata), apps managing concurrent write operations.

**Analogy:** A shared network drive multiple coworkers write to at once — but only within the same office (AZ), using coordination software.

**Azure anchor:** Azure Shared Disks (Premium SSD/Ultra Disk) — used for WSFC or SQL FCI clustering.

---

## Module 8: EBS Encryption

**Concept:** Encrypting a volume gives you, automatically:
- Data at rest → encrypted
- Data in flight (instance ↔ volume) → encrypted
- Snapshots taken from it → encrypted
- Volumes created from those snapshots → encrypted

Handled transparently via **KMS keys (AES-256)**, minimal latency impact.

**Encrypting an existing unencrypted volume (you can't toggle it directly):**
1. Snapshot the unencrypted volume
2. **Copy** the snapshot with encryption enabled (choose a KMS key) → produces an encrypted snapshot
3. Create a new volume from the encrypted snapshot → volume is encrypted
4. Attach the new encrypted volume in place of the old one

(Shortcut: "Create volume from snapshot" lets you enable encryption on the fly from an unencrypted snapshot, skipping the separate copy step.)

**Analogy:** You can't relock an already-open filing cabinet — copy the contents into a new, locked one.

**Azure anchor:** Azure managed disks are encrypted **at rest by default** (SSE, platform-managed keys) — the opposite default posture from AWS's opt-in-per-volume approach.

---

## Module 9: EFS (Elastic File System)

**Concept:** A managed **NFS** file system mountable by **many EC2 instances simultaneously, across multiple AZs** — the functional opposite of EBS.

- Highly available/scalable, ~3x the cost of gp2 EBS
- **Pay-per-use** — no advance provisioning
- **Linux only** — NFS protocol, POSIX file system
- Access controlled via security groups
- Encryption at rest available via KMS

**Performance mode (set at creation):** General Purpose (default, low latency) vs. Max I/O (higher latency, higher parallel throughput).

**Throughput mode:** Bursting (scales with storage size) · Provisioned (fixed) · **Elastic** (recommended — auto-scales to workload, pay only for use).

**Storage classes/lifecycle:** Standard → EFS-IA (infrequent access) → Archive, moved automatically via lifecycle policy based on days since last access. Up to 90% savings.

**Availability:** Regional (multi-AZ, production) vs. One Zone (single AZ, cheaper, dev/test).

**Analogy:** A shared Google Drive folder many computers across different offices can open and edit at once, vs. EBS's personal external hard drive.

**Azure anchor:** Azure Files (SMB/NFS shares, Hot/Cool tiering); Azure NetApp Files for heavier performance needs.

---

## Module 10: EBS vs EFS vs Instance Store

| | **EBS** | **EFS** | **Instance Store** |
|---|---|---|---|
| Attaches to | 1 instance (or ≤16 via Multi-Attach, io1/io2 only) | Many instances, multiple AZs | 1 instance, tied to physical host |
| AZ scope | Locked to one AZ | Spans multiple AZs (Regional) | Locked to the host machine |
| Persistence | Survives termination | Survives termination | **Lost** on stop/terminate |
| OS support | Linux & Windows | Linux only | Linux & Windows |
| Capacity planning | Provision size/IOPS in advance | Pay-per-use | Fixed by instance type |
| Best for | Boot volumes, databases | Shared file storage, web serving, CMS | Cache, buffer, scratch data |

**Azure anchor:** Managed Disks (EBS) · Azure Files (EFS) · Temporary Storage (Instance Store).

---

## Final Architecture Diagram

![Final architecture: EC2 instances across two AZs with EBS volumes, a snapshot feeding a cross-AZ volume and an encrypted volume, a custom AMI, and a Regional EFS file system mounted in both AZs](images/architecture-diagram.svg)

---

## Hands-On Redo Guide

Substitute your own AZ names throughout — referred to generically below as **AZ-A** and **AZ-B** within your region. Resource names below use the `menniboe-*` convention for consistency with other lab sessions.

### Stage 1: Create & Attach an EBS Volume

1. EC2 Console → Instances → launch or select an existing `t2.micro`, Amazon Linux 2 instance (`menniboe-web-a`).
2. Note its AZ: instance page → **Networking** tab → *Availability zone*.
3. Left nav → **Elastic Block Store → Volumes** → **Create volume**
   - Volume type: `gp3`
   - Size: `2 GiB`
   - Availability Zone: **must match** your instance's AZ
   - Create Volume
4. Select the new volume → **Actions → Attach volume** → choose your instance → Attach

![Screenshot placeholder: EC2 Volumes console showing the new gp3 volume in "in-use" state](images/screenshot-stage1-volume-attached.png)

> [!NOTE]
> If "Attach volume" shows no instances in the dropdown, the volume and instance are in different AZs — go back and recreate the volume in the correct AZ (Module 1's AZ-lock rule in action).

### Stage 2: Verify Delete on Termination

1. Instances → select your instance → **Storage** tab → scroll right on the Block devices table
   - Root volume → Delete on Termination = **Yes** (default)
   - Secondary volume → Delete on Termination = **No** (default)
2. To change this at launch time instead: Launch Instance → *Advanced details* → *Storage* → expand the volume row → toggle **Delete on termination**

![Screenshot placeholder: Block devices table with the Delete on Termination column visible](images/screenshot-stage2-delete-on-termination.png)

### Stage 3: Snapshot & Cross-AZ Migration

1. Volumes → select your 2 GiB volume → **Actions → Create snapshot** → description `demo-snapshot` → Create
2. Snapshots (left nav) → wait for status **Completed**, 100%
3. Select it → **Actions → Create volume from snapshot**
   - Size: `2 GiB`, Type: `gp3`
   - Availability Zone: pick **AZ-B** (different from your instance)
   - Create volume
4. Confirm the new volume lives in AZ-B — proof snapshots aren't AZ-locked, even though volumes are.

> [!TIP]
> This is the standard exam-scenario answer for "how do you move an EBS volume to another AZ" — snapshot, then create-volume-from-snapshot in the target AZ. No direct cross-AZ attach exists.

### Stage 4: Encrypt an Existing Volume

1. Snapshots → select the original snapshot → **Actions → Copy snapshot**
   - Destination Region: same region
   - Check **Encrypt this snapshot** → choose a KMS key (e.g. `aws/ebs`)
   - Copy snapshot → wait for status **Completed**
2. Select the encrypted snapshot → **Actions → Create volume from snapshot** (encryption inherited automatically) → Create volume
3. Attach this encrypted volume to your instance: Volumes → select → **Actions → Attach volume**

![Screenshot placeholder: Copy snapshot dialog with "Encrypt this snapshot" checked and a KMS key selected](images/screenshot-stage4-encrypt-copy.png)

> [!WARNING]
> Encryption cannot be toggled on an existing volume in place. If you try to "Modify volume" looking for an encryption checkbox, you won't find one — the copy-snapshot workflow above is the only path.

### Stage 5: Build & Launch from a Custom AMI

1. Launch a fresh Amazon Linux 2 `t2.micro` (`menniboe-web-base`). Under *Advanced details* → **User data**:

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
```

2. Launch → wait ~1–2 min for user data to finish → verify via EC2 Instance Connect:

```bash
sudo systemctl status httpd
```

3. Instance → **Actions → Image and templates → Create image** → name `menniboe-demo-image` → Create image
4. Left nav → **AMIs** → wait for status `pending` → `available`

![Screenshot placeholder: AMIs console with menniboe-demo-image in "available" state](images/screenshot-stage5-ami-available.png)

5. Launch a new instance (`menniboe-web-b`) → *Application and OS Images* → **My AMIs** tab → select `menniboe-demo-image`. *Advanced details* → User data (this time, only):

```bash
#!/bin/bash
echo "Hello from Menniboe Farm" > /var/www/html/index.html
```

6. Launch → open the public IP in a browser. It should load almost instantly — httpd was already baked into the AMI.

> [!NOTE]
> If the browser shows "connection refused," give it another minute — even a fast-booting AMI-based instance needs the user data script to finish before the new index page exists.

### Stage 6: Deploy EFS Across Two AZs

1. EC2 → Security Groups → Create security group `sg-menniboe-efs-demo`, inbound rule: NFS (port 2049), source = itself.
2. EFS Console → **Create file system → Customize**
   - File system type: **Regional**
   - Backups: enabled
   - Lifecycle: transition to IA after 30 days, Archive after 90 (optional, illustrative)
   - Throughput mode: **Elastic**
   - Network: default VPC, mount targets in all AZs, security group = `sg-menniboe-efs-demo`
   - Create → wait for **Available**
3. Launch **Instance A** in AZ-A and **Instance B** in AZ-B (Amazon Linux 2, `t2.micro`). During launch, expand **File systems** → Add EFS file system → select yours → mount point `/mnt/efs/fs1` (auto-attaches the security group and mount script).
4. Connect to Instance A (EC2 Instance Connect):

```bash
sudo su
echo "hello world" > /mnt/efs/fs1/hello.txt
cat /mnt/efs/fs1/hello.txt
```

5. Connect to Instance B:

```bash
ls /mnt/efs/fs1/
cat /mnt/efs/fs1/hello.txt
```

6. Confirm `hello.txt` and its contents appear on Instance B too — shared file system across AZs, verified.

![Screenshot placeholder: terminal output on Instance B showing hello.txt and its contents](images/screenshot-stage6-efs-shared-file.png)

> [!IMPORTANT]
> During instance launch, the console can't add a file system until a subnet is selected. If "Add file system" is greyed out, go back to *Network settings* → *Edit* → pick a subnet first, then return to *File systems*.

### Stage 7: Clean Up All Resources

1. EFS → select file system → Delete (type the file system ID to confirm)
2. EC2 → Instances → select all demo instances → **Terminate**
3. EBS → Volumes → delete any leftover "available" volumes
4. EBS → Snapshots → delete all demo snapshots
5. EC2 → Security Groups → delete `sg-menniboe-efs-demo` and any auto-created `efs-sg-*` groups

> [!WARNING]
> Security group deletion will fail with "still in use" until every dependent instance has fully finished terminating. Wait a minute and retry rather than assuming something is wrong.

---

## Quiz Recap

10 exam-style scenario questions, one per module, all answered correctly on the first attempt:

| # | Module | Scenario tested |
|---|---|---|
| 1 | EBS Fundamentals | Attaching a volume across AZs |
| 2 | Delete on Termination | Root vs. secondary volume defaults |
| 3 | Volume Types | Throughput-heavy, low-cost, non-boot workload → st1 |
| 4 | Snapshots | Recovering an accidentally deleted snapshot via Recycle Bin |
| 5 | AMI | Why you stop an instance before imaging it |
| 6 | Instance Store | Max-performance, disposable scratch data |
| 7 | Multi-Attach | AZ + 16-instance limits |
| 8 | Encryption | Copy-snapshot-to-encrypt workflow |
| 9 | EFS | Multi-AZ, multi-instance concurrent file access |
| 10 | Comparison | Matching DB / shared assets / disposable cache to the right storage type |