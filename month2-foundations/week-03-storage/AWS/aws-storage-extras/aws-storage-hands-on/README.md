# AWS Storage Hands-On — DataSync and S3 File Gateway

Two hands-on labs from the AWS SAA "Storage Extras" track. Both built end to end in `us-east-1`, verified, and torn down the same session.

![Architecture](images/architecture-diagram.svg)

---

## What I built

**Lab 1 — AWS DataSync, S3 to S3 (CLI)**
A DataSync task copying three objects between two S3 buckets, with an IAM role scoped to just those buckets. Ran it twice to prove the transfer is incremental.

**Lab 2 — Amazon S3 File Gateway (Console)**
A gateway appliance on EC2, activated, backed by a 150 GiB cache disk, exposing an S3 bucket as an NFS share. Mounted it from a second EC2 instance and watched filesystem writes land in S3 as objects.

---

## Key results

| Check | Result |
|---|---|
| DataSync first run | `SUCCESS` — 3 files, 45 bytes |
| DataSync second run (no changes) | `SUCCESS` — **0 files, 0 bytes** |
| Folder structure preserved | `archive/legacy.txt` key intact in destination |
| Gateway status after activation | `Running` — `sgw-lab`, type S3 File |
| Cache disk | `/dev/sdb`, 150 GiB, allocated to Cache |
| NFS mount | `vers=4.2`, size reported as **8.0E** |
| File-to-object | `invoice-001.txt` → S3 object, 29 B, Standard |
| Nested write | `reports/q3.txt` → 17 B, plus a 0-byte `reports/` folder object |
| Teardown | 0 running instances, 0 unattached volumes |

---

## Things worth remembering

- **AWS-to-AWS DataSync needs no agent.** Agents exist for on-premises and other-cloud sources, not for account or Region boundaries.
- **DataSync is incremental.** It compares name, size, and timestamp, then moves only the delta. The second run transferred nothing.
- **Bucket ARN and object ARN are different resources.** `ListBucket` on `arn:aws:s3:::bucket` and `GetObject` on `arn:aws:s3:::bucket/*` must be separate statements, or the policy silently never matches.
- **Permission and reachability are independent problems.** An NFS allowed-clients CIDR of `0.0.0.0/0` still cannot reach a private `172.31.x.x` address from the internet.
- **File Gateway latency is variable by design.** Cache hit feels local; cache miss is an S3 round trip. The full dataset is always visible regardless of cache size.
- **`df` is meaningless on a File Gateway share.** It reports 8 exabytes. Watch the `CachePercentDirty` CloudWatch metric instead.
- **DataSync creates prefixes; File Gateway creates folder objects.** POSIX semantics force the gateway to materialize an empty directory as a real zero-byte object.
- **NFS is not one port.** The gateway security group opened 2049, 111, and 20048 across both TCP and UDP, plus SMB on 445 and 139.
- **Orphaned EBS volumes survive instance termination.** An 80 GiB volume was left in `available` state after teardown and had to be deleted explicitly.

---

## Errors hit and fixed

1. `LogLevelSetWithNoLogGroup` — `create-task` rejected `LogLevel=BASIC` without a CloudWatch log group ARN.
2. `argument --region: expected one argument` — `$AWS_REGION` was unset because the export line was skipped during paste.
3. Marketplace AMI search returned third-party "gateway" products — wrong entry point for launching the appliance.
4. EC2 Instance Connect failed with a generic SSH error — security group and public IP prerequisites.

Full detail, with each fix placed where it happened, is in [`notes.md`](notes.md).

---

## Files

- [`notes.md`](notes.md) — full tutorial and copy-paste redo guide, with console field values, CLI, errors, and screenshots
- [`commands.md`](commands.md) — every command from the session, grouped by stage
- [`images/`](images/) — architecture diagram and session screenshots

**Region:** us-east-1 · **VPC CIDR:** 172.31.0.0/16 · **Estimated cost:** under $1 (gateway `m5.xlarge` ran roughly one hour)
