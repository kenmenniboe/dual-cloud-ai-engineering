# Commands: Day 7 lab (CloudFormation, Session Manager, AWS Backup)

Every command used in the lab, grouped by stage, plus a CLI-only redo path. Run them in AWS CloudShell. Each command sets its own `--region`, so any CloudShell Region tab works.

> [!TIP]
> CloudShell can behave like zsh when pasting. Avoid `!` inside double quotes, and for longer blocks save them to a file and run `bash file.sh`.

## Contents

- [Lab 1 Default VPC and stack checks](#lab-1-default-vpc-and-stack-checks)
- [Lab 2 Session Manager and CloudTrail](#lab-2-session-manager-and-cloudtrail)
- [Lab 3 AWS Backup checks and monitoring](#lab-3-aws-backup-checks-and-monitoring)
- [Teardown script](#teardown-script)
- [CLI-only redo](#cli-only-redo)

---

## Lab 1 Default VPC and stack checks

```bash
# Confirm the default VPC exists in us-east-1
aws ec2 describe-vpcs --region us-east-1 \
  --filters Name=isDefault,Values=true \
  --query "Vpcs[].{VpcId:VpcId,Cidr:CidrBlock}" --output table

# Confirm the stack's instance: public IP, instance profile, security group
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:project,Values=day7-lab" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].{Id:InstanceId,PublicIp:PublicIpAddress,Role:IamInstanceProfile.Arn,SG:SecurityGroups[0].GroupId}" \
  --output table

# Stack outputs
aws cloudformation describe-stacks --region us-east-1 --stack-name day7-ssm-backup-lab \
  --query "Stacks[0].Outputs" --output table
```

## Lab 2 Session Manager and CloudTrail

```bash
# Is the instance a managed node?
aws ssm describe-instance-information --region us-east-1 \
  --filters "Key=InstanceIds,Values=i-0f0e9ad01bd32f392" \
  --query "InstanceInformationList[].{Id:InstanceId,Ping:PingStatus,Platform:PlatformName,Agent:AgentVersion}" \
  --output table

# Prove the security group has zero inbound rules ("Inbound": [])
aws ec2 describe-security-groups --region us-east-1 \
  --group-ids sg-0b61438215633ae87 \
  --query "SecurityGroups[0].{Inbound:IpPermissions,OutboundCount:length(IpPermissionsEgress)}"
```

Inside the Session Manager shell:

```bash
whoami
hostname
cat /etc/os-release | head -2
systemctl is-active amazon-ssm-agent
sudo ss -tnp | grep -i ssm      # outbound ESTAB connections to :443
sudo ss -tlnp | grep ':22'      # sshd listening, blocked by the security group
exit
```

Audit the session:

```bash
aws cloudtrail lookup-events --region us-east-1 \
  --lookup-attributes AttributeKey=EventName,AttributeValue=StartSession \
  --max-results 3 \
  --query "Events[].{Time:EventTime,User:Username,Event:EventName}" --output table

aws cloudtrail lookup-events --region us-east-1 \
  --lookup-attributes AttributeKey=EventName,AttributeValue=TerminateSession \
  --max-results 3 \
  --query "Events[].{Time:EventTime,User:Username,Event:EventName}" --output table
```

## Lab 3 AWS Backup checks and monitoring

```bash
# Both vaults
for R in us-east-1 us-west-2; do
  aws backup list-backup-vaults --region "$R" \
    --query "BackupVaultList[?starts_with(BackupVaultName,'day7-lab')].{Region:'$R',Name:BackupVaultName,Points:NumberOfRecoveryPoints}" \
    --output table
done

# Backup plan rule, retention and copy destination
PLAN_ID=$(aws backup list-backup-plans --region us-east-1 \
  --query "BackupPlansList[?BackupPlanName=='day7-lab-plan'].BackupPlanId" --output text)
aws backup get-backup-plan --region us-east-1 --backup-plan-id "$PLAN_ID" \
  --query "BackupPlan.Rules[].{Rule:RuleName,Vault:TargetBackupVaultName,Schedule:ScheduleExpression,Keep:Lifecycle.DeleteAfterDays,CopyTo:CopyActions[0].DestinationBackupVaultArn}" \
  --output json

# Resource assignment condition (expect aws:ResourceTag/backup = daily)
SEL_ID=$(aws backup list-backup-selections --region us-east-1 --backup-plan-id "$PLAN_ID" \
  --query "BackupSelectionsList[0].SelectionId" --output text)
aws backup get-backup-selection --region us-east-1 --backup-plan-id "$PLAN_ID" --selection-id "$SEL_ID" \
  --query "BackupSelection.{Name:SelectionName,Resources:Resources,Conditions:Conditions.StringEquals}"

# Backup jobs in the primary vault
aws backup list-backup-jobs --region us-east-1 \
  --by-backup-vault-name day7-lab-vault \
  --query "BackupJobs[].{State:State,Pct:PercentDone,Type:ResourceType,Created:CreationDate}" \
  --output table

# Watch one backup job until it finishes
JOB=4f728e22-9a4b-4ec0-b782-eea72840b9f7
while true; do
  S=$(aws backup describe-backup-job --region us-east-1 --backup-job-id "$JOB" \
      --query "[State,PercentDone]" --output text)
  echo "$(date +%T)  $S"
  case "$S" in COMPLETED*|FAILED*|ABORTED*|EXPIRED*) break;; esac
  sleep 30
done

# Copy jobs are listed in the SOURCE Region
aws backup list-copy-jobs --region us-east-1 \
  --query "CopyJobs[].{State:State,Created:CreationDate,DestRP:DestinationRecoveryPointArn}" \
  --output table

# Watch the latest copy job
while true; do
  S=$(aws backup list-copy-jobs --region us-east-1 --query "CopyJobs[0].State" --output text)
  echo "$(date +%T)  $S"
  case "$S" in COMPLETED|FAILED|ABORTED) break;; esac
  sleep 30
done

# Recovery point in the DR vault
aws backup list-recovery-points-by-backup-vault --region us-west-2 \
  --backup-vault-name day7-lab-dr-vault \
  --query "RecoveryPoints[].{Status:Status,Type:ResourceType,RP:RecoveryPointArn,Expires:CalculatedLifecycle.DeleteAt}" \
  --output table
```

## Teardown script

Saved as [`scripts/day7-teardown.sh`](scripts/day7-teardown.sh). Run with `bash day7-teardown.sh`. It deletes in reverse order (recovery points, plan, vaults, stack, template bucket, Backup service role) and finishes with a verification sweep. It is safe to rerun.

```bash
#!/bin/bash
# Day 7 lab teardown: AWS Backup (us-east-1 + us-west-2), CloudFormation stack, leftovers.

SRC_R=us-east-1
DR_R=us-west-2
SRC_V=day7-lab-vault
DR_V=day7-lab-dr-vault
PLAN_NAME=day7-lab-plan
STACK=day7-ssm-backup-lab
TEMPLATE_FILE=day7-ssm-backup-lab.yaml
LAB_DATE=2026-11-03            # change to the day you ran the lab
ROLE=AWSBackupDefaultServiceRole

echo "== T1: delete recovery points in both vaults =="
printf '%s %s\n' "$DR_R" "$DR_V" "$SRC_R" "$SRC_V" | while read -r R V; do
  aws backup list-recovery-points-by-backup-vault --region "$R" --backup-vault-name "$V" \
    --query "RecoveryPoints[].RecoveryPointArn" --output text 2>/dev/null | tr '\t' '\n' |
  while read -r ARN; do
    case "$ARN" in ""|None) continue;; esac
    echo "  deleting $ARN  ($V, $R)"
    aws backup delete-recovery-point --region "$R" --backup-vault-name "$V" --recovery-point-arn "$ARN"
  done
done

echo "== waiting for both vaults to report 0 recovery points =="
for i in $(seq 1 20); do
  N1=$(aws backup list-recovery-points-by-backup-vault --region "$DR_R" --backup-vault-name "$DR_V" \
        --query "length(RecoveryPoints)" --output text 2>/dev/null)
  N2=$(aws backup list-recovery-points-by-backup-vault --region "$SRC_R" --backup-vault-name "$SRC_V" \
        --query "length(RecoveryPoints)" --output text 2>/dev/null)
  N1=${N1:-0}; N2=${N2:-0}
  echo "  $(date +%T)  $DR_V=$N1  $SRC_V=$N2"
  [ "$N1" = "0" ] && [ "$N2" = "0" ] && break
  sleep 15
done

echo "== T2: delete resource assignments, then the backup plan =="
PLAN_ID=$(aws backup list-backup-plans --region "$SRC_R" \
  --query "BackupPlansList[?BackupPlanName=='$PLAN_NAME'].BackupPlanId" --output text)
case "$PLAN_ID" in
  ""|None) echo "  plan $PLAN_NAME not found (already deleted)";;
  *)
    aws backup list-backup-selections --region "$SRC_R" --backup-plan-id "$PLAN_ID" \
      --query "BackupSelectionsList[].SelectionId" --output text | tr '\t' '\n' |
    while read -r SEL; do
      case "$SEL" in ""|None) continue;; esac
      echo "  deleting selection $SEL"
      aws backup delete-backup-selection --region "$SRC_R" --backup-plan-id "$PLAN_ID" --selection-id "$SEL"
    done
    aws backup delete-backup-plan --region "$SRC_R" --backup-plan-id "$PLAN_ID" \
      --query "DeletionDate" --output text && echo "  deleted plan $PLAN_NAME"
    ;;
esac

echo "== T3: delete both vaults =="
aws backup delete-backup-vault --region "$DR_R"  --backup-vault-name "$DR_V"  && echo "  deleted $DR_V ($DR_R)"
aws backup delete-backup-vault --region "$SRC_R" --backup-vault-name "$SRC_V" && echo "  deleted $SRC_V ($SRC_R)"

echo "== T4: delete the CloudFormation stack =="
aws cloudformation delete-stack --region "$SRC_R" --stack-name "$STACK"
aws cloudformation wait stack-delete-complete --region "$SRC_R" --stack-name "$STACK" && echo "  stack deleted"

echo "== T5: remove this lab's template from cf-templates buckets =="
aws s3api list-buckets --query "Buckets[?starts_with(Name,'cf-templates-')].Name" --output text | tr '\t' '\n' |
while read -r B; do
  case "$B" in ""|None) continue;; esac
  BR=$(aws s3api get-bucket-location --bucket "$B" --query "LocationConstraint" --output text)
  case "$BR" in ""|None) BR=us-east-1;; esac
  for T in Versions DeleteMarkers; do
    aws s3api list-object-versions --region "$BR" --bucket "$B" \
      --query "$T[?ends_with(Key,'$TEMPLATE_FILE')].[Key,VersionId]" --output text 2>/dev/null |
    while read -r K VID; do
      case "$K" in ""|None) continue;; esac
      echo "  deleting s3://$B/$K ($VID)"
      aws s3api delete-object --region "$BR" --bucket "$B" --key "$K" --version-id "$VID" >/dev/null
    done
  done
  if aws s3api delete-bucket --region "$BR" --bucket "$B" 2>/dev/null; then
    echo "  deleted bucket $B"
  else
    echo "  kept bucket $B (it still holds templates from other stacks)"
  fi
done

echo "== T6: $ROLE (delete only if created on $LAB_DATE) =="
CREATED=$(aws iam get-role --role-name "$ROLE" --query "Role.CreateDate" --output text 2>/dev/null)
case "$CREATED" in
  "") echo "  role not found";;
  "$LAB_DATE"*)
    aws iam list-attached-role-policies --role-name "$ROLE" \
      --query "AttachedPolicies[].PolicyArn" --output text | tr '\t' '\n' |
    while read -r P; do
      case "$P" in ""|None) continue;; esac
      echo "  detaching $P"
      aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$P"
    done
    aws iam list-role-policies --role-name "$ROLE" --query "PolicyNames" --output text | tr '\t' '\n' |
    while read -r IP; do
      case "$IP" in ""|None) continue;; esac
      aws iam delete-role-policy --role-name "$ROLE" --policy-name "$IP"
    done
    aws iam delete-role --role-name "$ROLE" && echo "  deleted $ROLE"
    ;;
  *) echo "  kept $ROLE (created $CREATED, before this lab)";;
esac

echo "== T7: verification sweep =="
aws cloudformation describe-stacks --region "$SRC_R" --stack-name "$STACK" \
  --query "Stacks[].StackStatus" --output text 2>&1 | sed 's/^/   stack: /'
aws ec2 describe-instances --region "$SRC_R" \
  --filters "Name=tag:project,Values=day7-lab" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" --output text | sed 's/^/   instances: /'
for R in "$SRC_R" "$DR_R"; do
  echo "-- $R"
  aws backup list-backup-vaults --region "$R" \
    --query "BackupVaultList[?starts_with(BackupVaultName,'day7-lab')].BackupVaultName" --output text | sed 's/^/   vaults: /'
  aws backup list-backup-plans --region "$R" \
    --query "BackupPlansList[?starts_with(BackupPlanName,'day7-lab')].BackupPlanName" --output text | sed 's/^/   plans: /'
  aws ec2 describe-images --region "$R" --owners self --query "Images[].ImageId" --output text | sed 's/^/   AMIs: /'
  aws ec2 describe-snapshots --region "$R" --owner-ids self --query "Snapshots[].SnapshotId" --output text | sed 's/^/   snapshots: /'
done
aws iam get-role --role-name "$ROLE" --query "Role.CreateDate" --output text 2>&1 | sed 's/^/   role: /'
echo "== teardown finished =="
```

---

## CLI-only redo

The same lab without the console. Run the blocks in order in CloudShell, from a folder that contains `day7-ssm-backup-lab.yaml`.

> [!WARNING]
> `ACCOUNT_ID` is stored in a variable so it never appears in files or screenshots. Do not `echo` it while recording.

### 1. Variables

```bash
export AWS_PAGER=""
SRC_R=us-east-1
DR_R=us-west-2
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
```

### 2. Create the stack (Lab 1)

```bash
aws cloudformation create-stack --region "$SRC_R" \
  --stack-name day7-ssm-backup-lab \
  --template-body file://day7-ssm-backup-lab.yaml \
  --capabilities CAPABILITY_IAM \
  --tags Key=project,Value=day7-lab

aws cloudformation wait stack-create-complete --region "$SRC_R" --stack-name day7-ssm-backup-lab

INSTANCE_ID=$(aws cloudformation describe-stacks --region "$SRC_R" --stack-name day7-ssm-backup-lab \
  --query "Stacks[0].Outputs[?OutputKey=='InstanceId'].OutputValue" --output text)
echo "$INSTANCE_ID"

aws cloudformation describe-stack-events --region "$SRC_R" --stack-name day7-ssm-backup-lab \
  --query "reverse(StackEvents)[].{Time:Timestamp,Id:LogicalResourceId,Status:ResourceStatus}" --output table
```

### 3. Session Manager (Lab 2)

```bash
# CloudShell has the Session Manager plugin installed
aws ssm start-session --region "$SRC_R" --target "$INSTANCE_ID"
```

### 4. Vaults (Lab 3 Steps 1 and 2)

```bash
aws backup create-backup-vault --region "$DR_R"  --backup-vault-name day7-lab-dr-vault \
  --backup-vault-tags project=day7-lab
aws backup create-backup-vault --region "$SRC_R" --backup-vault-name day7-lab-vault \
  --backup-vault-tags project=day7-lab
```

### 5. Backup service role (created by the console's "default role" option)

```bash
cat > backup-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Principal": { "Service": "backup.amazonaws.com" }, "Action": "sts:AssumeRole" }
  ]
}
EOF

aws iam create-role --role-name AWSBackupDefaultServiceRole --path /service-role/ \
  --assume-role-policy-document file://backup-trust.json
aws iam attach-role-policy --role-name AWSBackupDefaultServiceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup
aws iam attach-role-policy --role-name AWSBackupDefaultServiceRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores

ROLE_ARN=arn:aws:iam::${ACCOUNT_ID}:role/service-role/AWSBackupDefaultServiceRole
```

If the role already exists from an earlier lab, `create-role` returns `EntityAlreadyExists`; skip to setting `ROLE_ARN`.

### 6. Backup plan with a cross-Region copy rule (Lab 3 Step 3)

```bash
cat > plan.json <<EOF
{
  "BackupPlanName": "day7-lab-plan",
  "Rules": [
    {
      "RuleName": "daily-with-dr-copy",
      "TargetBackupVaultName": "day7-lab-vault",
      "ScheduleExpression": "cron(0 5 ? * * *)",
      "StartWindowMinutes": 480,
      "CompletionWindowMinutes": 10080,
      "Lifecycle": { "DeleteAfterDays": 1 },
      "RecoveryPointTags": { "project": "day7-lab" },
      "CopyActions": [
        {
          "DestinationBackupVaultArn": "arn:aws:backup:${DR_R}:${ACCOUNT_ID}:backup-vault:day7-lab-dr-vault",
          "Lifecycle": { "DeleteAfterDays": 1 }
        }
      ]
    }
  ]
}
EOF

PLAN_ID=$(aws backup create-backup-plan --region "$SRC_R" \
  --backup-plan file://plan.json --backup-plan-tags project=day7-lab \
  --query BackupPlanId --output text)
echo "$PLAN_ID"
```

### 7. Tag-based assignment (Lab 3 Step 4)

```bash
cat > selection.json <<EOF
{
  "SelectionName": "day7-lab-tagged-resources",
  "IamRoleArn": "${ROLE_ARN}",
  "Resources": ["*"],
  "Conditions": {
    "StringEquals": [
      { "ConditionKey": "aws:ResourceTag/backup", "ConditionValue": "daily" }
    ]
  }
}
EOF

aws backup create-backup-selection --region "$SRC_R" \
  --backup-plan-id "$PLAN_ID" --backup-selection file://selection.json
```

### 8. On-demand backup (Lab 3 Step 5)

```bash
JOB=$(aws backup start-backup-job --region "$SRC_R" \
  --backup-vault-name day7-lab-vault \
  --resource-arn "arn:aws:ec2:${SRC_R}:${ACCOUNT_ID}:instance/${INSTANCE_ID}" \
  --iam-role-arn "$ROLE_ARN" \
  --lifecycle DeleteAfterDays=1 \
  --recovery-point-tags project=day7-lab \
  --query BackupJobId --output text)

# Wait with the monitoring loop from Lab 3 above, then:
RP_ARN=$(aws backup describe-backup-job --region "$SRC_R" --backup-job-id "$JOB" \
  --query RecoveryPointArn --output text)
echo "$RP_ARN"
```

### 9. Cross-Region copy (Lab 3 Step 6)

```bash
aws backup start-copy-job --region "$SRC_R" \
  --recovery-point-arn "$RP_ARN" \
  --source-backup-vault-name day7-lab-vault \
  --destination-backup-vault-arn "arn:aws:backup:${DR_R}:${ACCOUNT_ID}:backup-vault:day7-lab-dr-vault" \
  --iam-role-arn "$ROLE_ARN" \
  --lifecycle DeleteAfterDays=1
```

### 10. Teardown

Run [`scripts/day7-teardown.sh`](scripts/day7-teardown.sh) with `LAB_DATE` set to the day you ran the lab, then delete the local `backup-trust.json`, `plan.json` and `selection.json`.
