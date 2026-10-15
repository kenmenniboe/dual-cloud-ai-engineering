# Commands: ECS on Fargate and EC2 (Menniboe Farm)

Every command from the session, copy-paste ready. Shell: **zsh on macOS (Apple Silicon)**.

> [!WARNING]
> **zsh gotchas we hit:**
> - zsh does **not** word-split `$VAR`. Use `${=VAR}` when a variable holds several IDs.
> - Quote `'[]'`, or zsh treats it as a glob pattern.
> - Paste multi-line commands carefully. A split quote leaves you at a `quote>` prompt; press Ctrl+C and paste the command again.

## Contents
1. [Environment setup](#1-environment-setup)
2. [App files](#2-app-files)
3. [Docker build and local test](#3-docker-build-and-local-test)
4. [ECR: repo, push, scan](#4-ecr-repo-push-scan)
5. [Networking: security groups](#5-networking-security-groups)
6. [Target group and ALB](#6-target-group-and-alb)
7. [Verification and load testing](#7-verification-and-load-testing)
8. [Alerts: SNS topic](#8-alerts-sns-topic)
9. [Phase 2 lookups (EC2)](#9-phase-2-lookups-ec2)
10. [Teardown](#10-teardown)

---

## 1. Environment setup
```bash
docker version --format '{{.Server.Version}}'
aws --version
aws sts get-caller-identity

mkdir -p ~/labs/menniboe-farm && cd ~/labs/menniboe-farm

export AWS_REGION=us-east-1
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export REPO=menniboe-farm
export ECR_URI=$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
export CLUSTER=DemoCluster
```

## 2. App files
```bash
cat > default.conf <<'EOF'
server {
    listen 80;
    location /health { default_type text/plain; return 200 'ok'; }
    location / {
        default_type text/html;
        return 200 '<html><body style="font-family:sans-serif;text-align:center;margin-top:60px">
<h1>Menniboe Farm</h1>
<p>Served by container: <b>$hostname</b></p>
<p>Container IP: <b>$server_addr</b></p>
<p>Image: menniboe-farm:1.0</p>
</body></html>';
    }
}
EOF

# v1.0 Dockerfile (later remediated, see below)
cat > Dockerfile <<'EOF'
FROM nginx:1.27-alpine
COPY default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOF
```

**v1.1 (CVE remediation):**
```bash
cat > Dockerfile <<'EOF'
FROM nginx:1.30.5-alpine
RUN apk upgrade --no-cache
COPY default.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
EOF
sed -i '' 's/menniboe-farm:1.0/menniboe-farm:1.1/' default.conf   # macOS sed
```

## 3. Docker build and local test
```bash
# Build for AWS (x86_64), not Apple Silicon arm64
docker build --platform linux/amd64 -t $REPO:1.0 -t $ECR_URI/$REPO:1.0 .
docker images $REPO
docker image inspect $REPO:1.0 --format '{{.Os}}/{{.Architecture}}'   # expect linux/amd64

# Run locally (sleep avoids the curl race condition)
docker run -d --platform linux/amd64 -p 8080:80 --name farm $REPO:1.0
sleep 3
curl -s localhost:8080/health; echo
curl -s localhost:8080 | grep -E "Menniboe|container|IP"
docker rm -f farm

# Check which nginx version a tag really ships
docker pull nginx:stable-alpine
docker run --rm nginx:stable-alpine nginx -v

# v1.1 build + test in one go
docker build --platform linux/amd64 -t $REPO:1.1 -t $ECR_URI/$REPO:1.1 .
docker image inspect $REPO:1.1 --format '{{.Os}}/{{.Architecture}}'
docker run -d --platform linux/amd64 -p 8080:80 --name farm $REPO:1.1
sleep 3
curl -s localhost:8080/health; echo
curl -s localhost:8080 | grep "Image:"
docker rm -f farm
```

## 4. ECR: repo, push, scan
```bash
aws ecr create-repository \
  --repository-name $REPO \
  --region $AWS_REGION \
  --image-scanning-configuration scanOnPush=true \
  --query 'repository.[repositoryName,repositoryUri,imageScanningConfiguration.scanOnPush]' \
  --output table

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

docker push $ECR_URI/$REPO:1.0
docker push $ECR_URI/$REPO:1.1

# Scan results (severity counts)
aws ecr wait image-scan-complete --repository-name $REPO --image-id imageTag=1.1
aws ecr describe-image-scan-findings --repository-name $REPO --image-id imageTag=1.0 \
  --query 'imageScanFindings.findingSeverityCounts'
aws ecr describe-image-scan-findings --repository-name $REPO --image-id imageTag=1.1 \
  --query 'imageScanFindings.findingSeverityCounts'

aws ecr describe-images --repository-name $REPO \
  --query 'imageDetails[].{tags:imageTags[0],pushed:imagePushedAt}' --output table
```

## 5. Networking: security groups
```bash
export VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
export SUBNETS=$(aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$VPC_ID Name=availability-zone,Values=us-east-1a,us-east-1b,us-east-1c \
  --query 'Subnets[].SubnetId' --output text)
echo $VPC_ID; echo $SUBNETS

# ALB SG: HTTP from anywhere
export ALB_SG=$(aws ec2 create-security-group --group-name farm-alb-sg \
  --description "Menniboe farm ALB" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0

# Task SG: HTTP only from the ALB SG (SG-to-SG trust)
export TASK_SG=$(aws ec2 create-security-group --group-name farm-task-sg \
  --description "Menniboe farm tasks" --vpc-id $VPC_ID --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $TASK_SG --protocol tcp --port 80 --source-group $ALB_SG
```

## 6. Target group and ALB
```bash
export TG_ARN=$(aws elbv2 create-target-group --name farm-tg \
  --protocol HTTP --port 80 --vpc-id $VPC_ID --target-type ip \
  --health-check-path /health --matcher HttpCode=200 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

aws elbv2 modify-target-group-attributes --target-group-arn $TG_ARN \
  --attributes Key=deregistration_delay.timeout_seconds,Value=30

# NOTE: ${=SUBNETS}, because zsh won't split plain $SUBNETS (InvalidSubnet error)
export ALB_ARN=$(aws elbv2 create-load-balancer --name farm-alb \
  --type application --scheme internet-facing \
  --subnets ${=SUBNETS} --security-groups $ALB_SG \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN

aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

export ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)
echo http://$ALB_DNS
```

## 7. Verification and load testing
```bash
# Target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN \
  --query 'TargetHealthDescriptions[].{ip:Target.Id,az:Target.AvailabilityZone,state:TargetHealth.State,reason:TargetHealth.Reason}' \
  --output table

# Round-robin check
for i in {1..6}; do curl -s http://$ALB_DNS | grep -o 'Container IP: <b>[0-9.]*'; done

# Load test (6 minutes, 10 concurrent) to trigger target tracking scale-out
ab -t 360 -n 1000000 -c 10 http://$ALB_DNS/
```

## 8. Alerts: SNS topic
```bash
export TOPIC_ARN=$(aws sns create-topic --name farm-task-alerts --query TopicArn --output text)
aws sns subscribe --topic-arn $TOPIC_ARN --protocol email --notification-endpoint <your-email>
# Confirm from the email (do NOT click "unsubscribe" in alert emails)
aws sns list-subscriptions-by-topic --topic-arn $TOPIC_ARN --query 'Subscriptions[].{ep:Endpoint,arn:SubscriptionArn}' --output table
```

## 9. Phase 2 lookups (EC2)
```bash
# ECS-optimized AL2023 AMI ID for the launch template
aws ssm get-parameter \
  --name /aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id \
  --query 'Parameter.Value' --output text
```
Launch template user data:
```bash
#!/bin/bash
echo ECS_CLUSTER=DemoCluster >> /etc/ecs/ecs.config
```

## 10. Teardown
Order: services → capacity provider → ASG → launch template → cluster → ALB → target group → SGs → EventBridge/SNS → ECR → logs → IAM → local.

```bash
export AWS_REGION=us-east-1
export CLUSTER=DemoCluster
```

**T1: EC2 service**
```bash
aws ecs delete-service --cluster $CLUSTER --service farm-svc-ec2 --force \
  --query 'service.{name:serviceName,status:status,desired:desiredCount}' --output table
aws ecs wait services-inactive --cluster $CLUSTER --services farm-svc-ec2 && echo "farm-svc-ec2 INACTIVE"
aws ecs list-services --cluster $CLUSTER --output table
```

**T2: Fargate service and its auto scaling**
```bash
aws application-autoscaling describe-scalable-targets --service-namespace ecs \
  --query 'ScalableTargets[].{id:ResourceId,min:MinCapacity,max:MaxCapacity}' --output table
aws application-autoscaling deregister-scalable-target --service-namespace ecs \
  --resource-id service/$CLUSTER/farm-svc --scalable-dimension ecs:service:DesiredCount
aws ecs delete-service --cluster $CLUSTER --service farm-svc --force --query 'service.status'
aws ecs wait services-inactive --cluster $CLUSTER --services farm-svc && echo "farm-svc INACTIVE"
aws ecs list-services --cluster $CLUSTER --output table
aws cloudwatch describe-alarms --alarm-name-prefix "TargetTracking-service/$CLUSTER" \
  --query 'MetricAlarms[].AlarmName' --output table
```

**T3: Capacity provider**
```bash
aws ecs put-cluster-capacity-providers --cluster $CLUSTER \
  --capacity-providers '[]' --default-capacity-provider-strategy '[]' \
  --query 'cluster.capacityProviders'
aws ecs delete-capacity-provider --capacity-provider farm-ecs-cp \
  --query 'capacityProvider.{name:name,status:status,update:updateStatus}' --output table
aws ecs describe-capacity-providers --capacity-providers farm-ecs-cp \
  --query 'capacityProviders[].{name:name,status:status,update:updateStatus}' --output table
```

**T4: ASG and instances**
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names farm-ecs-asg \
  --query 'AutoScalingGroups[].{desired:DesiredCapacity,min:MinSize,max:MaxSize,instances:length(Instances)}' --output table
IDS=$(aws ec2 describe-instances \
  --filters Name=tag:aws:autoscaling:groupName,Values=farm-ecs-asg \
            Name=instance-state-name,Values=pending,running,stopping,shutting-down \
  --query 'Reservations[].Instances[].InstanceId' --output text)
echo $IDS
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name farm-ecs-asg --force-delete
aws ec2 wait instance-terminated --instance-ids ${=IDS} && echo "All farm-ecs-asg instances TERMINATED"
```

**T5: Launch template and cluster**
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names farm-ecs-asg \
  --query 'AutoScalingGroups[].{name:AutoScalingGroupName,status:Status}' --output table
aws ec2 delete-launch-template --launch-template-name farm-ecs-lt \
  --query 'LaunchTemplate.{name:LaunchTemplateName,id:LaunchTemplateId}' --output table
aws ecs list-container-instances --cluster $CLUSTER --output table
aws ecs delete-cluster --cluster $CLUSTER --query 'cluster.{name:clusterName,status:status}' --output table
```

**T6: ALB, listener and target group**
```bash
ALB_ARN=$(aws elbv2 describe-load-balancers --names farm-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text)
TG_ARN=$(aws elbv2 describe-target-groups --names farm-tg --query 'TargetGroups[0].TargetGroupArn' --output text)
echo $ALB_ARN; echo $TG_ARN
aws elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
aws elbv2 wait load-balancers-deleted --load-balancer-arns $ALB_ARN && echo "farm-alb DELETED"
aws elbv2 delete-target-group --target-group-arn $TG_ARN && echo "farm-tg DELETED"
```

**T7: Security groups (task SG first, because it references the ALB SG)**
```bash
TASK_SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=farm-task-sg --query 'SecurityGroups[0].GroupId' --output text)
ALB_SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=farm-alb-sg --query 'SecurityGroups[0].GroupId' --output text)
echo "task=$TASK_SG  alb=$ALB_SG"
aws ec2 describe-network-interfaces --filters Name=group-id,Values=$TASK_SG,$ALB_SG \
  --query 'NetworkInterfaces[].{id:NetworkInterfaceId,status:Status,desc:Description}' --output table
aws ec2 delete-security-group --group-id $TASK_SG && echo "farm-task-sg DELETED"
aws ec2 delete-security-group --group-id $ALB_SG && echo "farm-alb-sg DELETED"
```

**T8: EventBridge rule and SNS topic**
```bash
TARGET_IDS=$(aws events list-targets-by-rule --rule farm-task-stopped --query 'Targets[].Id' --output text)
echo "targets: $TARGET_IDS"
aws events remove-targets --rule farm-task-stopped --ids ${=TARGET_IDS}
aws events delete-rule --name farm-task-stopped && echo "farm-task-stopped rule DELETED"
TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn,'farm')].TopicArn" --output text)
echo $TOPIC_ARN
aws sns delete-topic --topic-arn $TOPIC_ARN && echo "SNS topic DELETED"
```

**T9: ECR and logs**
```bash
aws events describe-rule --name farm-task-stopped 2>&1 | grep -o 'ResourceNotFoundException' || echo "rule still exists"
aws ecr delete-repository --repository-name menniboe-farm --force \
  --query 'repository.repositoryName' --output text && echo "ECR repo DELETED"
aws logs describe-log-groups --log-group-name-prefix /ecs --query 'logGroups[].logGroupName' --output table
aws logs delete-log-group --log-group-name /ecs/menniboe-farm && echo "Log group DELETED"
# optional: other labs' log groups
aws logs put-retention-policy --log-group-name /ecs/sonarqube-task --retention-in-days 7
```

**T10: ecsInstanceRole**
```bash
ROLE=ecsInstanceRole
aws iam list-instance-profiles-for-role --role-name $ROLE --query 'InstanceProfiles[].InstanceProfileName' --output text
POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE --query 'AttachedPolicies[].PolicyArn' --output text)
echo "managed: $POLICIES"
aws iam list-role-policies --role-name $ROLE --query 'PolicyNames' --output text
aws iam remove-role-from-instance-profile --instance-profile-name $ROLE --role-name $ROLE
aws iam delete-instance-profile --instance-profile-name $ROLE && echo "Instance profile DELETED"
for p in ${=POLICIES}; do aws iam detach-role-policy --role-name $ROLE --policy-arn $p && echo "detached $p"; done
aws iam delete-role --role-name $ROLE && echo "ecsInstanceRole DELETED"
```

**T11: EventBridge → SNS role and its customer-managed policy**
```bash
ROLE=Amazon_EventBridge_Invoke_Sns_1331989812
POLICIES=$(aws iam list-attached-role-policies --role-name $ROLE --query 'AttachedPolicies[].PolicyArn' --output text)
echo "managed: $POLICIES"
aws iam list-role-policies --role-name $ROLE --query 'PolicyNames' --output text
for p in ${=POLICIES}; do aws iam detach-role-policy --role-name $ROLE --policy-arn $p && echo "detached $p"; done
aws iam delete-role --role-name $ROLE && echo "EventBridge role DELETED"
for p in ${=POLICIES}; do
  [[ $p == arn:aws:iam::aws:* ]] && echo "skip AWS-managed $p" && continue
  aws iam delete-policy --policy-arn $p && echo "deleted policy $p"
done
```

**T12: Final sweep (every line should print nothing)**
```bash
echo "--- ECS clusters (ACTIVE)";  aws ecs describe-clusters --clusters DemoCluster --query 'clusters[?status==`ACTIVE`].clusterName' --output text
echo "--- Load balancers";        aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(LoadBalancerName,'farm')].LoadBalancerName" --output text
echo "--- Target groups";         aws elbv2 describe-target-groups --query "TargetGroups[?contains(TargetGroupName,'farm')].TargetGroupName" --output text
echo "--- Running instances";     aws ec2 describe-instances --filters Name=tag:Project,Values=menniboe-farm-lab Name=instance-state-name,Values=pending,running,stopped --query 'Reservations[].Instances[].InstanceId' --output text
echo "--- ASGs";                  aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName,'farm')].AutoScalingGroupName" --output text
echo "--- Security groups";       aws ec2 describe-security-groups --query "SecurityGroups[?starts_with(GroupName,'farm')].GroupName" --output text
echo "--- ECR repos";             aws ecr describe-repositories --query "repositories[?contains(repositoryName,'farm')].repositoryName" --output text
echo "--- EventBridge rules";     aws events list-rules --name-prefix farm --query 'Rules[].Name' --output text
echo "--- Unattached EIPs";       aws ec2 describe-addresses --query 'Addresses[?AssociationId==`null`].PublicIp' --output text
echo "--- IAM roles";             aws iam list-roles --query "Roles[?contains(RoleName,'ecsInstanceRole') || contains(RoleName,'EventBridge_Invoke_Sns')].RoleName" --output text
```

**T13: Local Docker cleanup**
```bash
docker ps -a --filter ancestor=menniboe-farm --format 'table {{.ID}}\t{{.Image}}\t{{.Status}}'
docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'menniboe-farm|nginx'
docker images --format '{{.Repository}}:{{.Tag}}' | grep -E 'menniboe-farm|^nginx:' | xargs docker rmi -f
docker logout $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
docker image prune -f
docker images --format 'table {{.Repository}}\t{{.Tag}}' | grep -E 'menniboe-farm|nginx' || echo "No lab images left"
```
