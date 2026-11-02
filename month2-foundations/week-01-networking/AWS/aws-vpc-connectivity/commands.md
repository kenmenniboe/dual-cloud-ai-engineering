# Commands: AWS VPC Connectivity

Every command from the session, grouped by workflow stage, followed by a CLI-only version of the whole lab for future reps.

> [!NOTE]
> Run Mac commands in zsh. Code blocks contain no `#` comments, because zsh doesn't treat `#` as a comment when pasting interactively. Region is `us-east-1` throughout.

## Contents

- [Inside the instances](#inside-the-instances)
- [Flow Logs reading](#flow-logs-reading)
- [Teardown from the Mac](#teardown-from-the-mac)
- [Verify nothing is left](#verify-nothing-is-left)
- [Account-wide checks](#account-wide-checks)
- [CLI-only redo of the lab](#cli-only-redo-of-the-lab)

---

## Inside the instances

### EC2-A (browser shell through EC2 Instance Connect)

Ping EC2-B across the peering connection:

```bash
ping -c 4 10.1.0.75
```

Generate ACCEPT records (ICMP) and a REJECT record (TCP 80, no SG rule):

```bash
ping -c 10 10.1.0.75
curl -m 3 http://10.1.0.75
```

### EC2-B (browser shell through the EC2 Instance Connect Endpoint)

Confirm the instance role supplies the credentials:

```bash
aws configure list
```

Test S3 with short timeouts, before and after the gateway endpoint:

```bash
aws s3 ls --region us-east-1 --cli-connect-timeout 5 --cli-read-timeout 5
```

| Result | Meaning |
|---|---|
| `Connect timeout on endpoint URL` | No network path to S3 |
| Bucket list | Path exists (gateway endpoint + route) |
| `AccessDenied` | Path exists, IAM permissions missing |

---

## Flow Logs reading

CloudWatch Logs filter (log stream `eni-…-all`):

```text
10.0.0.25
```

Default record format:

```text
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
```

Same query from the CLI:

```bash
aws logs filter-log-events --log-group-name /vpc/lab-b-flowlogs --filter-pattern '"10.0.0.25"' --query 'events[].message' --output text
```

Only REJECT records:

```bash
aws logs filter-log-events --log-group-name /vpc/lab-b-flowlogs --filter-pattern 'REJECT' --query 'events[].message' --output text
```

---

## Teardown from the Mac

### Stage 1: instances, endpoints, flow logs

```bash
export AWS_DEFAULT_REGION=us-east-1
VPC_A=vpc-0d3931da0afadc379
VPC_B=vpc-0313ecbc27e671df8
aws sts get-caller-identity --query Account --output text
```

```bash
aws ec2 terminate-instances --instance-ids i-00cd51d97588012b6 i-0fe2e8bbf419af8ec --query 'TerminatingInstances[].[InstanceId,CurrentState.Name]' --output table
```

```bash
aws ec2 delete-instance-connect-endpoint --instance-connect-endpoint-id eice-0cd257eabf8d42a4c --query 'InstanceConnectEndpoint.State' --output text
```

```bash
S3_EP=$(aws ec2 describe-vpc-endpoints --filters Name=vpc-id,Values=$VPC_B Name=service-name,Values=com.amazonaws.us-east-1.s3 --query 'VpcEndpoints[].VpcEndpointId' --output text)
echo $S3_EP
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids ${=S3_EP}
```

```bash
aws ec2 delete-flow-logs --flow-log-ids fl-0f7ccd1ba95d632c5
aws logs delete-log-group --log-group-name /vpc/lab-b-flowlogs
```

```bash
aws ec2 wait instance-terminated --instance-ids i-00cd51d97588012b6 i-0fe2e8bbf419af8ec && echo "Both instances terminated"
```

### Stage 2: peering and both VPCs

Wait until the EIC Endpoint is fully gone (its ENI blocks subnet deletion):

```bash
aws ec2 describe-instance-connect-endpoints --query 'InstanceConnectEndpoints[].[InstanceConnectEndpointId,State]' --output table
```

```bash
aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id pcx-07f4ad586a2c525e2
```

VPC-A:

```bash
SG_A=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC_A Name=group-name,Values=sg-ec2-a --query 'SecurityGroups[0].GroupId' --output text)
aws ec2 detach-internet-gateway --internet-gateway-id igw-0e0dc95606c80938b --vpc-id $VPC_A
aws ec2 delete-internet-gateway --internet-gateway-id igw-0e0dc95606c80938b
aws ec2 delete-subnet --subnet-id subnet-07401f693e0d9d46a
aws ec2 delete-route-table --route-table-id rtb-0779b7c3d6a5b0a35
aws ec2 delete-security-group --group-id $SG_A
aws ec2 delete-vpc --vpc-id $VPC_A
```

VPC-B:

```bash
aws ec2 delete-subnet --subnet-id subnet-0dd2266d5f5b559f3
aws ec2 delete-route-table --route-table-id rtb-0f7f3f8f2cfdd8a94
aws ec2 delete-security-group --group-id sg-0fdccd83b0c2e2751
aws ec2 delete-vpc --vpc-id $VPC_B
```

### Stage 3: IAM roles and policies

Instance role for EC2-B:

```bash
aws iam remove-role-from-instance-profile --instance-profile-name lab-ec2-b-s3-read --role-name lab-ec2-b-s3-read
aws iam delete-instance-profile --instance-profile-name lab-ec2-b-s3-read
aws iam detach-role-policy --role-name lab-ec2-b-s3-read --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam delete-role --role-name lab-ec2-b-s3-read
```

Flow Logs service role and the customer-managed policy the console created:

```bash
ROLE=VPCFlowLogs-Cloudwatch-1793597444538
ACCT=$(aws sts get-caller-identity --query Account --output text)
POLICY_ARN=arn:aws:iam::$ACCT:policy/service-role/VPCFlowLogs-CloudWatch-Policy-1793597782160
aws iam list-role-policies --role-name $ROLE
aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY_ARN
aws iam delete-role --role-name $ROLE
aws iam delete-policy --policy-arn $POLICY_ARN
```

If `list-role-policies` returns an inline policy name, delete it before `delete-role`:

```bash
aws iam delete-role-policy --role-name $ROLE --policy-name <inline-policy-name>
```

---

## Verify nothing is left

An empty table or no output means nothing is left for that resource type.

```bash
export AWS_DEFAULT_REGION=us-east-1
echo "== EC2 instances (not terminated)"
aws ec2 describe-instances --filters Name=instance-state-name,Values=pending,running,stopping,stopped --query 'Reservations[].Instances[].[InstanceId,State.Name,Tags[?Key==`Name`]|[0].Value]' --output table
echo "== VPCs (only the default should remain)"
aws ec2 describe-vpcs --query 'Vpcs[].[VpcId,CidrBlock,IsDefault,Tags[?Key==`Name`]|[0].Value]' --output table
echo "== VPC endpoints"
aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[].[VpcEndpointId,VpcEndpointType,State]' --output table
echo "== Instance Connect endpoints"
aws ec2 describe-instance-connect-endpoints --query 'InstanceConnectEndpoints[].[InstanceConnectEndpointId,State]' --output table
echo "== Peering connections"
aws ec2 describe-vpc-peering-connections --filters Name=status-code,Values=active,pending-acceptance --query 'VpcPeeringConnections[].[VpcPeeringConnectionId,Status.Code]' --output table
echo "== Flow logs"
aws ec2 describe-flow-logs --query 'FlowLogs[].[FlowLogId,FlowLogStatus,LogDestination]' --output table
echo "== NAT gateways and Elastic IPs"
aws ec2 describe-nat-gateways --filter Name=state,Values=pending,available --query 'NatGateways[].[NatGatewayId,State]' --output table
aws ec2 describe-addresses --query 'Addresses[].[PublicIp,AllocationId,AssociationId]' --output table
echo "== Log groups"
aws logs describe-log-groups --log-group-name-prefix /vpc --query 'logGroups[].logGroupName' --output table
echo "== Lab IAM roles"
aws iam list-roles --query "Roles[?starts_with(RoleName,'lab-') || starts_with(RoleName,'VPCFlowLogs')].RoleName" --output table
```

---

## Account-wide checks

Running or stopped instances in every Region:

```bash
for r in $(aws ec2 describe-regions --query 'Regions[].RegionName' --output text); do echo "== $r"; aws ec2 describe-instances --region $r --filters Name=instance-state-name,Values=running,stopped --query 'Reservations[].Instances[].[InstanceId,State.Name]' --output text; done
```

CloudFormation stacks, ECS clusters and load balancers left from earlier labs:

```bash
aws cloudformation describe-stacks --query 'Stacks[].[StackName,StackStatus]' --output table
aws ecs list-clusters --output table
aws elbv2 describe-load-balancers --query 'LoadBalancers[].[LoadBalancerName,State.Code]' --output table
```

KMS keys: `CUSTOMER` + `Enabled` is a paid key, `AWS` keys are free:

```bash
for k in $(aws kms list-keys --query 'Keys[].KeyId' --output text); do aws kms describe-key --key-id $k --query 'KeyMetadata.[KeyId,KeyManager,KeyState,Description]' --output text; done
```

Deletion date of a key in `PendingDeletion`:

```bash
aws kms describe-key --key-id <key-id> --query 'KeyMetadata.DeletionDate' --output text
```

---

## CLI-only redo of the lab

The same build as the console lab, for repeat practice. Run in order; each block stores IDs in variables for the next.

### 1. Region and AMI

```bash
export AWS_DEFAULT_REGION=us-east-1
AMI=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)
echo $AMI
```

### 2. VPC-A with a public subnet

```bash
VPC_A=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lab-A-vpc}]' --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_A --enable-dns-hostnames '{"Value":true}'
SUB_A=$(aws ec2 create-subnet --vpc-id $VPC_A --cidr-block 10.0.0.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab-A-subnet-public1}]' --query Subnet.SubnetId --output text)
aws ec2 modify-subnet-attribute --subnet-id $SUB_A --map-public-ip-on-launch
IGW=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=lab-A-igw}]' --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_A
RT_A=$(aws ec2 create-route-table --vpc-id $VPC_A --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=lab-A-rtb-public}]' --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $RT_A --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 associate-route-table --route-table-id $RT_A --subnet-id $SUB_A
```

### 3. VPC-B with a private subnet only

```bash
VPC_B=$(aws ec2 create-vpc --cidr-block 10.1.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=lab-B-vpc}]' --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_B --enable-dns-hostnames '{"Value":true}'
SUB_B=$(aws ec2 create-subnet --vpc-id $VPC_B --cidr-block 10.1.0.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=lab-B-subnet-private1}]' --query Subnet.SubnetId --output text)
RT_B=$(aws ec2 create-route-table --vpc-id $VPC_B --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=lab-B-rtb-private1}]' --query RouteTable.RouteTableId --output text)
aws ec2 associate-route-table --route-table-id $RT_B --subnet-id $SUB_B
```

### 4. Security Groups

```bash
PL_EIC=$(aws ec2 describe-managed-prefix-lists --filters Name=prefix-list-name,Values=com.amazonaws.us-east-1.ec2-instance-connect --query 'PrefixLists[0].PrefixListId' --output text)
SG_A=$(aws ec2 create-security-group --group-name sg-ec2-a --description "SSH from EC2 Instance Connect" --vpc-id $VPC_A --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_A --ip-permissions "IpProtocol=tcp,FromPort=22,ToPort=22,PrefixListIds=[{PrefixListId=$PL_EIC}]"
SG_B=$(aws ec2 create-security-group --group-name ec2-b-sg --description "ICMP from VPC-A, SSH from VPC-B" --vpc-id $VPC_B --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_B --ip-permissions 'IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=10.1.0.0/16,Description=SSH-from-EIC-endpoint}]' 'IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=10.0.0.0/16,Description=ping-from-VPC-A}]'
aws ec2 describe-security-groups --group-ids $SG_B --query 'SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]' --output table
```

### 5. Instance role for EC2-B

```bash
cat > ec2-trust.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF
aws iam create-role --role-name lab-ec2-b-s3-read --assume-role-policy-document file://ec2-trust.json --query Role.Arn --output text
aws iam attach-role-policy --role-name lab-ec2-b-s3-read --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam create-instance-profile --instance-profile-name lab-ec2-b-s3-read
aws iam add-role-to-instance-profile --instance-profile-name lab-ec2-b-s3-read --role-name lab-ec2-b-s3-read
sleep 10
```

### 6. Launch both instances

```bash
EC2_A=$(aws ec2 run-instances --image-id $AMI --instance-type t3.micro --subnet-id $SUB_A --security-group-ids $SG_A --metadata-options HttpTokens=required --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EC2-A}]' --query 'Instances[0].InstanceId' --output text)
EC2_B=$(aws ec2 run-instances --image-id $AMI --instance-type t3.micro --subnet-id $SUB_B --security-group-ids $SG_B --iam-instance-profile Name=lab-ec2-b-s3-read --metadata-options HttpTokens=required --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EC2-B}]' --query 'Instances[0].InstanceId' --output text)
aws ec2 wait instance-running --instance-ids $EC2_A $EC2_B
aws ec2 describe-instances --instance-ids $EC2_A $EC2_B --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,PrivateIpAddress,PublicIpAddress]' --output table
```

### 7. Peering and routes on both sides

```bash
PCX=$(aws ec2 create-vpc-peering-connection --vpc-id $VPC_A --peer-vpc-id $VPC_B --tag-specifications 'ResourceType=vpc-peering-connection,Tags=[{Key=Name,Value=lab-A-to-B}]' --query VpcPeeringConnection.VpcPeeringConnectionId --output text)
aws ec2 accept-vpc-peering-connection --vpc-peering-connection-id $PCX --query 'VpcPeeringConnection.Status.Code' --output text
aws ec2 create-route --route-table-id $RT_A --destination-cidr-block 10.1.0.0/16 --vpc-peering-connection-id $PCX
aws ec2 create-route --route-table-id $RT_B --destination-cidr-block 10.0.0.0/16 --vpc-peering-connection-id $PCX
aws ec2 describe-route-tables --route-table-ids $RT_A $RT_B --query 'RouteTables[].Routes[].[DestinationCidrBlock,GatewayId,VpcPeeringConnectionId,State]' --output table
```

### 8. Flow Logs to CloudWatch Logs

```bash
cat > flowlogs-trust.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"vpc-flow-logs.amazonaws.com"},"Action":"sts:AssumeRole"}]}
EOF
cat > flowlogs-perms.json <<'EOF'
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents","logs:DescribeLogGroups","logs:DescribeLogStreams"],"Resource":"*"}]}
EOF
FL_ROLE_ARN=$(aws iam create-role --role-name lab-flowlogs-role --assume-role-policy-document file://flowlogs-trust.json --query Role.Arn --output text)
aws iam put-role-policy --role-name lab-flowlogs-role --policy-name lab-flowlogs-cwl --policy-document file://flowlogs-perms.json
sleep 10
aws ec2 create-flow-logs --resource-type VPC --resource-ids $VPC_B --traffic-type ALL --log-destination-type cloud-watch-logs --log-group-name /vpc/lab-b-flowlogs --deliver-logs-permission-arn $FL_ROLE_ARN --max-aggregation-interval 60
```

### 9. EC2 Instance Connect Endpoint and shell into EC2-B

```bash
EICE=$(aws ec2 create-instance-connect-endpoint --subnet-id $SUB_B --tag-specifications 'ResourceType=instance-connect-endpoint,Tags=[{Key=Name,Value=lab-b-eice}]' --query InstanceConnectEndpoint.InstanceConnectEndpointId --output text)
aws ec2 describe-instance-connect-endpoints --instance-connect-endpoint-ids $EICE --query 'InstanceConnectEndpoints[0].State' --output text
```

When the state is `create-complete`:

```bash
aws ec2-instance-connect ssh --instance-id $EC2_B --connection-type eice
```

### 10. S3 gateway endpoint

```bash
VPCE=$(aws ec2 create-vpc-endpoint --vpc-id $VPC_B --vpc-endpoint-type Gateway --service-name com.amazonaws.us-east-1.s3 --route-table-ids $RT_B --tag-specifications 'ResourceType=vpc-endpoint,Tags=[{Key=Name,Value=lab-b-s3-gw}]' --query VpcEndpoint.VpcEndpointId --output text)
aws ec2 describe-route-tables --route-table-ids $RT_B --query 'RouteTables[0].Routes[].[DestinationCidrBlock,DestinationPrefixListId,GatewayId,VpcPeeringConnectionId]' --output table
```

The table must include `pl-63a5400a` with the `vpce-…` target.

### 11. Teardown of the CLI build

```bash
aws ec2 terminate-instances --instance-ids $EC2_A $EC2_B --output text
aws ec2 delete-instance-connect-endpoint --instance-connect-endpoint-id $EICE --output text
aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $VPCE
aws ec2 delete-flow-logs --flow-log-ids $(aws ec2 describe-flow-logs --filter Name=resource-id,Values=$VPC_B --query 'FlowLogs[].FlowLogId' --output text)
aws logs delete-log-group --log-group-name /vpc/lab-b-flowlogs
aws ec2 wait instance-terminated --instance-ids $EC2_A $EC2_B
aws ec2 delete-vpc-peering-connection --vpc-peering-connection-id $PCX
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_A
aws ec2 delete-internet-gateway --internet-gateway-id $IGW
```

After `describe-instance-connect-endpoints` shows nothing for `$EICE`:

```bash
aws ec2 delete-subnet --subnet-id $SUB_A
aws ec2 delete-subnet --subnet-id $SUB_B
aws ec2 delete-route-table --route-table-id $RT_A
aws ec2 delete-route-table --route-table-id $RT_B
aws ec2 delete-security-group --group-id $SG_A
aws ec2 delete-security-group --group-id $SG_B
aws ec2 delete-vpc --vpc-id $VPC_A
aws ec2 delete-vpc --vpc-id $VPC_B
aws iam remove-role-from-instance-profile --instance-profile-name lab-ec2-b-s3-read --role-name lab-ec2-b-s3-read
aws iam delete-instance-profile --instance-profile-name lab-ec2-b-s3-read
aws iam detach-role-policy --role-name lab-ec2-b-s3-read --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess
aws iam delete-role --role-name lab-ec2-b-s3-read
aws iam delete-role-policy --role-name lab-flowlogs-role --policy-name lab-flowlogs-cwl
aws iam delete-role --role-name lab-flowlogs-role
rm -f ec2-trust.json flowlogs-trust.json flowlogs-perms.json
```
