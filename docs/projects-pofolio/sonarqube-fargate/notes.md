# SonarQube on AWS Fargate — Reference Notes

> Mini-tutorial and reference guide for rebuilding this from scratch.

---

## Project Overview

### What is SonarQube?
A code quality and security scanning tool. It analyzes source code for bugs, vulnerabilities, and code smells. It runs as a Java web application backed by a PostgreSQL database.

### Why Fargate Over EC2?

| Reason | Detail |
|--------|--------|
| No server management | No OS patching, no AMI selection, no SSH key management |
| Cost efficiency | Billed per second of CPU/RAM used — no idle EC2 cost |
| Auto-recovery | ECS Service restarts crashed containers automatically |
| Container-native | Fargate is purpose-built for containers — no EC2 overhead |

**EC2 is better when:** You need persistent local storage, GPU workloads, or full OS control.

### Why Each Service Was Provisioned

| Service | Why We Need It |
|---------|---------------|
| VPC | Isolated private network — nothing is exposed by default |
| Public Subnets | Required for ALB (internet-facing) and NAT Gateway |
| Private Subnets | Fargate tasks and RDS never exposed directly to internet |
| Internet Gateway | Door between VPC and public internet |
| NAT Gateway | Allows private subnet resources to reach internet (outbound only) |
| Route Tables | GPS for network traffic — tells packets where to go |
| Security Groups | Virtual firewall per resource — defense in depth |
| RDS PostgreSQL | SonarQube requires a relational DB; PostgreSQL is recommended |
| ECS Cluster | Groups all Fargate tasks and services |
| Task Definition | Blueprint: what container to run, how much CPU/RAM, env vars |
| ECS Service | Supervisor — keeps desired task count running at all times |
| ALB | Distributes traffic, performs health checks, terminates SSL |
| Target Group | Tells ALB where to send traffic (Fargate task IPs, port 9000) |
| ACM Certificate | Free SSL cert from AWS — attached to ALB HTTPS listener |

---

## Step-by-Step Build Guide

### Step 1 — VPC

**Console path:** VPC → Your VPCs → Create VPC → VPC only

| Field | Value |
|-------|-------|
| Name | `sonarqube-demo-vpc` |
| IPv4 CIDR | `10.0.0.0/16` |
| IPv6 | No |
| Tenancy | Default |

**After creation — enable DNS Hostnames:**
Actions → Edit VPC Settings → Enable DNS hostnames ✅

**Key VPC concepts:**

| Concept | Meaning |
|---------|---------|
| CIDR `10.0.0.0/16` | 65,536 IP addresses available across all subnets |
| DNS Resolution | Resources can resolve AWS service names (e.g. RDS endpoint) |
| DNS Hostnames | Resources get DNS names, not just IPs |
| Tenancy Default | Shared hardware (dedicated = your own hardware, costs more) |
| Main Route Table | Default route table all subnets inherit until reassigned |

> 📸 Screenshot: VPC details page showing State = Available, DNS Hostnames = Enabled

---

### Step 2 — Subnets (all 4 in one create)

**Console path:** VPC → Subnets → Create Subnet → Add New Subnet (x4)

| Name | AZ | CIDR | Type |
|------|----|------|------|
| `sonarqube-public-subnet-1` | us-east-1a | `10.0.1.0/24` | Public |
| `sonarqube-public-subnet-2` | us-east-1b | `10.0.2.0/24` | Public |
| `sonarqube-private-subnet-1` | us-east-1a | `10.0.3.0/24` | Private |
| `sonarqube-private-subnet-2` | us-east-1b | `10.0.4.0/24` | Private |

**Why 2 AZs?**
AWS requires ALB and RDS to span at least 2 Availability Zones for high availability.

**After creation — enable Auto-assign Public IP on public subnets only:**
Select each public subnet → Actions → Edit Subnet Settings → Enable Auto-assign public IPv4 ✅

**CIDR math:**
Each `/24` = 256 addresses. AWS reserves 5, leaving **251 usable** per subnet.

> 📸 Screenshot: Subnets list showing all 4 subnets, correct CIDRs and AZs

---

### Step 3 — Internet Gateway

**Console path:** VPC → Internet Gateways → Create Internet Gateway

| Field | Value |
|-------|-------|
| Name | `sonarqube-igw` |

**Attach after creation:**
Actions → Attach to VPC → `sonarqube-demo-vpc`

> An IGW is not functional until attached. One IGW per VPC.

> 📸 Screenshot: IGW state = Attached

---

### Step 4 — NAT Gateway

**Console path:** VPC → NAT Gateways → Create NAT Gateway

| Field | Value |
|-------|-------|
| Name | `sonarqube-nat-gw` |
| Subnet | `sonarqube-public-subnet-1` (must be public) |
| Connectivity | Public |
| Availability mode | Zonal |
| Elastic IP | Click "Allocate Elastic IP" |

**Why in a public subnet?**
NAT Gateway needs a path to the internet (via IGW). It then proxies outbound traffic for private subnet resources without exposing them inbound.

> NAT Gateway takes 2-3 minutes to become Available.

> 📸 Screenshot: NAT Gateway status = Available

---

### Step 5 — Route Tables

**Console path:** VPC → Route Tables → Create Route Table

**Public Route Table:**

| Field | Value |
|-------|-------|
| Name | `sonarqube-public-rt` |
| VPC | `sonarqube-demo-vpc` |

Add route: `0.0.0.0/0` → Internet Gateway (`sonarqube-igw`)
Associate: `sonarqube-public-subnet-1` and `sonarqube-public-subnet-2`

**Private Route Table:**

| Field | Value |
|-------|-------|
| Name | `sonarqube-private-rt` |
| VPC | `sonarqube-demo-vpc` |

Add route: `0.0.0.0/0` → NAT Gateway (`sonarqube-nat-gw`)
Associate: `sonarqube-private-subnet-1` and `sonarqube-private-subnet-2`

**Route table logic:**

| Destination | Target | Meaning |
|-------------|--------|---------|
| `10.0.0.0/16` | local | All VPC-internal traffic routes locally |
| `0.0.0.0/0` | IGW | Everything else → internet (public subnets) |
| `0.0.0.0/0` | NAT GW | Everything else → NAT proxy (private subnets) |

> 📸 Screenshot: Route table associations showing correct subnets

---

### Step 6 — Security Groups

**Console path:** VPC → Security Groups → Create Security Group

**Traffic flow model:**
Internet → ALB (80/443) → Fargate (9000) → RDS (5432)

#### sonarqube-alb-sg

| Direction | Port | Source | Reason |
|-----------|------|--------|--------|
| Inbound | 80 | `0.0.0.0/0` | Public HTTP |
| Inbound | 443 | `0.0.0.0/0` | Public HTTPS |
| Outbound | All | `0.0.0.0/0` | Default allow all |

#### sonarqube-ecs-sg

| Direction | Port | Source | Reason |
|-----------|------|--------|--------|
| Inbound | 9000 | `sonarqube-alb-sg` | Only ALB can reach container |
| Outbound | All | `0.0.0.0/0` | RDS, ECR, CloudWatch access |

#### sonarqube-rds-sg

| Direction | Port | Source | Reason |
|-----------|------|--------|--------|
| Inbound | 5432 | `sonarqube-ecs-sg` | Only Fargate can reach database |
| Outbound | All | `0.0.0.0/0` | Default |

> Security groups reference each other by ID — no hardcoded IPs needed.

> 📸 Screenshot: Each security group inbound rules

---

### Step 7 — RDS PostgreSQL

**Console path:** RDS → Create Database → Standard create

**Before creating RDS — create DB Subnet Group:**
RDS → Subnet Groups → Create → select both private subnets

| Field | Value |
|-------|-------|
| Engine | PostgreSQL |
| Template | Free tier |
| DB Identifier | `sonarqube-db` |
| Master username | `sonarqube` |
| Instance class | `db.t4g.micro` |
| Storage | 20 GiB gp2 |
| VPC | `sonarqube-demo-vpc` |
| Subnet group | `sonarqube-db-subnet-group` |
| Public access | No |
| Security group | `sonarqube-rds-sg` |
| Initial DB name | `sonarqube` |
| Automated backups | Disabled (demo) |
| Authentication | Password only |

**Save these credentials:**

| Item | Value |
|------|-------|
| Endpoint | `sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com` |
| Port | `5432` |
| Database | `sonarqube` |
| Username | `sonarqube` |

> 📸 Screenshot: RDS instance — Status = Available, endpoint visible

---

### Step 8 — ECS Cluster

**Console path:** ECS → Clusters → Create Cluster

| Field | Value |
|-------|-------|
| Name | `sonarqube-cluster` |
| Infrastructure | Fargate only |

**Error fix — CloudFormation stack conflict:**
If creation fails due to a leftover stack: CloudFormation → Stacks → delete `Infra-ECS-Cluster-sonarqube-cluster-*` → retry.

> 📸 Screenshot: Cluster status = Active, 1 service running

---

### Step 9 — Task Definition

**Console path:** ECS → Task Definitions → Create new

| Field | Value |
|-------|-------|
| Family | `sonarqube-task` |
| Launch type | AWS Fargate |
| OS | Linux/X86_64 |
| CPU | 1 vCPU |
| Memory | 3 GB |
| Task execution role | Create new |

**Container settings:**

| Field | Value |
|-------|-------|
| Name | `sonarqube` |
| Image URI | `sonarqube:community` |
| Port | `9000` TCP/HTTP |
| Read-only root FS | Disabled (SonarQube writes to disk) |

**Environment variables:**

| Key | Value |
|-----|-------|
| `SONAR_JDBC_URL` | `jdbc:postgresql://sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com:5432/sonarqube` |
| `SONAR_JDBC_USERNAME` | `sonarqube` |
| `SONAR_JDBC_PASSWORD` | `<your password>` |

**Health check:**
```
CMD-SHELL, curl -f http://localhost:9000/api/system/status || exit 1
```
Interval: 30s | Timeout: 5s | Start period: 120s | Retries: 3

**Ulimits:**
`nofile` soft: 65536, hard: 65536
(Required for SonarQube's Elasticsearch component)

**Logging:** CloudWatch — enabled

> How to find required env vars: always check the Docker Hub image page → Configuration section.

> 📸 Screenshot: Task definition revision 1 created

---

### Step 10 — Application Load Balancer + Target Group

**Console path:** EC2 → Load Balancers → Create → Application Load Balancer

| Field | Value |
|-------|-------|
| Name | `sonarqube-alb` |
| Scheme | Internet-facing |
| IP type | IPv4 |
| VPC | `sonarqube-demo-vpc` |
| Subnets | Both public subnets |
| Security group | `sonarqube-alb-sg` |

**Target Group (create during ALB setup):**

| Field | Value |
|-------|-------|
| Name | `sonarqube-tg` |
| Target type | IP addresses |
| Protocol | HTTP |
| Port | 9000 |
| VPC | `sonarqube-demo-vpc` |
| Health check path | `/api/system/status` |
| Healthy threshold | 2 |
| Unhealthy threshold | 3 |
| Interval | 30s |
| Success codes | 200 |

> Do not register targets manually — ECS registers Fargate task IPs automatically.

> 📸 Screenshot: ALB status = Active, 2 listeners visible

---

### Step 11 — ECS Service

**Console path:** ECS → Clusters → sonarqube-cluster → Services → Create

| Field | Value |
|-------|-------|
| Task definition | `sonarqube-task:1` |
| Service name | `sonarqube-service` |
| Desired tasks | 1 |
| Subnets | Both private subnets |
| Security group | `sonarqube-ecs-sg` |
| Public IP | Off |
| Load balancer | `sonarqube-alb` |
| Listener | HTTP:80 (existing) |
| Target group | `sonarqube-tg` |
| Health check grace period | 120s |

> Grace period prevents ECS from killing SonarQube before it finishes booting (~2 min).

> 📸 Screenshot: Service showing 1/1 tasks running

---

### Step 12 — SSL Certificate + HTTPS

**ACM:**
Certificate Manager → Request → Public certificate

| Field | Value |
|-------|-------|
| Domains | `menniboefarm.com`, `www.menniboefarm.com` |
| Validation | DNS validation |
| Key algorithm | RSA 2048 |

**Namecheap DNS validation:**
Add 2 CNAME records from ACM into Namecheap Advanced DNS.

**ALB HTTPS listener:**
EC2 → Load Balancers → sonarqube-alb → Listeners → Add Listener

| Field | Value |
|-------|-------|
| Protocol | HTTPS |
| Port | 443 |
| Action | Forward to `sonarqube-tg` |
| Certificate | `menniboefarm.com` (from ACM) |

**HTTP → HTTPS redirect:**
Edit HTTP:80 listener → Change action to Redirect → HTTPS:443 → 301

> 📸 Screenshot: Both listeners — HTTP:80 redirect + HTTPS:443 forward

---

## Key Concepts Reference

### Layered Security Model
```
Internet
   ↓  (80/443)
ALB [sonarqube-alb-sg]
   ↓  (9000)
Fargate Task [sonarqube-ecs-sg]
   ↓  (5432)
RDS PostgreSQL [sonarqube-rds-sg]
```
Each layer only accepts traffic from the layer above it. Nothing bypasses the chain.

### JDBC URL Breakdown
```
jdbc:postgresql://[host]:[port]/[database]
jdbc = Java Database Connectivity protocol
postgresql = database type
host = RDS endpoint DNS name
port = 5432 (PostgreSQL default)
database = sonarqube (initial DB we created)
```

### Why DNS Names Over IPs
RDS IPs change during failover or replacement. DNS names stay constant — AWS updates the mapping automatically. Always use DNS endpoints.

### Fargate vs EC2 — When to Use Each

| Use Fargate | Use EC2 |
|------------|---------|
| Containerized apps | GPU workloads |
| Variable traffic | Persistent local storage |
| No ops team | Full OS control needed |
| Fast deployments | License-based software (per-core) |

---

## Errors & Fixes

| Error | Fix |
|-------|-----|
| ECS cluster creation fails — service linked role | IAM → Roles → check `AWSServiceRoleForECS` exists |
| CloudFormation stack conflict on cluster retry | CloudFormation → delete old stack → retry |
| Namecheap DNS locked to cPanel | Change nameservers to Namecheap BasicDNS first |
| ALB listener port conflict | Switch to "Use existing listener" instead of creating new |
| SonarQube health check failing on first deploy | Increase health check grace period to 120s |

---

## Bookmarked Follow-Up Topics

1. **KMS + Secrets Manager** — Store `SONAR_JDBC_PASSWORD` in Secrets Manager; reference ARN in task definition instead of plain text
2. **SonarQube upgrade on Fargate** — Create new task definition revision with updated image tag → Update service → rolling deployment