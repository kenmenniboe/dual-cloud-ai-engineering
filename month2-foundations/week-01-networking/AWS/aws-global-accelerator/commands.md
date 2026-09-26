# Commands — AWS Global Accelerator Lab

Every CLI command from the session, grouped by workflow stage. Copy-paste ready.

**Substitute these placeholders:**

```
<US_INSTANCE_ID>    e.g. i-0xxxxxxxxxxxxxxxx
<EU_INSTANCE_ID>    e.g. i-0xxxxxxxxxxxxxxxx
<ACCEL_IP_1>        first static anycast IP
<ACCEL_IP_2>        second static anycast IP
<ACCEL_DNS>         xxxxxxxxxxxxx.awsglobalaccelerator.com
<ACCOUNT_ID>        your 12-digit AWS account ID
```

> **Every Global Accelerator command needs `--region us-west-2`.**
> The service is global, but its control plane lives in Oregon. Omit it and you get an
> endpoint error.

---

## Table of Contents

- [0. Shell setup](#0-shell-setup)
- [1. EC2 user data scripts](#1-ec2-user-data-scripts)
- [2. Verify both instances serve](#2-verify-both-instances-serve)
- [3. Accelerator status and health](#3-accelerator-status-and-health)
- [4. Anycast routing test](#4-anycast-routing-test)
- [5. Failover test](#5-failover-test)
- [6. Failback test](#6-failback-test)
- [7. Teardown](#7-teardown)
- [8. Git](#8-git)

---

## 0. Shell setup

```bash
# zsh does not treat # as a comment interactively by default.
# Without this, pasting a comment line gives: zsh: unknown file attribute: h
setopt interactive_comments
echo 'setopt interactive_comments' >> ~/.zshrc
```

```bash
aws sts get-caller-identity
aws configure get region
```

---

## 1. EC2 user data scripts

Pasted into **Advanced details → User data** at launch. Not run from your shell.

**us-east-1:**

```bash
#!/bin/bash
dnf install -y httpd
systemctl enable --now httpd
echo "<h1>Hello World from $(hostname -f) in US-EAST-1</h1>" > /var/www/html/index.html
```

**eu-west-1:**

```bash
#!/bin/bash
dnf install -y httpd
systemctl enable --now httpd
echo "<h1>Hello World from $(hostname -f) in EU-WEST-1</h1>" > /var/www/html/index.html
```

---

## 2. Verify both instances serve

```bash
US_IP=$(aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=ga-demo-us-east-1" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PublicIpAddress" --output text)

EU_IP=$(aws ec2 describe-instances --region eu-west-1 \
  --filters "Name=tag:Name,Values=ga-demo-eu-west-1" "Name=instance-state-name,Values=running" \
  --query "Reservations[].Instances[].PublicIpAddress" --output text)

echo "US: $US_IP"
echo "EU: $EU_IP"
echo "---"
curl -s --max-time 10 http://$US_IP/
curl -s --max-time 10 http://$EU_IP/
```

```bash
# Get the instance IDs for later stages
aws ec2 describe-instances --region us-east-1 \
  --filters "Name=tag:Name,Values=ga-demo-us-east-1" \
  --query "Reservations[].Instances[].InstanceId" --output text

aws ec2 describe-instances --region eu-west-1 \
  --filters "Name=tag:Name,Values=ga-demo-eu-west-1" \
  --query "Reservations[].Instances[].InstanceId" --output text
```

---

## 3. Accelerator status and health

```bash
# Capture the accelerator and listener ARNs into variables
ACC=$(aws globalaccelerator list-accelerators --region us-west-2 \
  --query "Accelerators[?Name=='ga-demo'].AcceleratorArn" --output text)

LIS=$(aws globalaccelerator list-listeners --region us-west-2 \
  --accelerator-arn $ACC --query "Listeners[0].ListenerArn" --output text)

echo "ACC=$ACC"
echo "LIS=$LIS"
```

```bash
# Provisioning status: IN_PROGRESS -> DEPLOYED
aws globalaccelerator describe-accelerator --region us-west-2 \
  --accelerator-arn $ACC --query "Accelerator.Status" --output text
```

```bash
# Per-region endpoint health
aws globalaccelerator list-endpoint-groups --region us-west-2 --listener-arn $LIS \
  --query "EndpointGroups[].{Region:EndpointGroupRegion,Health:EndpointDescriptions[0].HealthState}" \
  --output table
```

```bash
# The two static anycast IPs and the DNS name
aws globalaccelerator describe-accelerator --region us-west-2 \
  --accelerator-arn $ACC \
  --query "Accelerator.{DNS:DnsName,IPs:IpSets[0].IpAddresses}" --output json
```

```bash
# Full endpoint group config, including health check settings
aws globalaccelerator list-endpoint-groups --region us-west-2 --listener-arn $LIS \
  --query "EndpointGroups[].{Region:EndpointGroupRegion,Dial:TrafficDialPercentage,Proto:HealthCheckProtocol,Path:HealthCheckPath,Port:HealthCheckPort,Interval:HealthCheckIntervalSeconds,Threshold:ThresholdCount}" \
  --output table
```

---

## 4. Anycast routing test

```bash
echo "--- Static IP 1 ---"
curl -s http://<ACCEL_IP_1>/
echo "--- Static IP 2 ---"
curl -s http://<ACCEL_IP_2>/
echo "--- DNS name ---"
curl -s http://<ACCEL_DNS>/
```

```bash
# Status-code-only variant
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" http://<ACCEL_IP_1>/
```

---

## 5. Failover test

**Terminal 1 — watch loop (runs until Ctrl+C):**

```bash
while true; do
  printf "%s  " "$(date +%H:%M:%S)"
  curl -s --max-time 5 http://<ACCEL_IP_1>/ | sed 's/<[^>]*>//g'
  sleep 5
done
```

**Terminal 2 — stop the nearest instance:**

```bash
aws ec2 stop-instances --region us-east-1 --instance-ids <US_INSTANCE_ID> \
  --query "StoppingInstances[].{Id:InstanceId,State:CurrentState.Name}" --output table
```

**Confirm the endpoint flips to UNHEALTHY:**

```bash
aws globalaccelerator list-endpoint-groups --region us-west-2 --listener-arn $LIS \
  --query "EndpointGroups[].{Region:EndpointGroupRegion,Health:EndpointDescriptions[0].HealthState}" \
  --output table
```

---

## 6. Failback test

```bash
aws ec2 start-instances --region us-east-1 --instance-ids <US_INSTANCE_ID> \
  --query "StartingInstances[].{Id:InstanceId,State:CurrentState.Name}" --output table
```

Re-run the watch loop from section 5. Traffic returns to `us-east-1` with **no dropped
requests**, because the EU endpoint served continuously until US passed its health checks.

---

## 7. Teardown

> **Mandatory.** ~$0.025/hour bills regardless of traffic. Disabling alone does NOT stop
> charges — only deletion does.

```bash
# --- Step 1: disable (required before delete) ---
ACC=$(aws globalaccelerator list-accelerators --region us-west-2 \
  --query "Accelerators[?Name=='ga-demo'].AcceleratorArn" --output text)

aws globalaccelerator update-accelerator --region us-west-2 \
  --accelerator-arn $ACC --no-enabled \
  --query "Accelerator.{Name:Name,Enabled:Enabled,Status:Status}" --output table
```

```bash
# --- Step 2: poll until Enabled=False AND Status=DEPLOYED ---
aws globalaccelerator describe-accelerator --region us-west-2 \
  --accelerator-arn $ACC --query "Accelerator.{Enabled:Enabled,Status:Status}" --output table
```

```bash
# --- Step 3: delete BOTTOM-UP. The CLI does not cascade. ---
# Without this, delete-accelerator fails with AssociatedListenerFoundException.
LIS=$(aws globalaccelerator list-listeners --region us-west-2 \
  --accelerator-arn $ACC --query "Listeners[0].ListenerArn" --output text)

# 3a. endpoint groups
for EG in $(aws globalaccelerator list-endpoint-groups --region us-west-2 \
  --listener-arn $LIS --query "EndpointGroups[].EndpointGroupArn" --output text); do
  aws globalaccelerator delete-endpoint-group --region us-west-2 --endpoint-group-arn $EG
  echo "deleted endpoint group"
done

# 3b. listener
aws globalaccelerator delete-listener --region us-west-2 --listener-arn $LIS
echo "deleted listener"

# 3c. accelerator
aws globalaccelerator delete-accelerator --region us-west-2 --accelerator-arn $ACC
echo "deleted accelerator"
```

```bash
# --- Step 4: verify the accelerator is gone (should return nothing) ---
aws globalaccelerator list-accelerators --region us-west-2 \
  --query "Accelerators[].Name" --output text
```

```bash
# --- Step 5: terminate EC2 in BOTH regions ---
aws ec2 terminate-instances --region us-east-1 --instance-ids <US_INSTANCE_ID> \
  --query "TerminatingInstances[].{Id:InstanceId,State:CurrentState.Name}" --output table

aws ec2 terminate-instances --region eu-west-1 --instance-ids <EU_INSTANCE_ID> \
  --query "TerminatingInstances[].{Id:InstanceId,State:CurrentState.Name}" --output table
```

```bash
# --- Step 6: verify nothing is left in either region ---
for R in us-east-1 eu-west-1; do
  echo "--- $R ---"
  aws ec2 describe-instances --region $R \
    --filters "Name=instance-state-name,Values=running,stopped,pending,stopping" \
    --query "Reservations[].Instances[].{Id:InstanceId,State:State.Name,Name:Tags[?Key=='Name']|[0].Value}" \
    --output table
done
```

```bash
# --- Step 7: optional — delete the security groups in both regions ---
# Only works once the instances are fully terminated.
for R in us-east-1 eu-west-1; do
  SG=$(aws ec2 describe-security-groups --region $R \
    --filters "Name=group-name,Values=ga-demo-sg" \
    --query "SecurityGroups[0].GroupId" --output text)
  [ "$SG" != "None" ] && aws ec2 delete-security-group --region $R --group-id $SG && echo "$R: deleted $SG"
done
```

---

## 8. Git

```bash
# Scaffold the folder and files
mkdir -p aws-global-accelerator/{images,screenshots} && touch aws-global-accelerator/{README.md,notes.md,commands.md}
```

```bash
# Stage, commit and push in one shot
git add . && git commit -m "Add Global Accelerator two-region failover lab" && git push
```

```bash
# For commit messages containing special characters
git commit -F commit-message.txt
```
