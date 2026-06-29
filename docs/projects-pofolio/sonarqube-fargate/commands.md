# SonarQube on AWS Fargate — Commands Reference

> CLI and Terraform equivalents of the full Console build.
> All commands target region: `us-east-1`

---

## AWS CLI Version

### Prerequisites
```bash
# Configure AWS CLI
aws configure
# AWS Access Key ID: <your key>
# AWS Secret Access Key: <your secret>
# Default region: us-east-1
# Default output format: json

# Verify identity
aws sts get-caller-identity
```

---

### Stage 1 — VPC

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
  --cidr-block 10.0.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=sonarqube-demo-vpc}]' \
  --query 'Vpc.VpcId' --output text)
echo "VPC: $VPC_ID"

# Enable DNS support
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames "{\"Value\":true}"
```

---

### Stage 2 — Subnets

```bash
# Public Subnet 1 (us-east-1a)
PUB_SUB_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sonarqube-public-subnet-1}]' \
  --query 'Subnet.SubnetId' --output text)

# Public Subnet 2 (us-east-1b)
PUB_SUB_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sonarqube-public-subnet-2}]' \
  --query 'Subnet.SubnetId' --output text)

# Private Subnet 1 (us-east-1a)
PRIV_SUB_1=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.3.0/24 \
  --availability-zone us-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sonarqube-private-subnet-1}]' \
  --query 'Subnet.SubnetId' --output text)

# Private Subnet 2 (us-east-1b)
PRIV_SUB_2=$(aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.4.0/24 \
  --availability-zone us-east-1b \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=sonarqube-private-subnet-2}]' \
  --query 'Subnet.SubnetId' --output text)

# Enable auto-assign public IP on public subnets
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB_1 --map-public-ip-on-launch
aws ec2 modify-subnet-attribute --subnet-id $PUB_SUB_2 --map-public-ip-on-launch

echo "Public: $PUB_SUB_1 $PUB_SUB_2"
echo "Private: $PRIV_SUB_1 $PRIV_SUB_2"
```

---

### Stage 3 — Internet Gateway

```bash
# Create and attach IGW
IGW_ID=$(aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=sonarqube-igw}]' \
  --query 'InternetGateway.InternetGatewayId' --output text)

aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
echo "IGW: $IGW_ID"
```

---

### Stage 4 — NAT Gateway

```bash
# Allocate Elastic IP
EIP_ALLOC=$(aws ec2 allocate-address \
  --domain vpc \
  --query 'AllocationId' --output text)

# Create NAT Gateway in public subnet 1
NAT_GW_ID=$(aws ec2 create-nat-gateway \
  --subnet-id $PUB_SUB_1 \
  --allocation-id $EIP_ALLOC \
  --tag-specifications 'ResourceType=natgateway,Tags=[{Key=Name,Value=sonarqube-nat-gw}]' \
  --query 'NatGateway.NatGatewayId' --output text)

# Wait for NAT Gateway to become available
echo "Waiting for NAT Gateway..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GW_ID
echo "NAT GW: $NAT_GW_ID"
```

---

### Stage 5 — Route Tables

```bash
# Public Route Table
PUB_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=sonarqube-public-rt}]' \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUB_1
aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $PUB_SUB_2

# Private Route Table
PRIV_RT=$(aws ec2 create-route-table \
  --vpc-id $VPC_ID \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=sonarqube-private-rt}]' \
  --query 'RouteTable.RouteTableId' --output text)

aws ec2 create-route --route-table-id $PRIV_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_GW_ID
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_SUB_1
aws ec2 associate-route-table --route-table-id $PRIV_RT --subnet-id $PRIV_SUB_2

echo "Public RT: $PUB_RT | Private RT: $PRIV_RT"
```

---

### Stage 6 — Security Groups

```bash
# ALB Security Group
ALB_SG=$(aws ec2 create-security-group \
  --group-name sonarqube-alb-sg \
  --description "Security group for SonarQube Load Balancer" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $ALB_SG --protocol tcp --port 443 --cidr 0.0.0.0/0

# ECS Security Group
ECS_SG=$(aws ec2 create-security-group \
  --group-name sonarqube-ecs-sg \
  --description "Security group for SonarQube Fargate Tasks" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $ECS_SG --protocol tcp --port 9000 --source-group $ALB_SG

# RDS Security Group
RDS_SG=$(aws ec2 create-security-group \
  --group-name sonarqube-rds-sg \
  --description "Security group for SonarQube RDS Database" \
  --vpc-id $VPC_ID \
  --query 'GroupId' --output text)

aws ec2 authorize-security-group-ingress --group-id $RDS_SG --protocol tcp --port 5432 --source-group $ECS_SG

echo "ALB SG: $ALB_SG | ECS SG: $ECS_SG | RDS SG: $RDS_SG"
```

---

### Stage 7 — RDS PostgreSQL

```bash
# DB Subnet Group
aws rds create-db-subnet-group \
  --db-subnet-group-name sonarqube-db-subnet-group \
  --db-subnet-group-description "Subnet group for SonarQube RDS" \
  --subnet-ids $PRIV_SUB_1 $PRIV_SUB_2

# Create RDS Instance
aws rds create-db-instance \
  --db-instance-identifier sonarqube-db \
  --db-instance-class db.t4g.micro \
  --engine postgres \
  --master-username sonarqube \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 20 \
  --db-name sonarqube \
  --vpc-security-group-ids $RDS_SG \
  --db-subnet-group-name sonarqube-db-subnet-group \
  --no-publicly-accessible \
  --no-multi-az \
  --no-enable-performance-insights \
  --backup-retention-period 0

# Wait for RDS to be available (takes 5-10 min)
echo "Waiting for RDS..."
aws rds wait db-instance-available --db-instance-identifier sonarqube-db

# Get endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier sonarqube-db \
  --query 'DBInstances[0].Endpoint.Address' --output text)
echo "RDS Endpoint: $RDS_ENDPOINT"
```

---

### Stage 8 — ECS Cluster

```bash
aws ecs create-cluster \
  --cluster-name sonarqube-cluster \
  --capacity-providers FARGATE \
  --default-capacity-provider-strategy capacityProvider=FARGATE,weight=1

echo "ECS Cluster created: sonarqube-cluster"
```

---

### Stage 9 — Task Definition

```bash
# Create task definition JSON
cat > /tmp/sonarqube-task-def.json << EOF
{
  "family": "sonarqube-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "3072",
  "executionRoleArn": "arn:aws:iam::860945038667:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "sonarqube",
      "image": "sonarqube:community",
      "portMappings": [
        {
          "containerPort": 9000,
          "protocol": "tcp",
          "appProtocol": "http"
        }
      ],
      "environment": [
        {
          "name": "SONAR_JDBC_URL",
          "value": "jdbc:postgresql://${RDS_ENDPOINT}:5432/sonarqube"
        },
        {
          "name": "SONAR_JDBC_USERNAME",
          "value": "sonarqube"
        },
        {
          "name": "SONAR_JDBC_PASSWORD",
          "value": "YourSecurePassword123!"
        }
      ],
      "ulimits": [
        {
          "name": "nofile",
          "softLimit": 65536,
          "hardLimit": 65536
        }
      ],
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:9000/api/system/status || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 120
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/sonarqube",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "startTimeout": 120,
      "stopTimeout": 30
    }
  ]
}
EOF

# Create CloudWatch log group
aws logs create-log-group --log-group-name /ecs/sonarqube

# Register task definition
aws ecs register-task-definition --cli-input-json file:///tmp/sonarqube-task-def.json
echo "Task definition registered: sonarqube-task:1"
```

---

### Stage 10 — Application Load Balancer + Target Group

```bash
# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name sonarqube-alb \
  --subnets $PUB_SUB_1 $PUB_SUB_2 \
  --security-groups $ALB_SG \
  --scheme internet-facing \
  --type application \
  --ip-address-type ipv4 \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

# Create Target Group
TG_ARN=$(aws elbv2 create-target-group \
  --name sonarqube-tg \
  --protocol HTTP \
  --port 9000 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path /api/system/status \
  --health-check-protocol HTTP \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

# Create HTTP:80 listener (redirect to HTTPS)
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}"

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' --output text)
echo "ALB DNS: $ALB_DNS"
echo "TG ARN: $TG_ARN"
```

---

### Stage 11 — ECS Service

```bash
aws ecs create-service \
  --cluster sonarqube-cluster \
  --service-name sonarqube-service \
  --task-definition sonarqube-task:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIV_SUB_1,$PRIV_SUB_2],securityGroups=[$ECS_SG],assignPublicIp=DISABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=sonarqube,containerPort=9000" \
  --health-check-grace-period-seconds 120

echo "ECS Service created: sonarqube-service"
```

---

### Stage 12 — SSL (ACM + ALB HTTPS Listener)

```bash
# Request ACM certificate (DNS validation)
CERT_ARN=$(aws acm request-certificate \
  --domain-name menniboefarm.com \
  --subject-alternative-names www.menniboefarm.com \
  --validation-method DNS \
  --key-algorithm RSA_2048 \
  --query 'CertificateArn' --output text)
echo "Certificate ARN: $CERT_ARN"

# Get DNS validation records to add to Namecheap
aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --query 'Certificate.DomainValidationOptions[*].{Domain:DomainName,Name:ResourceRecord.Name,Value:ResourceRecord.Value}' \
  --output table

# After adding CNAME records in Namecheap and cert is Issued:
# Add HTTPS:443 listener
aws elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTPS \
  --port 443 \
  --certificates CertificateArn=$CERT_ARN \
  --ssl-policy ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "HTTPS listener added. SonarQube live at https://menniboefarm.com"
```

---

## Terraform Version

### File Structure
```
sonarqube-fargate/
├── main.tf
├── variables.tf
├── outputs.tf
└── terraform.tfvars
```

---

### variables.tf

```hcl
variable "region" {
  default = "us-east-1"
}

variable "db_password" {
  description = "RDS master password"
  sensitive   = true
}

variable "domain_name" {
  default = "menniboefarm.com"
}
```

---

### main.tf

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── VPC ──────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "sonarqube-demo-vpc" }
}

# ── Subnets ───────────────────────────────────────────────────────────────────

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = { Name = "sonarqube-public-subnet-1" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = { Name = "sonarqube-public-subnet-2" }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "sonarqube-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "sonarqube-private-subnet-2" }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "sonarqube-igw" }
}

# ── NAT Gateway ───────────────────────────────────────────────────────────────

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id
  tags          = { Name = "sonarqube-nat-gw" }
  depends_on    = [aws_internet_gateway.main]
}

# ── Route Tables ──────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "sonarqube-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "sonarqube-private-rt" }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}

# ── Security Groups ───────────────────────────────────────────────────────────

resource "aws_security_group" "alb" {
  name        = "sonarqube-alb-sg"
  description = "Security group for SonarQube Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sonarqube-alb-sg" }
}

resource "aws_security_group" "ecs" {
  name        = "sonarqube-ecs-sg"
  description = "Security group for SonarQube Fargate Tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sonarqube-ecs-sg" }
}

resource "aws_security_group" "rds" {
  name        = "sonarqube-rds-sg"
  description = "Security group for SonarQube RDS Database"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sonarqube-rds-sg" }
}

# ── RDS PostgreSQL ────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "main" {
  name       = "sonarqube-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  tags       = { Name = "sonarqube-db-subnet-group" }
}

resource "aws_db_instance" "main" {
  identifier             = "sonarqube-db"
  engine                 = "postgres"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_name                = "sonarqube"
  username               = "sonarqube"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  backup_retention_period = 0
  tags = { Name = "sonarqube-db" }
}

# ── ECS Cluster ───────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "main" {
  name = "sonarqube-cluster"
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "sonarqube" {
  name              = "/ecs/sonarqube"
  retention_in_days = 7
}

# ── ECS Task Definition ───────────────────────────────────────────────────────

resource "aws_ecs_task_definition" "sonarqube" {
  family                   = "sonarqube-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "3072"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name  = "sonarqube"
      image = "sonarqube:community"
      portMappings = [
        {
          containerPort = 9000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = [
        {
          name  = "SONAR_JDBC_URL"
          value = "jdbc:postgresql://${aws_db_instance.main.address}:5432/sonarqube"
        },
        {
          name  = "SONAR_JDBC_USERNAME"
          value = "sonarqube"
        },
        {
          name  = "SONAR_JDBC_PASSWORD"
          value = var.db_password
        }
      ]
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65536
          hardLimit = 65536
        }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:9000/api/system/status || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/sonarqube"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
      startTimeout = 120
      stopTimeout  = 30
    }
  ])
}

# ── IAM Role for ECS Task Execution ──────────────────────────────────────────

resource "aws_iam_role" "ecs_execution" {
  name = "sonarqube-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── Application Load Balancer ─────────────────────────────────────────────────

resource "aws_lb" "main" {
  name               = "sonarqube-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags               = { Name = "sonarqube-alb" }
}

resource "aws_lb_target_group" "sonarqube" {
  name        = "sonarqube-tg"
  port        = 9000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/api/system/status"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09"
  certificate_arn   = aws_acm_certificate_validation.main.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }
}

# ── ACM Certificate ───────────────────────────────────────────────────────────

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  # DNS validation records must be added to Namecheap manually
  # Get records from: aws_acm_certificate.main.domain_validation_options
}

# ── ECS Service ───────────────────────────────────────────────────────────────

resource "aws_ecs_service" "sonarqube" {
  name            = "sonarqube-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.sonarqube.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sonarqube.arn
    container_name   = "sonarqube"
    container_port   = 9000
  }

  health_check_grace_period_seconds = 120

  depends_on = [
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_execution
  ]
}
```

---

### outputs.tf

```hcl
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = aws_db_instance.main.address
}

output "sonarqube_url" {
  description = "SonarQube URL"
  value       = "https://${var.domain_name}"
}

output "acm_validation_records" {
  description = "DNS records to add to Namecheap for certificate validation"
  value       = aws_acm_certificate.main.domain_validation_options
}
```

---

### terraform.tfvars

```hcl
region      = "us-east-1"
db_password = "YourSecurePassword123!"
domain_name = "menniboefarm.com"
```

---

### Terraform Workflow

```bash
# Initialize
terraform init

# Preview changes
terraform plan

# Apply
terraform apply

# Destroy all resources when done
terraform destroy
```

---

## One-Line Folder Setup Command

```bash
mkdir -p sat-jun-28-sonarqube-fargate && touch sat-jun-28-sonarqube-fargate/{README.md,notes.md,commands.md}
```