# Commands: AWS VPC Fundamentals

All commands from the session, grouped by stage. Region: `us-east-1`. Replace `BASTION_IP` and `YOUR_IP` with real values (no angle brackets: zsh treats `<` `>` as redirection).

## 1. Mac: key pair

```bash
ls -l ~/.ssh
chmod 400 ~/.ssh/MSuccess.pem
ls -l ~/.ssh/MSuccess.pem
```

## 2. Mac: SSH agent

```bash
ssh-add --apple-use-keychain ~/.ssh/MSuccess.pem
ssh-add -l
ssh-add -d ~/.ssh/MSuccess.pem
```

## 3. Lab 1: bastion and private server

```bash
ssh -i ~/.ssh/MSuccess.pem ec2-user@BASTION_IP
```

On the bastion:

```bash
curl -s https://checkip.amazonaws.com
ping -c 4 10.0.2.119
```

From the Mac, through the bastion (ProxyJump):

```bash
ssh -J ec2-user@BASTION_IP ec2-user@10.0.2.119
```

On the app server:

```bash
curl -s --max-time 5 https://checkip.amazonaws.com || echo "NO INTERNET PATH"
```

## 4. Lab 2: NAT gateway tests (on the app server)

```bash
curl -s --max-time 5 https://checkip.amazonaws.com || echo "NO INTERNET PATH"
date; curl -s --max-time 5 https://checkip.amazonaws.com || echo "NO INTERNET PATH"
```

## 5. Lab 3: NACL tests

On the Mac (not inside SSH):

```bash
curl -s https://checkip.amazonaws.com
ssh -o ConnectTimeout=10 ec2-user@BASTION_IP
```

## 6. Teardown verification (CloudShell)

```bash
VPC=vpc-07b4089d20fdd22ec
```

```bash
aws ec2 describe-instances --region us-east-1 --filters Name=vpc-id,Values=$VPC --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,State.Name]' --output table
```

```bash
aws ec2 describe-nat-gateways --region us-east-1 --filter Name=vpc-id,Values=$VPC --query 'NatGateways[].[NatGatewayId,State]' --output table
```

```bash
aws ec2 describe-addresses --region us-east-1 --query 'Addresses[].[PublicIp,AllocationId,AssociationId]' --output table
```

```bash
aws ec2 describe-network-interfaces --region us-east-1 --filters Name=vpc-id,Values=$VPC --query 'NetworkInterfaces[].[NetworkInterfaceId,Status,Description]' --output table
```

After deleting the VPC:

```bash
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[].[VpcId,CidrBlock,IsDefault]' --output table
aws ec2 describe-internet-gateways --region us-east-1 --filters Name=tag:Name,Values=menniboe-internet-GW --query 'InternetGateways[].InternetGatewayId' --output text
aws ec2 describe-security-groups --region us-east-1 --filters Name=group-name,Values='menniboe-*' --query 'SecurityGroups[].[GroupName,GroupId]' --output table
aws ec2 describe-network-acls --region us-east-1 --filters Name=tag:Name,Values=menniboe-public-nacl --query 'NetworkAcls[].NetworkAclId' --output text
aws ec2 describe-key-pairs --region us-east-1 --key-names MSuccess --query 'KeyPairs[].KeyName' --output text
```

---

## CLI-only redo (equivalent of the console labs)

Run in CloudShell. Each command saves the new ID in a variable for the next one.

### Lab 1: network

```bash
export AWS_REGION=us-east-1
VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=menniboe-vpc}]' --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC --enable-dns-hostnames '{"Value":true}'
PUB=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=menniboe-public-1a}]' --query Subnet.SubnetId --output text)
PRIV=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=menniboe-private-1b}]' --query Subnet.SubnetId --output text)
IGW=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=menniboe-internet-GW}]' --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
PUBRT=$(aws ec2 create-route-table --vpc-id $VPC --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=menniboe-public-rt}]' --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $PUBRT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW
aws ec2 associate-route-table --route-table-id $PUBRT --subnet-id $PUB
aws ec2 modify-subnet-attribute --subnet-id $PUB --map-public-ip-on-launch
PRIVRT=$(aws ec2 create-route-table --vpc-id $VPC --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=menniboe-private-rt}]' --query RouteTable.RouteTableId --output text)
aws ec2 associate-route-table --route-table-id $PRIVRT --subnet-id $PRIV
```

### Lab 1: security groups

```bash
MYIP=YOUR_IP
BSG=$(aws ec2 create-security-group --group-name menniboe-bastion-sg --description "SSH from my IP only" --vpc-id $VPC --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $BSG --protocol tcp --port 22 --cidr $MYIP/32
ASG=$(aws ec2 create-security-group --group-name menniboe-app-sg --description "SSH and ping from bastion SG only" --vpc-id $VPC --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $ASG --protocol tcp --port 22 --source-group $BSG
aws ec2 authorize-security-group-ingress --group-id $ASG --protocol icmp --port -1 --source-group $BSG
```

### Lab 1: instances

```bash
AMI=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)
aws ec2 run-instances --image-id $AMI --instance-type t3.micro --key-name MSuccess --subnet-id $PUB --security-group-ids $BSG --associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=menniboe-bastion}]' --query 'Instances[0].InstanceId' --output text
aws ec2 run-instances --image-id $AMI --instance-type t3.micro --key-name MSuccess --subnet-id $PRIV --security-group-ids $ASG --no-associate-public-ip-address --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=menniboe-app}]' --query 'Instances[0].InstanceId' --output text
```

### Lab 2: NAT gateway (billed hourly)

```bash
ALLOC=$(aws ec2 allocate-address --domain vpc --query AllocationId --output text)
NAT=$(aws ec2 create-nat-gateway --subnet-id $PUB --allocation-id $ALLOC --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=menniboe-nat-1a}]' --query NatGateway.NatGatewayId --output text)
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT
aws ec2 create-route --route-table-id $PRIVRT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT
```

Cleanup:

```bash
aws ec2 delete-nat-gateway --nat-gateway-id $NAT
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT
aws ec2 release-address --allocation-id $ALLOC
aws ec2 delete-route --route-table-id $PRIVRT --destination-cidr-block 0.0.0.0/0
```

### Lab 3: NACL tests

```bash
NACL=$(aws ec2 create-network-acl --vpc-id $VPC --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=menniboe-public-nacl}]' --query NetworkAcl.NetworkAclId --output text)
ASSOC=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$PUB --query "NetworkAcls[].Associations[?SubnetId=='$PUB'].NetworkAclAssociationId" --output text)
aws ec2 replace-network-acl-association --association-id $ASSOC --network-acl-id $NACL
```

Test B, C and D rules:

```bash
aws ec2 create-network-acl-entry --network-acl-id $NACL --ingress --rule-number 100 --protocol tcp --port-range From=22,To=22 --cidr-block $MYIP/32 --rule-action allow
aws ec2 create-network-acl-entry --network-acl-id $NACL --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block $MYIP/32 --rule-action allow
aws ec2 create-network-acl-entry --network-acl-id $NACL --ingress --rule-number 90 --protocol tcp --port-range From=22,To=22 --cidr-block $MYIP/32 --rule-action deny
```

### Teardown

```bash
IDS=$(aws ec2 describe-instances --filters Name=vpc-id,Values=$VPC Name=instance-state-name,Values=running,stopped --query 'Reservations[].Instances[].InstanceId' --output text)
aws ec2 terminate-instances --instance-ids $IDS
aws ec2 wait instance-terminated --instance-ids $IDS
DEF=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$VPC Name=default,Values=true --query 'NetworkAcls[0].NetworkAclId' --output text)
ASSOC=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$PUB --query "NetworkAcls[].Associations[?SubnetId=='$PUB'].NetworkAclAssociationId" --output text)
aws ec2 replace-network-acl-association --association-id $ASSOC --network-acl-id $DEF
aws ec2 delete-network-acl --network-acl-id $NACL
aws ec2 delete-security-group --group-id $ASG
aws ec2 delete-security-group --group-id $BSG
aws ec2 delete-subnet --subnet-id $PUB
aws ec2 delete-subnet --subnet-id $PRIV
aws ec2 delete-route-table --route-table-id $PUBRT
aws ec2 delete-route-table --route-table-id $PRIVRT
aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC
aws ec2 delete-internet-gateway --internet-gateway-id $IGW
aws ec2 delete-vpc --vpc-id $VPC
```
