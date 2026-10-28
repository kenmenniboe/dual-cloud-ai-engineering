# Commands: AWS Security and Encryption

All commands run in **AWS CloudShell, us-east-1**. Replace `<ACCOUNT_ID>`, `<ALB_DNS_NAME>`, `<INSTANCE_ID>` and the security group IDs with your own values.

> [!WARNING]
> CloudShell behaves like zsh: square brackets in pasted text are treated as glob patterns. Paste only commands, never expected output.

---

## Lab 1: KMS and S3

### Console steps as CLI (optional CLI-only redo)

```bash
# Create the customer managed key
KEY_ID=$(aws kms create-key \
  --description "Day 4 lab - encrypt Menniboe order objects in S3" \
  --tags TagKey=Project,TagValue=saa-day4 \
  --query KeyMetadata.KeyId --output text); echo $KEY_ID
aws kms create-alias --alias-name alias/menniboe-orders-key --target-key-id $KEY_ID
aws kms enable-key-rotation --key-id $KEY_ID --rotation-period-in-days 365
aws kms get-key-rotation-status --key-id $KEY_ID

# Bucket with SSE-KMS default encryption + Bucket Key
BUCKET=menniboe-day4-orders-<suffix>
aws s3api create-bucket --bucket $BUCKET
aws s3api put-public-access-block --bucket $BUCKET \
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
aws s3api put-bucket-encryption --bucket $BUCKET --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"alias/menniboe-orders-key"},"BucketKeyEnabled":true}]}'
aws s3api put-bucket-tagging --bucket $BUCKET --tagging 'TagSet=[{Key=Project,Value=saa-day4}]'

# Upload and check the object's encryption
aws s3 cp orders-2026-10.csv s3://$BUCKET/
aws s3api head-object --bucket $BUCKET --key orders-2026-10.csv \
  --query "{SSE:ServerSideEncryption,Key:SSEKMSKeyId,BucketKey:BucketKeyEnabled}"
```

### CloudTrail: find the key usage

```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=kms.amazonaws.com \
  --max-results 20 --query "Events[].[EventTime,EventName,Username]" --output table
```

### Role with S3 read and no KMS

```bash
aws iam create-role --role-name menniboe-s3-readonly-no-kms \
  --description "Day 4 lab - S3 read only, no KMS permissions" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"AWS":"arn:aws:iam::<ACCOUNT_ID>:root"},"Action":"sts:AssumeRole"}]}' \
  --tags Key=Project,Value=saa-day4
aws iam attach-role-policy --role-name menniboe-s3-readonly-no-kms \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# Test as the role (expect AccessDenied on kms:Decrypt before the key grant)
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::<ACCOUNT_ID>:role/menniboe-s3-readonly-no-kms \
  --role-session-name test --query Credentials --output json)
AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r .AccessKeyId) \
AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r .SecretAccessKey) \
AWS_SESSION_TOKEN=$(echo $CREDS | jq -r .SessionToken) \
aws s3 cp s3://$BUCKET/orders-2026-10.csv -
```

> [!NOTE]
> In the lab, the role was added as a **key user** through the console (Key policy → Key users → Add). From the CLI, that means editing the key policy with `aws kms get-key-policy` / `aws kms put-key-policy`.

---

## Lab 2: Parameter Store and Secrets Manager

### Create (CLI equivalent of the console steps)

```bash
aws ssm put-parameter --name /menniboe/dev/db-url --type String \
  --value "menniboe-dev-db.example.internal:5432" \
  --description "Day 4 lab - dev database endpoint" --tags Key=Project,Value=saa-day4
aws ssm put-parameter --name /menniboe/dev/db-password --type SecureString \
  --key-id alias/menniboe-orders-key --value '<test-password>' \
  --description "Day 4 lab - dev database password" --tags Key=Project,Value=saa-day4

aws secretsmanager create-secret --name menniboe/dev/db-credentials \
  --description "Day 4 lab - dev DB credentials" --kms-key-id alias/menniboe-orders-key \
  --secret-string '{"username":"menniboe_app","password":"<test-password>","engine":"postgres","host":"menniboe-dev-db.example.internal","port":"5432"}' \
  --tags Key=Project,Value=saa-day4
```

### Read (used in the lab)

```bash
aws ssm get-parameter --name /menniboe/dev/db-url
aws ssm get-parameter --name /menniboe/dev/db-password
aws ssm get-parameter --name /menniboe/dev/db-password --with-decryption
aws ssm get-parameters-by-path --path /menniboe/dev --with-decryption \
  --query "Parameters[].{Name:Name,Type:Type,Value:Value}" --output table
aws ssm describe-parameters \
  --parameter-filters "Key=Name,Values=/menniboe/dev/db-password" \
  --query "Parameters[].{Name:Name,Type:Type,Tier:Tier,KeyId:KeyId}" --output table

aws secretsmanager get-secret-value --secret-id menniboe/dev/db-credentials
```

---

## Lab 3: ALB and WAF

### Web server user data

```bash
#!/bin/bash
dnf install -y httpd
echo "<h1>Menniboe Farm shop</h1><p>Served by $(hostname -f)</p>" > /var/www/html/index.html
systemctl enable --now httpd
```

### Flood test (used in the lab)

```bash
curl -s https://checkip.amazonaws.com
ALB="http://<ALB_DNS_NAME>"

# 120 requests at about 2 per second
for i in $(seq 1 120); do echo "$i $(curl -s -o /dev/null -w '%{http_code}' $ALB)"; sleep 0.5; done

# Stop at the first 403, then inspect WAF's block page
for i in $(seq 1 150); do c=$(curl -s -o /dev/null -w '%{http_code}' $ALB); echo "$i $c"; [ "$c" = "403" ] && break; sleep 0.5; done
curl -s $ALB
curl -s -o /dev/null -w '%{http_code}\n' $ALB
```

### Inspect the Web ACL

```bash
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 --query "WebACLs[].Name"
aws wafv2 get-sampled-requests --web-acl-arn <WEB_ACL_ARN> --rule-metric-name menniboe-rate-limit \
  --scope REGIONAL --max-items 50 \
  --time-window StartTime=$(date -u -d '-3 hours' +%s),EndTime=$(date -u +%s) \
  --query "SampledRequests[].[Request.ClientIP,Action]" --output table
```

---

## Teardown

Run in this order.

### 1. WAF Web ACL

```bash
ALB_ARN=$(aws elbv2 describe-load-balancers --names menniboe-web-alb \
  --query "LoadBalancers[0].LoadBalancerArn" --output text); echo $ALB_ARN
aws wafv2 disassociate-web-acl --resource-arn $ALB_ARN --region us-east-1
ACL_ID=$(aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 \
  --query "WebACLs[?Name=='menniboe-web-acl'].Id" --output text)
ACL_LOCK=$(aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 \
  --query "WebACLs[?Name=='menniboe-web-acl'].LockToken" --output text)
aws wafv2 delete-web-acl --name menniboe-web-acl --scope REGIONAL \
  --id $ACL_ID --lock-token $ACL_LOCK --region us-east-1
aws wafv2 list-web-acls --scope REGIONAL --region us-east-1 --query "WebACLs[].Name"
```

### 2. Application Load Balancer

```bash
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
aws elbv2 wait load-balancers-deleted --load-balancer-arns $ALB_ARN && echo "ALB deleted"
aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='menniboe-web-alb'].LoadBalancerName"
```

### 3. Target group

```bash
TG_ARN=$(aws elbv2 describe-target-groups --names menniboe-web-tg \
  --query "TargetGroups[0].TargetGroupArn" --output text)
aws elbv2 delete-target-group --target-group-arn $TG_ARN
aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='menniboe-web-tg'].TargetGroupName"
```

### 4. EC2 instance

```bash
aws ec2 terminate-instances --instance-ids <INSTANCE_ID> \
  --query "TerminatingInstances[].[InstanceId,CurrentState.Name]" --output table
aws ec2 wait instance-terminated --instance-ids <INSTANCE_ID> && echo "Instance terminated"
aws ec2 describe-volumes --filters Name=tag:Project,Values=saa-day4 --query "Volumes[].VolumeId" --output text
```

### 5. Security groups (web first, then ALB)

```bash
aws ec2 delete-security-group --group-id <WEB_SG_ID>
aws ec2 delete-security-group --group-id <ALB_SG_ID>
aws ec2 describe-security-groups \
  --filters Name=group-name,Values=menniboe-web-sg,menniboe-alb-sg \
  --query "SecurityGroups[].GroupName"
```

### 6. Secrets Manager secret

```bash
aws secretsmanager delete-secret --secret-id menniboe/dev/db-credentials --force-delete-without-recovery
aws secretsmanager list-secrets --include-planned-deletion \
  --query "SecretList[?Name=='menniboe/dev/db-credentials'].Name"
```

### 7. Parameter Store

```bash
aws ssm delete-parameters --names /menniboe/dev/db-url /menniboe/dev/db-password
aws ssm get-parameters-by-path --path /menniboe/dev --query "Parameters[].Name"
```

### 8. S3 bucket

```bash
aws s3 rm s3://menniboe-day4-orders-<suffix> --recursive
aws s3 rb s3://menniboe-day4-orders-<suffix>
aws s3 ls | grep menniboe-day4
```

### 9. IAM role

```bash
aws iam detach-role-policy --role-name menniboe-s3-readonly-no-kms \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam delete-role --role-name menniboe-s3-readonly-no-kms
aws iam get-role --role-name menniboe-s3-readonly-no-kms 2>&1 | grep -o NoSuchEntity
```

### 10. KMS key (last)

```bash
aws kms schedule-key-deletion --key-id <KEY_ID> --pending-window-in-days 7
aws kms describe-key --key-id <KEY_ID> --query "KeyMetadata.[KeyState,DeletionDate]" --output text
# Undo within the window if needed:
# aws kms cancel-key-deletion --key-id <KEY_ID>
```

### 11. Tag sweep

```bash
aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=Project,Values=saa-day4 \
  --query "ResourceTagMappingList[].ResourceARN" --output text
```

Expected: only the KMS key while it is pending deletion.
