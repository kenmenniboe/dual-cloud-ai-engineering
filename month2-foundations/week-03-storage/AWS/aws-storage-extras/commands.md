# Console paths and reference commands

> [!NOTE]
> The lecture modules were concept-only — no commands were executed during this portion of the session. Everything below is reference material: the console navigation paths covered per service, plus read-only CLI commands for exploring each one.
>
> Commands that were actually run live in `aws-storage-hands-on/commands.md`.

---

## Table of contents

- [Snow Family](#snow-family)
- [Amazon FSx](#amazon-fsx)
- [AWS Storage Gateway](#aws-storage-gateway)
- [AWS Transfer Family](#aws-transfer-family)
- [AWS DataSync](#aws-datasync)
- [Cross-service inventory sweep](#cross-service-inventory-sweep)

---

## Snow Family

**Console:** AWS Snow Family → Order an AWS Snow Family device → Job type (Import into Amazon S3 / Export from Amazon S3 / Local compute and storage) → Device type → Shipping address → Security (KMS key, IAM role) → Notifications (SNS topic) → Review → Create job

List existing jobs:

```bash
aws snowball list-jobs --region us-east-1
aws snowball describe-job --job-id <job-id> --region us-east-1
```

Available device types and capacity for a Region:

```bash
aws snowball list-compatible-images --region us-east-1
```

---

## Amazon FSx

**Console:** FSx → Create file system → choose file system type (Windows File Server / Lustre / NetApp ONTAP / OpenZFS) → Quick create or Standard create

**FSx for Windows — Standard create tabs:**
- File system details: name, deployment type (Multi-AZ / Single-AZ), storage type (SSD / HDD), storage capacity, throughput capacity
- Network & security: VPC, security groups, subnets, preferred subnet
- Windows authentication: AWS Managed Microsoft AD / Self-managed AD (DNS IPs, domain name, service account)
- Encryption: KMS key
- Maintenance: backup window, retention, weekly maintenance window

**FSx for Lustre — Standard create tabs:**
- File system details: deployment type (Scratch / Persistent), storage type (SSD / HDD), capacity, throughput per TiB
- Data repository import/export: linked S3 bucket, import path, export path, import policy
- Network & security: VPC, subnet (single only), security groups
- Encryption, Maintenance

List and inspect file systems:

```bash
aws fsx describe-file-systems --region us-east-1

aws fsx describe-file-systems --region us-east-1 \
  --query 'FileSystems[].[FileSystemId,FileSystemType,StorageCapacity,Lifecycle]' \
  --output table
```

Data repository associations (the Lustre-to-S3 link):

```bash
aws fsx describe-data-repository-associations --region us-east-1
```

Backups:

```bash
aws fsx describe-backups --region us-east-1
```

---

## AWS Storage Gateway

**Console:** Storage Gateway → Create gateway → Set up gateway (name, time zone, gateway type, host platform) → Connect to AWS (IP address or activation key, service endpoint) → Review and activate → Configure gateway (cache disk, CloudWatch log group, alarms)

> [!TIP]
> Launch the appliance from **Storage Gateway → Create gateway → Host platform: Amazon EC2 → Launch instance**, not by searching the EC2 AMI catalog. Marketplace searches for "gateway" return unrelated third-party products.

List gateways and their file shares:

```bash
aws storagegateway list-gateways --region us-east-1

aws storagegateway describe-gateway-information \
  --gateway-arn <gateway-arn> --region us-east-1

aws storagegateway list-file-shares --region us-east-1
```

Inspect an NFS share's configuration:

```bash
aws storagegateway describe-nfs-file-shares \
  --file-share-arn-list <share-arn> --region us-east-1
```

Local disks available for cache allocation:

```bash
aws storagegateway list-local-disks --gateway-arn <gateway-arn> --region us-east-1
```

Volume and tape gateways:

```bash
aws storagegateway list-volumes --region us-east-1
aws storagegateway list-tapes --region us-east-1
```

---

## AWS Transfer Family

**Console:** Transfer Family → Create server → Choose protocols (SFTP / FTPS / FTP) → Choose an identity provider (Service managed / AWS Directory Service / Custom) → Choose an endpoint (Publicly accessible / VPC hosted) → Choose a domain (Amazon S3 / Amazon EFS) → Configure additional details (logging role, security policy, tags) → Create

Then: Server → Add user → username, IAM role, home directory, SSH public key.

List servers and users:

```bash
aws transfer list-servers --region us-east-1

aws transfer describe-server --server-id <server-id> --region us-east-1

aws transfer list-users --server-id <server-id> --region us-east-1
```

---

## AWS DataSync

**Console:** DataSync → Locations → Create location → location type → settings. Then Tasks → Create task → source location → destination location → settings → Create.

Agents (only needed for on-premises or another cloud):

```bash
aws datasync list-agents --region us-east-1
```

Locations and tasks:

```bash
aws datasync list-locations --region us-east-1
aws datasync list-tasks --region us-east-1

aws datasync describe-task --task-arn <task-arn> --region us-east-1
```

Execution history for a task:

```bash
aws datasync list-task-executions --task-arn <task-arn> --region us-east-1
```

---

## Cross-service inventory sweep

Useful for confirming nothing from a study session is still running. Empty output means clean — the AWS CLI prints nothing at all for a zero-row table.

```bash
export AWS_REGION=us-east-1

aws fsx describe-file-systems --region $AWS_REGION \
  --query 'FileSystems[].[FileSystemId,FileSystemType,Lifecycle]' --output table

aws storagegateway list-gateways --region $AWS_REGION \
  --query 'Gateways[].[GatewayId,GatewayType,GatewayOperationalState]' --output table

aws transfer list-servers --region $AWS_REGION \
  --query 'Servers[].[ServerId,State]' --output table

aws datasync list-tasks --region $AWS_REGION

aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running,pending" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType]' --output table

aws ec2 describe-volumes --filters "Name=status,Values=available" \
  --query 'Volumes[].[VolumeId,Size]' --output table
```
