# Commands — AWS Storage Hands-On

Every CLI command from the session, grouped by tool and workflow stage. Copy-paste ready.

> Variables live only in the current shell. Stay in one terminal per lab.

---

## Table of contents

- [Lab 1 — DataSync](#lab-1--datasync)
  - [Environment and buckets](#environment-and-buckets)
  - [Stage test data](#stage-test-data)
  - [IAM role](#iam-role)
  - [DataSync locations](#datasync-locations)
  - [DataSync task and execution](#datasync-task-and-execution)
  - [Verify](#verify)
  - [Teardown — Lab 1](#teardown--lab-1)
- [Lab 2 — S3 File Gateway](#lab-2--s3-file-gateway)
  - [Environment and bucket](#environment-and-bucket)
  - [NFS client setup](#nfs-client-setup)
  - [Mount and inspect](#mount-and-inspect)
  - [Write through the share](#write-through-the-share)
  - [Teardown — Lab 2](#teardown--lab-2)
- [Account hygiene checks](#account-hygiene-checks)
- [Optional — CloudWatch logging](#optional--cloudwatch-logging)

---

# Lab 1 — DataSync

## Environment and buckets

```bash
export AWS_REGION=us-east-1
export SUFFIX=$(date +%s)
export SRC_BUCKET=datasync-lab-src-$SUFFIX
export DST_BUCKET=datasync-lab-dst-$SUFFIX

aws s3 mb s3://$SRC_BUCKET --region $AWS_REGION
aws s3 mb s3://$DST_BUCKET --region $AWS_REGION

echo "SRC=$SRC_BUCKET"
echo "DST=$DST_BUCKET"
```

## Stage test data

```bash
mkdir -p /tmp/datasync-lab && cd /tmp/datasync-lab
echo "claim record 001" > claim-001.txt
echo "claim record 002" > claim-002.txt
mkdir -p archive && echo "old record" > archive/legacy.txt

aws s3 cp . s3://$SRC_BUCKET/ --recursive
aws s3 ls s3://$SRC_BUCKET/ --recursive
```

## IAM role

Trust policy and role:

```bash
cat > trust.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow",
"Principal":{"Service":"datasync.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF

aws iam create-role --role-name DataSyncLabRole \
  --assume-role-policy-document file://trust.json
```

Permissions policy — note the two statements, bucket ARN and object ARN:

```bash
cat > policy.json <<EOF
{"Version":"2012-10-17","Statement":[
{"Effect":"Allow","Action":["s3:GetBucketLocation","s3:ListBucket","s3:ListBucketMultipartUploads"],
"Resource":["arn:aws:s3:::$SRC_BUCKET","arn:aws:s3:::$DST_BUCKET"]},
{"Effect":"Allow","Action":["s3:AbortMultipartUpload","s3:DeleteObject","s3:GetObject","s3:ListMultipartUploadParts","s3:PutObject","s3:GetObjectTagging","s3:PutObjectTagging"],
"Resource":["arn:aws:s3:::$SRC_BUCKET/*","arn:aws:s3:::$DST_BUCKET/*"]}]}
EOF

aws iam put-role-policy --role-name DataSyncLabRole \
  --policy-name DataSyncLabS3 --policy-document file://policy.json

export ROLE_ARN=$(aws iam get-role --role-name DataSyncLabRole --query Role.Arn --output text)
echo $ROLE_ARN
```

## DataSync locations

```bash
export SRC_LOC=$(aws datasync create-location-s3 \
  --s3-bucket-arn arn:aws:s3:::$SRC_BUCKET \
  --s3-config BucketAccessRoleArn=$ROLE_ARN \
  --region $AWS_REGION --query LocationArn --output text)

export DST_LOC=$(aws datasync create-location-s3 \
  --s3-bucket-arn arn:aws:s3:::$DST_BUCKET \
  --s3-config BucketAccessRoleArn=$ROLE_ARN \
  --region $AWS_REGION --query LocationArn --output text)

echo "$SRC_LOC -> $DST_LOC"
```

*If this errors with "unable to assume role", wait ~15 seconds for IAM propagation and rerun.*

## DataSync task and execution

```bash
export TASK=$(aws datasync create-task \
  --source-location-arn $SRC_LOC --destination-location-arn $DST_LOC \
  --name s3-to-s3-lab \
  --options VerifyMode=ONLY_FILES_TRANSFERRED,LogLevel=OFF \
  --region $AWS_REGION --query TaskArn --output text)

echo "TASK=$TASK"

export EXEC=$(aws datasync start-task-execution --task-arn $TASK \
  --region $AWS_REGION --query TaskExecutionArn --output text)

echo "EXEC=$EXEC"
```

*`LogLevel=BASIC` fails without a CloudWatch log group — see [Optional — CloudWatch logging](#optional--cloudwatch-logging).*

Second run, to prove incremental behaviour:

```bash
export EXEC2=$(aws datasync start-task-execution --task-arn $TASK \
  --region $AWS_REGION --query TaskExecutionArn --output text)

sleep 30
```

## Verify

Poll until `Status` is `SUCCESS`:

```bash
aws datasync describe-task-execution --task-execution-arn $EXEC \
  --region $AWS_REGION \
  --query '{Status:Status,Files:FilesTransferred,Bytes:BytesTransferred}'
```

```bash
aws datasync describe-task-execution --task-execution-arn $EXEC2 \
  --region $AWS_REGION \
  --query '{Status:Status,Files:FilesTransferred,Bytes:BytesTransferred}'
```

Destination listing:

```bash
aws s3 ls s3://$DST_BUCKET/ --recursive
```

## Teardown — Lab 1

```bash
aws datasync delete-task --task-arn $TASK --region $AWS_REGION
aws datasync delete-location --location-arn $SRC_LOC --region $AWS_REGION
aws datasync delete-location --location-arn $DST_LOC --region $AWS_REGION

aws s3 rb s3://$SRC_BUCKET --force
aws s3 rb s3://$DST_BUCKET --force

aws iam delete-role-policy --role-name DataSyncLabRole --policy-name DataSyncLabS3
aws iam delete-role --role-name DataSyncLabRole
```

Confirm:

```bash
aws s3 ls | grep datasync-lab
aws datasync list-tasks --region $AWS_REGION
```

---

# Lab 2 — S3 File Gateway

## Environment and bucket

```bash
export AWS_REGION=us-east-1
export SGW_BUCKET=sgw-lab-$(date +%s)

aws s3 mb s3://$SGW_BUCKET --region $AWS_REGION
echo $SGW_BUCKET
```

Verify it actually exists — a set variable does not prove the bucket was created:

```bash
aws s3 ls | grep sgw-lab
```

## NFS client setup

Run on the `nfs-client` EC2 instance:

```bash
sudo dnf install -y nfs-utils
sudo mkdir -p /mnt/sgw
```

Diagnose Instance Connect failures from a workstation shell:

```bash
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=nfs-client" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,SecurityGroups[0].GroupId]' \
  --output table
```

## Mount and inspect

```bash
sudo mount -t nfs -o nolock,hard <gateway-private-ip>:/<bucket-name> /mnt/sgw

df -h /mnt/sgw
mount | grep sgw
```

As run in this session:

```bash
sudo mount -t nfs -o nolock,hard 172.31.23.174:/sgw-lab-1791952330 /mnt/sgw
```

Other platforms, from the file share detail page:

```bash
# Windows
mount -o nolock -o mtype=hard <gateway-ip>:/<bucket-name> <DriveLetter>:

# macOS
sudo mount -t nfs -o vers=3,rsize=1048576,wsize=1048576,hard,nolock -v <gateway-ip>:/<bucket-name> /mount/path
```

## Write through the share

```bash
echo "invoice 001 from the gateway" | sudo tee /mnt/sgw/invoice-001.txt
sudo mkdir -p /mnt/sgw/reports
echo "quarterly report" | sudo tee /mnt/sgw/reports/q3.txt
ls -la /mnt/sgw
```

Confirm objects landed in S3:

```bash
aws s3 ls s3://$SGW_BUCKET/ --recursive
```

Read back — a cache hit:

```bash
cat /mnt/sgw/invoice-001.txt
```

## Teardown — Lab 2

Unmount from the client first:

```bash
sudo umount /mnt/sgw
```

Then delete the file share and gateway in the console, terminate both instances, and:

```bash
aws s3 rb s3://$SGW_BUCKET --force
```

---

# Account hygiene checks

Run after every lab. Empty output means clean — the AWS CLI prints nothing at all for a zero-row table.

Running instances:

```bash
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running,pending" \
  --query 'Reservations[].Instances[].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' \
  --output table
```

Orphaned EBS volumes — the most common source of surprise bills:

```bash
aws ec2 describe-volumes \
  --filters "Name=status,Values=available" \
  --query 'Volumes[].[VolumeId,Size]' --output table
```

Delete an orphan:

```bash
aws ec2 delete-volume --volume-id <volume-id>
```

Terminate an instance:

```bash
aws ec2 terminate-instances --instance-ids <instance-id>
```

Worth adding to the same sweep: unassociated Elastic IPs and old snapshots.

---

# Optional — CloudWatch logging

Required if you want `LogLevel=BASIC` on a DataSync task:

```bash
aws logs create-log-group --log-group-name /aws/datasync/lab --region $AWS_REGION

export LOG_ARN=$(aws logs describe-log-groups --log-group-name-prefix /aws/datasync/lab \
  --region $AWS_REGION --query 'logGroups[0].arn' --output text)
```

Then add to `create-task`:

```bash
--cloud-watch-log-group-arn $LOG_ARN --options VerifyMode=ONLY_FILES_TRANSFERRED,LogLevel=BASIC
```
