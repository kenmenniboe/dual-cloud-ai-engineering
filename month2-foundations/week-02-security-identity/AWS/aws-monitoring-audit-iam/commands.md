# Commands: Monitoring, Audit, IAM Advanced and Organizations

Every command from the Day 3 labs, grouped by lab and workflow stage. The labs were done in the console; blocks marked **CLI equivalent** reproduce the console steps for a CLI-only redo.

> [!NOTE]
> Run in **AWS CloudShell, us-east-1**. CloudShell behaves like zsh: avoid `!` inside double quotes, and loop over lists with `echo "$VAR" | tr '\t' '\n' | while read -r X; do ...; done`.

## Contents

- [Setup](#setup)
- [Lab 1 Metric filter alarm SNS](#lab-1-metric-filter-alarm-sns)
- [Lab 2 CloudTrail EventBridge SNS](#lab-2-cloudtrail-eventbridge-sns)
- [Lab 3 Config restricted-ssh remediation](#lab-3-config-restricted-ssh-remediation)
- [Lab 4 Permission boundary](#lab-4-permission-boundary)
- [Useful extras](#useful-extras)
- [Teardown](#teardown)

## Setup

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
echo $ACCOUNT_ID $REGION
```

## Lab 1 Metric filter alarm SNS

### SNS topic and email subscription (CLI equivalent)

```bash
TOPIC_ARN=$(aws sns create-topic --name menniboe-alerts --attributes DisplayName="Menniboe Alerts" --tags Key=Project,Value=day3-lab --query TopicArn --output text)
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint you@example.com
aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --query 'Subscriptions[].[Endpoint,SubscriptionArn]' --output table
```

### Log group and metric filter (CLI equivalent)

```bash
aws logs create-log-group --log-group-name /menniboe/orders-api --log-group-class STANDARD --tags Project=day3-lab
aws logs put-retention-policy --log-group-name /menniboe/orders-api --retention-in-days 1
aws logs put-metric-filter \
  --log-group-name /menniboe/orders-api \
  --filter-name PaymentFailuresFilter \
  --filter-pattern '"payment failed"' \
  --metric-transformations metricName=PaymentFailures,metricNamespace=MenniboeFarm/Orders,metricValue=1,defaultValue=0,unit=Count
aws logs test-metric-filter --filter-pattern '"payment failed"' --log-event-messages "INFO order 1001 placed" "ERROR payment failed order 1002" "ERROR payment failed order 1003"
```

### CloudWatch alarm (CLI equivalent)

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name Menniboe-PaymentFailures-High \
  --alarm-description "3 or more payment failures in 1 minute on /menniboe/orders-api" \
  --namespace MenniboeFarm/Orders --metric-name PaymentFailures \
  --statistic Sum --period 60 --evaluation-periods 1 --datapoints-to-alarm 1 \
  --threshold 3 --comparison-operator GreaterThanOrEqualToThreshold \
  --treat-missing-data notBreaching \
  --alarm-actions $TOPIC_ARN --ok-actions $TOPIC_ARN \
  --tags Key=Project,Value=day3-lab
```

### Send test log events (used in the lab)

```bash
aws logs create-log-stream --log-group-name /menniboe/orders-api --log-stream-name orders-api-test
NOW=$(date +%s%3N)
cat > events.json <<EOF
[
  {"timestamp": $NOW,           "message": "INFO order 2000 placed"},
  {"timestamp": $((NOW+1000)),  "message": "ERROR payment failed order 2001"},
  {"timestamp": $((NOW+2000)),  "message": "ERROR payment failed order 2002"},
  {"timestamp": $((NOW+3000)),  "message": "ERROR payment failed order 2003"}
]
EOF
cat events.json
aws logs put-log-events --log-group-name /menniboe/orders-api --log-stream-name orders-api-test --log-events file://events.json
```

### Verify

```bash
aws cloudwatch describe-alarms --alarm-names Menniboe-PaymentFailures-High --query 'MetricAlarms[].[AlarmName,StateValue,StateReason]' --output table
aws cloudwatch describe-alarm-history --alarm-name Menniboe-PaymentFailures-High --history-item-type StateUpdate --query 'AlarmHistoryItems[].[Timestamp,HistorySummary]' --output table
aws cloudwatch get-metric-statistics --namespace MenniboeFarm/Orders --metric-name PaymentFailures --statistics Sum --period 60 --start-time $(date -u -d '-30 min' +%Y-%m-%dT%H:%M:%SZ) --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ)
aws logs filter-log-events --log-group-name /menniboe/orders-api --filter-pattern '"payment failed"' --query 'events[].message'
aws cloudwatch set-alarm-state --alarm-name Menniboe-PaymentFailures-High --state-value ALARM --state-reason "manual test"
```

## Lab 2 CloudTrail EventBridge SNS

### Trail with a new S3 bucket (CLI equivalent)

```bash
TRAIL_BUCKET=day3-lab-aws-cloudtrail-logs-klm
aws s3api create-bucket --bucket $TRAIL_BUCKET
cat > trail-bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "AWSCloudTrailAclCheck", "Effect": "Allow", "Principal": {"Service": "cloudtrail.amazonaws.com"},
     "Action": "s3:GetBucketAcl", "Resource": "arn:aws:s3:::$TRAIL_BUCKET"},
    {"Sid": "AWSCloudTrailWrite", "Effect": "Allow", "Principal": {"Service": "cloudtrail.amazonaws.com"},
     "Action": "s3:PutObject", "Resource": "arn:aws:s3:::$TRAIL_BUCKET/AWSLogs/$ACCOUNT_ID/*",
     "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}}
  ]
}
EOF
aws s3api put-bucket-policy --bucket $TRAIL_BUCKET --policy file://trail-bucket-policy.json
aws cloudtrail create-trail --name menniboe-audit-trail --s3-bucket-name $TRAIL_BUCKET --is-multi-region-trail --enable-log-file-validation --tags-list Key=Project,Value=day3-lab
aws cloudtrail put-event-selectors --trail-name menniboe-audit-trail --event-selectors '[{"ReadWriteType":"WriteOnly","IncludeManagementEvents":true}]'
aws cloudtrail start-logging --name menniboe-audit-trail
aws cloudtrail get-trail-status --name menniboe-audit-trail --query '[IsLogging,LatestDeliveryTime]'
```

### EventBridge rule and SNS target (CLI equivalent)

```bash
cat > sg-ingress-pattern.json <<'EOF'
{
  "source": ["aws.ec2"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["ec2.amazonaws.com"],
    "eventName": ["AuthorizeSecurityGroupIngress", "ModifySecurityGroupRules"]
  }
}
EOF
aws events put-rule --name menniboe-sg-ingress-alert --event-bus-name default --event-pattern file://sg-ingress-pattern.json --description "Email when any security group inbound rule is added or modified" --state ENABLED
cat > sns-allow-events.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "AllowOwner", "Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::$ACCOUNT_ID:root"}, "Action": "SNS:*", "Resource": "$TOPIC_ARN"},
    {"Sid": "AllowEventBridgePublish", "Effect": "Allow", "Principal": {"Service": "events.amazonaws.com"}, "Action": "sns:Publish", "Resource": "$TOPIC_ARN"}
  ]
}
EOF
aws sns set-topic-attributes --topic-arn $TOPIC_ARN --attribute-name Policy --attribute-value file://sns-allow-events.json
aws events put-targets --rule menniboe-sg-ingress-alert --targets Id=sns-target,Arn=$TOPIC_ARN
```

> [!NOTE]
> The CLI version uses the classic **resource-based policy** on the topic. The console lab used the wizard's default **execution role** (`Amazon_EventBridge_Invoke_Sns_...`). The pattern above already includes `ModifySecurityGroupRules`, closing the gap found in the lab.

### Test security group and trigger (CLI equivalent)

```bash
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
SG_ID=$(aws ec2 create-security-group --group-name menniboe-lab-sg --description "Day 3 lab test SG - safe to delete" --vpc-id $VPC_ID --tag-specifications 'ResourceType=security-group,Tags=[{Key=Project,Value=day3-lab}]' --query GroupId --output text)
echo $SG_ID
aws ec2 authorize-security-group-ingress --group-id $SG_ID --ip-permissions 'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0,Description="Lab trigger - remove after test"}]'
```

### Verify in CloudTrail

```bash
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=AuthorizeSecurityGroupIngress --max-results 5 --query 'Events[].[EventTime,Username,EventName]' --output table
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=$SG_ID --query 'Events[].[EventTime,Username,EventName]' --output table
aws events list-targets-by-rule --rule menniboe-sg-ingress-alert
```

## Lab 3 Config restricted-ssh remediation

### Recorder, delivery channel and rule (CLI equivalent)

```bash
CONFIG_BUCKET=config-bucket-day3-lab-klm
aws iam create-service-linked-role --aws-service-name config.amazonaws.com
aws s3api create-bucket --bucket $CONFIG_BUCKET
cat > config-bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "AWSConfigBucketPermissionsCheck", "Effect": "Allow", "Principal": {"Service": "config.amazonaws.com"},
     "Action": ["s3:GetBucketAcl", "s3:ListBucket"], "Resource": "arn:aws:s3:::$CONFIG_BUCKET"},
    {"Sid": "AWSConfigBucketDelivery", "Effect": "Allow", "Principal": {"Service": "config.amazonaws.com"},
     "Action": "s3:PutObject", "Resource": "arn:aws:s3:::$CONFIG_BUCKET/AWSLogs/$ACCOUNT_ID/Config/*",
     "Condition": {"StringEquals": {"s3:x-amz-acl": "bucket-owner-full-control"}}}
  ]
}
EOF
aws s3api put-bucket-policy --bucket $CONFIG_BUCKET --policy file://config-bucket-policy.json
aws configservice put-configuration-recorder \
  --configuration-recorder name=default,roleARN=arn:aws:iam::$ACCOUNT_ID:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig \
  --recording-group allSupported=false,includeGlobalResourceTypes=false,resourceTypes=AWS::EC2::SecurityGroup
aws configservice put-delivery-channel --delivery-channel name=default,s3BucketName=$CONFIG_BUCKET
aws configservice start-configuration-recorder --configuration-recorder-name default
aws configservice put-config-rule --config-rule '{"ConfigRuleName":"restricted-ssh","Source":{"Owner":"AWS","SourceIdentifier":"INCOMING_SSH_DISABLED"},"Scope":{"ComplianceResourceTypes":["AWS::EC2::SecurityGroup"]}}'
```

> [!NOTE]
> The console name `restricted-ssh` maps to the managed rule identifier `INCOMING_SSH_DISABLED`.

### Investigate (used in the lab via the console timeline)

```bash
aws configservice describe-compliance-by-config-rule --config-rule-names restricted-ssh
aws configservice get-compliance-details-by-config-rule --config-rule-name restricted-ssh --query 'EvaluationResults[].[EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,ComplianceType]' --output table
aws configservice get-resource-config-history --resource-type AWS::EC2::SecurityGroup --resource-id $SG_ID --limit 5 --query 'configurationItems[].[configurationItemCaptureTime,configurationItemStatus]' --output table
```

### Remediation role (CLI equivalent)

```bash
cat > ssm-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{"Effect": "Allow", "Principal": {"Service": "ssm.amazonaws.com"}, "Action": "sts:AssumeRole"}]
}
EOF
cat > revoke-sg-policy.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid": "AllowRevokeOpenSecurityGroupRules", "Effect": "Allow",
     "Action": ["ec2:DescribeSecurityGroups", "ec2:RevokeSecurityGroupIngress"], "Resource": "*"}
  ]
}
EOF
aws iam create-role --role-name day3-lab-config-role --assume-role-policy-document file://ssm-trust.json --description "SSM Automation role for Config remediation - revokes open SG rules (Day 3 lab)"
aws iam put-role-policy --role-name day3-lab-config-role --policy-name day3-lab-config-rolePolicy --policy-document file://revoke-sg-policy.json
```

### Automatic remediation (CLI equivalent)

```bash
cat > remediation.json <<EOF
[
  {
    "ConfigRuleName": "restricted-ssh",
    "TargetType": "SSM_DOCUMENT",
    "TargetId": "AWS-DisablePublicAccessForSecurityGroup",
    "Parameters": {
      "GroupId": {"ResourceValue": {"Value": "RESOURCE_ID"}},
      "AutomationAssumeRole": {"StaticValue": {"Values": ["arn:aws:iam::$ACCOUNT_ID:role/day3-lab-config-role"]}}
    },
    "Automatic": true,
    "MaximumAutomaticAttempts": 5,
    "RetryAttemptSeconds": 60,
    "ExecutionControls": {"SsmControls": {"ConcurrentExecutionRatePercentage": 2, "ErrorPercentage": 5}}
  }
]
EOF
aws configservice put-remediation-configurations --remediation-configurations file://remediation.json
aws configservice start-config-rules-evaluation --config-rule-names restricted-ssh
```

### Verify

```bash
aws configservice describe-remediation-execution-status --config-rule-name restricted-ssh
aws ec2 describe-security-groups --group-ids $SG_ID --query 'SecurityGroups[0].IpPermissions'
aws configservice get-compliance-details-by-config-rule --config-rule-name restricted-ssh --query 'EvaluationResults[].[EvaluationResultIdentifier.EvaluationResultQualifier.ResourceId,ComplianceType]' --output table
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=RevokeSecurityGroupIngress --max-results 5 --query 'Events[].[EventTime,Username]' --output table
```

## Lab 4 Permission boundary

### Boundary policy and capped role (CLI equivalent)

```bash
cat > dev-boundary.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DevBoundaryReadOnlyS3AndCloudWatch",
      "Effect": "Allow",
      "Action": ["s3:ListAllMyBuckets", "s3:GetBucketLocation", "s3:ListBucket", "s3:GetObject",
                 "cloudwatch:Get*", "cloudwatch:List*", "cloudwatch:Describe*"],
      "Resource": "*"
    }
  ]
}
EOF
aws iam create-policy --policy-name menniboe-dev-boundary --policy-document file://dev-boundary.json --description "Permission boundary - caps any identity to S3 and CloudWatch read (Day 3 lab)"
cat > account-trust.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{"Effect": "Allow", "Principal": {"AWS": "arn:aws:iam::$ACCOUNT_ID:root"}, "Action": "sts:AssumeRole"}]
}
EOF
aws iam create-role --role-name menniboe-dev-test-role --assume-role-policy-document file://account-trust.json --permissions-boundary arn:aws:iam::$ACCOUNT_ID:policy/menniboe-dev-boundary --description "Test role - AdministratorAccess capped by menniboe-dev-boundary (Day 3 lab)"
aws iam attach-role-policy --role-name menniboe-dev-test-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam get-role --role-name menniboe-dev-test-role --query 'Role.PermissionsBoundary'
```

Add a boundary to an existing role (the fix used in the lab):

```bash
aws iam put-role-permissions-boundary --role-name menniboe-dev-test-role --permissions-boundary arn:aws:iam::$ACCOUNT_ID:policy/menniboe-dev-boundary
```

### Policy Simulator (CLI equivalent)

```bash
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::$ACCOUNT_ID:role/menniboe-dev-test-role \
  --action-names s3:ListAllMyBuckets iam:CreateUser ec2:RunInstances \
  --query 'EvaluationResults[].[EvalActionName,EvalDecision]' --output table
```

### Assume the role and test live (CLI equivalent of Switch Role)

```bash
CREDS=$(aws sts assume-role --role-arn arn:aws:iam::$ACCOUNT_ID:role/menniboe-dev-test-role --role-session-name dev-capped-test --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' --output text)
export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | cut -f1)
export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | cut -f2)
export AWS_SESSION_TOKEN=$(echo "$CREDS" | cut -f3)
aws sts get-caller-identity
aws s3 ls
aws iam list-roles --max-items 1
aws ec2 describe-instances --max-items 1
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
aws sts get-caller-identity
```

Expected: `s3 ls` succeeds; `iam list-roles` and `ec2 describe-instances` return `AccessDenied`; the final `get-caller-identity` shows your normal user again.

## Useful extras

```bash
aws logs describe-log-groups --log-group-name-prefix /menniboe
aws logs start-query --log-group-name /menniboe/orders-api --start-time $(date -d '-1 hour' +%s) --end-time $(date +%s) --query-string 'fields @timestamp, @message | filter @message like /payment failed/ | sort @timestamp desc'
aws events list-rules --event-bus-name default
aws configservice describe-configuration-recorder-status
aws iam list-entities-for-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/menniboe-dev-boundary --entity-filter Role --policy-usage-filter PermissionsBoundary
```

## Teardown

Run as your normal user, one block at a time. `NoSuchEntity` / `NotFound` means it was already deleted.

### T1 Lab 4 role and boundary policy

```bash
aws iam detach-role-policy --role-name menniboe-dev-test-role --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
aws iam delete-role-permissions-boundary --role-name menniboe-dev-test-role
aws iam delete-role --role-name menniboe-dev-test-role
aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/menniboe-dev-boundary
```

### T2 Lab 3 Config rule, recorder, bucket, remediation role

```bash
aws configservice delete-remediation-configuration --config-rule-name restricted-ssh
aws configservice delete-config-rule --config-rule-name restricted-ssh
REC=$(aws configservice describe-configuration-recorders --query 'ConfigurationRecorders[0].name' --output text)
CH=$(aws configservice describe-delivery-channels --query 'DeliveryChannels[0].name' --output text)
echo "$REC / $CH"
aws configservice stop-configuration-recorder --configuration-recorder-name "$REC"
aws configservice delete-delivery-channel --delivery-channel-name "$CH"
aws configservice delete-configuration-recorder --configuration-recorder-name "$REC"
aws s3 rb s3://config-bucket-day3-lab-klm --force
aws iam delete-role-policy --role-name day3-lab-config-role --policy-name day3-lab-config-rolePolicy
aws iam delete-role --role-name day3-lab-config-role
```

Optional (only after the recorder is gone):

```bash
aws iam delete-service-linked-role --role-name AWSServiceRoleForConfig
```

### T3 Test security group

```bash
aws ec2 delete-security-group --group-id sg-0bc73272616bb7e98
```

### T4 Lab 2 rule, role, trail, bucket

```bash
TID=$(aws events list-targets-by-rule --rule menniboe-sg-ingress-alert --query 'Targets[].Id' --output text)
aws events remove-targets --rule menniboe-sg-ingress-alert --ids $TID
aws events delete-rule --name menniboe-sg-ingress-alert
EBROLE=Amazon_EventBridge_Invoke_Sns_1650777938
ARNS=$(aws iam list-attached-role-policies --role-name $EBROLE --query 'AttachedPolicies[].PolicyArn' --output text)
echo "$ARNS" | tr '\t' '\n' | while read -r P; do [ -n "$P" ] && aws iam detach-role-policy --role-name $EBROLE --policy-arn "$P" && aws iam delete-policy --policy-arn "$P"; done
INL=$(aws iam list-role-policies --role-name $EBROLE --query 'PolicyNames' --output text)
echo "$INL" | tr '\t' '\n' | while read -r N; do [ -n "$N" ] && aws iam delete-role-policy --role-name $EBROLE --policy-name "$N"; done
aws iam delete-role --role-name $EBROLE
aws cloudtrail delete-trail --name menniboe-audit-trail
aws s3 rb s3://day3-lab-aws-cloudtrail-logs-klm --force
```

### T5 Lab 1 alarm, log group, SNS topic

```bash
aws cloudwatch delete-alarms --alarm-names Menniboe-PaymentFailures-High
aws logs delete-log-group --log-group-name /menniboe/orders-api
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:$ACCOUNT_ID:menniboe-alerts
rm -f events.json
```

### T6 Verify

```bash
aws iam list-roles --query "Roles[?contains(RoleName,'menniboe') || contains(RoleName,'day3') || contains(RoleName,'EventBridge_Invoke_Sns')].RoleName"
aws iam list-policies --scope Local --query "Policies[?contains(PolicyName,'menniboe') || contains(PolicyName,'EventBridge_Invoke_Sns')].PolicyName"
aws configservice describe-config-rules --query 'ConfigRules[].ConfigRuleName'
aws configservice describe-configuration-recorders --query 'ConfigurationRecorders[].name'
aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='menniboe-lab-sg'].GroupId"
aws events list-rules --query "Rules[?Name=='menniboe-sg-ingress-alert'].Name"
aws cloudtrail describe-trails --query 'trailList[].Name'
aws cloudwatch describe-alarms --alarm-names Menniboe-PaymentFailures-High --query 'MetricAlarms[].AlarmName'
aws logs describe-log-groups --log-group-name-prefix /menniboe --query 'logGroups[].logGroupName'
aws sns list-topics --query "Topics[?contains(TopicArn,'menniboe-alerts')]"
aws s3 ls
```

Expected: `[]` for every check; `aws s3 ls` shows only buckets that are meant to stay.
