#!/bin/bash
# Day 7 lab teardown: AWS Backup (us-east-1 + us-west-2), CloudFormation stack, leftovers.
# Run in CloudShell with:  bash day7-teardown.sh

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

echo "== T4: delete the CloudFormation stack (instance, SG, profile, role) =="
aws cloudformation delete-stack --region "$SRC_R" --stack-name "$STACK"
echo "  waiting for DELETE_COMPLETE (about 1-3 min)..."
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
      echo "  deleting inline policy $IP"
      aws iam delete-role-policy --role-name "$ROLE" --policy-name "$IP"
    done
    aws iam delete-role --role-name "$ROLE" && echo "  deleted $ROLE"
    ;;
  *) echo "  kept $ROLE (created $CREATED, before this lab)";;
esac

echo "== T7: verification sweep (every line should be empty or 'none') =="
echo "-- stack:"
aws cloudformation describe-stacks --region "$SRC_R" --stack-name "$STACK" \
  --query "Stacks[].StackStatus" --output text 2>&1 | sed 's/^/   /'
echo "-- lab instances not terminated:"
aws ec2 describe-instances --region "$SRC_R" \
  --filters "Name=tag:project,Values=day7-lab" "Name=instance-state-name,Values=pending,running,stopping,stopped" \
  --query "Reservations[].Instances[].InstanceId" --output text | sed 's/^/   /'
for R in "$SRC_R" "$DR_R"; do
  echo "-- $R backup vaults / plans / AMIs / snapshots:"
  aws backup list-backup-vaults --region "$R" \
    --query "BackupVaultList[?starts_with(BackupVaultName,'day7-lab')].BackupVaultName" --output text | sed 's/^/   vaults: /'
  aws backup list-backup-plans --region "$R" \
    --query "BackupPlansList[?starts_with(BackupPlanName,'day7-lab')].BackupPlanName" --output text | sed 's/^/   plans: /'
  aws ec2 describe-images --region "$R" --owners self --query "Images[].ImageId" --output text | sed 's/^/   AMIs: /'
  aws ec2 describe-snapshots --region "$R" --owner-ids self --query "Snapshots[].SnapshotId" --output text | sed 's/^/   snapshots: /'
done
echo "-- $ROLE:"
aws iam get-role --role-name "$ROLE" --query "Role.CreateDate" --output text 2>&1 | sed 's/^/   /'
echo "== teardown finished =="
