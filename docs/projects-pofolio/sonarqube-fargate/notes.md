# SonarQube on AWS Fargate — Notes & Redo Guide

## Table of Contents
- [1. Overview](#1-overview)
- [2. Concepts](#2-concepts)
  - [2.1 Why Fargate Over EC2](#21-why-fargate-over-ec2)
  - [2.2 Why Each Service Was Provisioned](#22-why-each-service-was-provisioned)
  - [2.3 Layered Security Model](#23-layered-security-model)
  - [2.4 JDBC URL Breakdown](#24-jdbc-url-breakdown)
  - [2.5 SonarQube Docker Image — Environment Variables](#25-sonarqube-docker-image--environment-variables)
- [3. Architecture Diagram](#3-architecture-diagram)
- [4. Hands-On Lab (Redo Guide)](#4-hands-on-lab-redo-guide)
  - [4.1 VPC](#41-vpc)
  - [4.2 Subnets](#42-subnets)
  - [4.3 Internet Gateway](#43-internet-gateway)
  - [4.4 NAT Gateway](#44-nat-gateway)
  - [4.5 Route Tables](#45-route-tables)
  - [4.6 Security Groups](#46-security-groups)
  - [4.7 RDS PostgreSQL](#47-rds-postgresql)
  - [4.8 ECS Cluster](#48-ecs-cluster)
  - [4.9 Task Definition](#49-task-definition)
  - [4.10 Application Load Balancer + Target Group](#410-application-load-balancer--target-group)
  - [4.11 ECS Service](#411-ecs-service)
  - [4.12 SSL Certificate + HTTPS](#412-ssl-certificate--https)
- [5. Errors & Fixes](#5-errors--fixes)
- [6. Acronyms](#6-acronyms)

---

## 1. Overview

This lab deployed **SonarQube Community Edition** on **AWS Fargate** from scratch — no wizard shortcuts. Every resource was created manually in the AWS Console to understand how each piece connects. SonarQube is a code quality and security scanning tool that runs as a Java web application backed by a PostgreSQL database.

---

## 2. Concepts

### 2.1 Why Fargate Over EC2

EC2 hosts containers but you manage the server: OS patching, AMI selection, SSH keys, scaling. Fargate removes all of that — you define the container, AWS runs it.

| Factor | Fargate | EC2 |
|---|---|---|
| Server management | None | You patch, scale, maintain |
| Billing | Per CPU/RAM second used | Per instance hour (even idle) |
| Auto-recovery | ECS Service restarts crashed containers | You set up Auto Scaling manually |
| Best for | Stateless containerized workloads | Full OS control, GPU, persistent storage |

For SonarQube specifically: it runs as a single stateless web app backed by RDS — a perfect Fargate fit. No need to manage servers just to run one container.

> [!TIP]
> **AWS anchor:** Fargate is to ECS what Lambda is to functions — you define the workload, AWS handles the infrastructure. The difference is that Fargate runs long-lived containers, not short-lived function invocations.

### 2.2 Why Each Service Was Provisioned

| Service | Why we need it |
|---|---|
| VPC | Isolated private network — nothing is exposed by default |
| Public subnets | Required for ALB (internet-facing) and NAT Gateway |
| Private subnets | Fargate tasks and RDS must never be directly reachable from the internet |
| Internet Gateway | The door between the VPC and the public internet |
| NAT Gateway | Lets private subnet resources reach the internet outbound only — no inbound |
| Route tables | GPS for network traffic — tells packets where to go |
| Security groups | Virtual firewall per resource — stateful, allow-only |
| RDS PostgreSQL | SonarQube requires a relational database; PostgreSQL is its recommended engine |
| ECS Cluster | Groups all Fargate tasks and services together |
| Task Definition | Blueprint: what container to run, how much CPU/RAM, env vars, health check |
| ECS Service | Supervisor — keeps the desired task count running at all times; restarts on crash |
| ALB | Distributes traffic, performs health checks, terminates SSL |
| Target Group | Tells ALB where to forward traffic (Fargate task IPs on port 9000) |
| ACM Certificate | Free SSL cert from AWS — attached to the ALB HTTPS listener |

### 2.3 Layered Security Model

Traffic flows in one direction through each security layer — nothing bypasses the chain:

```
Internet
    ↓  (80 / 443)
ALB  [sonarqube-alb-sg]
    ↓  (9000)
Fargate Task  [sonarqube-ecs-sg]
    ↓  (5432)
RDS PostgreSQL  [sonarqube-rds-sg]
```

Each security group references the one above it as its source — no hardcoded IPs anywhere. If the ALB is replaced, traffic still flows correctly.

> [!IMPORTANT]
> Security groups in AWS are **stateful** — if an inbound rule allows traffic, the response is automatically allowed back out, regardless of outbound rules. This is different from Azure NSGs which can require bidirectional rules in some configurations.

### 2.4 JDBC URL Breakdown

SonarQube connects to its database using a JDBC URL — the standard Java database connection string format:

```
jdbc:postgresql://sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com:5432/sonarqube
│    │            │                                                        │    │
│    │            └── RDS endpoint (DNS name, not IP — stays constant)    │    └── database name
│    └── database engine type                                              └── port
└── Java Database Connectivity protocol
```

**Why DNS name instead of IP?** RDS IPs change during failover or maintenance. The DNS endpoint stays constant — AWS updates the mapping automatically.

### 2.5 SonarQube Docker Image — Environment Variables

> [!TIP]
> **How to know which environment variables to use for any Docker image:** always check the image's **Docker Hub page** → Configuration section. It lists every supported variable and which ones are required. For SonarQube: [hub.docker.com/_/sonarqube](https://hub.docker.com/_/sonarqube)

The three variables SonarQube requires to connect to its database:

| Variable | Purpose |
|---|---|
| `SONAR_JDBC_URL` | Where the database is (full JDBC connection string) |
| `SONAR_JDBC_USERNAME` | Who to log in as |
| `SONAR_JDBC_PASSWORD` | How to prove identity |

> [!WARNING]
> Never store `SONAR_JDBC_PASSWORD` as a plain text environment variable in production. Store it in **AWS Secrets Manager** and reference the secret ARN in the task definition `valueFrom` field instead. See bookmarked follow-up lab #1.

---

## 3. Architecture Diagram

![SonarQube on AWS Fargate Architecture](images/architecture-diagram.svg)

Traffic path: Internet → ALB (public subnets) → Fargate task (private subnets) → RDS PostgreSQL (private subnets). NAT Gateway provides outbound-only internet access for the private subnets (used for ECR image pulls and plugin downloads).

---

## 4. Hands-On Lab (Redo Guide)

### 4.1 VPC

**Console path:** VPC → Your VPCs → Create VPC → **VPC only**

**Basics tab:**

| Field | Value | Note |
|---|---|---|
| Name tag | `sonarqube-demo-vpc` | |
| IPv4 CIDR | `10.0.0.0/16` | 65,536 available addresses |
| IPAM-allocated CIDR | Skip / unchecked | Enterprise IP management feature — not needed |
| IPv6 | No IPv6 | |
| Tenancy | Default | Shared hardware — Dedicated = your own hardware, higher cost |
| VPC encryption control | Disabled | Demo — consider enabling for production |

**After creation — two settings to enable:**

Actions → Edit VPC Settings:
- **DNS resolution** → Enable (already on by default — confirm it)
- **DNS hostnames** → **Enable** (off by default — must be turned on manually)

> [!IMPORTANT]
> DNS hostnames must be enabled for resources to get DNS names instead of just IPs. Without it, your RDS endpoint won't resolve correctly from inside the VPC.

**Key VPC details explained:**

| Field | Meaning |
|---|---|
| VPC ID | Unique AWS identifier — referenced when attaching subnets, security groups, and other resources |
| DNS resolution | Resources can look up other AWS services by DNS name |
| DNS hostnames | Resources get human-readable DNS names, not just raw IPs |
| Main route table | Default route table all subnets inherit until explicitly reassigned |
| Main network ACL | Subnet-level stateless firewall — allows all traffic by default |
| DHCP option set | Auto-assigns IPs to resources at launch — rarely changed |
| Owner ID | Your AWS account ID |

[SCREENSHOT: VPC details — State = Available, DNS Hostnames = Enabled]

---

### 4.2 Subnets

**Console path:** VPC → Subnets → Create Subnet → use **Add new subnet** to create all 4 at once

| Name | AZ | CIDR | Type |
|---|---|---|---|
| `sonarqube-public-subnet-1` | us-east-1a | `10.0.1.0/24` | Public |
| `sonarqube-public-subnet-2` | us-east-1b | `10.0.2.0/24` | Public |
| `sonarqube-private-subnet-1` | us-east-1a | `10.0.3.0/24` | Private |
| `sonarqube-private-subnet-2` | us-east-1b | `10.0.4.0/24` | Private |

**Why 2 AZs?** AWS requires ALB and RDS to span at least 2 Availability Zones. If one data center goes down, your app keeps running.

**CIDR math:** each `/24` = 256 addresses. AWS reserves 5 per subnet, leaving **251 usable**.

**After creation — enable Auto-assign Public IP on public subnets only:**

Select `sonarqube-public-subnet-1` → Actions → Edit Subnet Settings → Enable **Auto-assign public IPv4 address** ✅

Repeat for `sonarqube-public-subnet-2`.

> [!WARNING]
> Do **not** enable auto-assign on private subnets. Fargate tasks and RDS should never receive a public IP directly — they're only reachable through the ALB.

[SCREENSHOT: Subnets list — all 4 with correct CIDRs and AZs]
[SCREENSHOT: Auto-assign IPv4 enabled on both public subnets]

---

### 4.3 Internet Gateway

**Console path:** VPC → Internet Gateways → Create Internet Gateway

| Field | Value |
|---|---|
| Name tag | `sonarqube-igw` |

**Attach after creation:**
Actions → Attach to VPC → select `sonarqube-demo-vpc`

> [!NOTE]
> An IGW is not functional until attached to a VPC. One IGW maximum per VPC. The IGW is what makes a subnet "public" — without it, even subnets with public IPs can't reach the internet.

[SCREENSHOT: IGW — State = Attached, VPC ID showing]

---

### 4.4 NAT Gateway

**Console path:** VPC → NAT Gateways → Create NAT Gateway

| Field | Value | Note |
|---|---|---|
| Name | `sonarqube-nat-gw` | |
| Subnet | `sonarqube-public-subnet-1` | Must be a **public** subnet |
| Connectivity type | Public | |
| Availability mode | Zonal | Regional = multi-AZ, higher cost — not needed for demo |
| Elastic IP | Click **Allocate Elastic IP** | Static public IP required |

**Why in a public subnet?** NAT Gateway needs a path to the internet via the IGW. It proxies outbound requests for private subnet resources without exposing them to inbound traffic.

> [!NOTE]
> NAT Gateway takes 2–3 minutes to reach Available status. The Elastic IP it gets is the source address for all outbound traffic from your private subnets.

[SCREENSHOT: NAT Gateway — Status = Available, Elastic IP assigned]

---

### 4.5 Route Tables

**Console path:** VPC → Route Tables → Create Route Table

**Public route table — `sonarqube-public-rt`:**

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | local | All VPC-internal traffic stays inside |
| `0.0.0.0/0` | `sonarqube-igw` | Everything else → internet via IGW |

After creating, go to **Subnet associations** tab → **Edit subnet associations** → select both public subnets.

**Private route table — `sonarqube-private-rt`:**

| Destination | Target | Meaning |
|---|---|---|
| `10.0.0.0/16` | local | VPC-internal traffic stays local |
| `0.0.0.0/0` | `sonarqube-nat-gw` | Everything else → NAT Gateway (outbound only) |

After creating, associate both private subnets.

> [!IMPORTANT]
> An unassociated route table does nothing. Always confirm subnet associations after creating a route table.

[SCREENSHOT: Public route table — 2 routes, 2 subnet associations]
[SCREENSHOT: Private route table — 2 routes, 2 subnet associations]

---

### 4.6 Security Groups

**Console path:** VPC → Security Groups → Create Security Group

#### sonarqube-alb-sg

| Field | Value |
|---|---|
| Name | `sonarqube-alb-sg` |
| Description | `Security group for SonarQube Load Balancer` |
| VPC | `sonarqube-demo-vpc` |

**Inbound rules:**

| Type | Protocol | Port | Source |
|---|---|---|---|
| HTTP | TCP | 80 | `0.0.0.0/0` |
| HTTPS | TCP | 443 | `0.0.0.0/0` |

**Outbound rules:** leave default (all traffic allowed)

#### sonarqube-ecs-sg

| Field | Value |
|---|---|
| Name | `sonarqube-ecs-sg` |
| Description | `Security group for SonarQube Fargate Tasks` |
| VPC | `sonarqube-demo-vpc` |

**Inbound rules:**

| Type | Protocol | Port | Source |
|---|---|---|---|
| Custom TCP | TCP | 9000 | `sonarqube-alb-sg` |

**Why port 9000?** That is the port SonarQube listens on — baked into the Docker image. Using the security group as source (instead of a CIDR) means only traffic that came through the ALB is allowed.

**Outbound rules:** leave default (Fargate needs to reach RDS, ECR for image pulls, and CloudWatch for logs)

#### sonarqube-rds-sg

| Field | Value |
|---|---|
| Name | `sonarqube-rds-sg` |
| Description | `Security group for SonarQube RDS Database` |
| VPC | `sonarqube-demo-vpc` |

**Inbound rules:**

| Type | Protocol | Port | Source |
|---|---|---|---|
| PostgreSQL | TCP | 5432 | `sonarqube-ecs-sg` |

**Outbound rules:** leave default

[SCREENSHOT: Each security group — inbound rules tab confirmed]

---

### 4.7 RDS PostgreSQL

**Before creating RDS — create a DB Subnet Group first:**

RDS → Subnet Groups → Create DB Subnet Group

| Field | Value |
|---|---|
| Name | `sonarqube-db-subnet-group` |
| Description | `Subnet group for SonarQube RDS` |
| VPC | `sonarqube-demo-vpc` |
| Subnets | Both private subnets |

> [!IMPORTANT]
> Without a DB Subnet Group, your VPC will not appear in the RDS VPC dropdown. Always create the subnet group first.

**Console path:** RDS → Create Database → **Standard create**

**Engine options:**

| Field | Value |
|---|---|
| Engine type | PostgreSQL (not Aurora) |
| Engine version | Latest (PostgreSQL 18.x — SonarQube requires 13 or higher) |

**Templates:**

| Field | Value |
|---|---|
| Template | **Free tier** |

**Settings:**

| Field | Value |
|---|---|
| DB instance identifier | `sonarqube-db` |
| Master username | `sonarqube` |
| Credentials management | Self managed |
| Master password | Choose a secure password — save it |

**Database authentication:**

| Field | Value |
|---|---|
| Authentication | Password authentication |

**Instance configuration:**

| Field | Value |
|---|---|
| DB instance class | `db.t4g.micro` |
| Storage type | General Purpose SSD (gp2) |
| Allocated storage | 20 GiB |

**Connectivity:**

| Field | Value |
|---|---|
| Compute resource | Don't connect to an EC2 compute resource |
| VPC | `sonarqube-demo-vpc` |
| DB subnet group | `sonarqube-db-subnet-group` |
| Public access | **No** |
| VPC security group | `sonarqube-rds-sg` (remove `default` if pre-selected) |
| Availability zone | No preference |
| RDS Proxy | Leave unchecked |
| Certificate authority | Default |

**Monitoring:**

| Field | Value |
|---|---|
| Database Insights | Disable |
| Performance Insights | Disable |
| Enhanced Monitoring | Disable |
| DevOps Guru | Disable |

**Additional configuration:**

| Field | Value |
|---|---|
| Initial database name | `sonarqube` |
| DB parameter group | default |
| Enable encryption | Leave checked (AWS-managed key, free) |
| Enable automated backups | **Disable** for demo |
| Auto minor version upgrade | Leave checked |
| Maintenance window | No preference |
| Enable deletion protection | **Off** for demo |

> [!WARNING]
> The **Initial database name** field is easy to miss — it's buried in Additional Configuration at the bottom. If you skip it, SonarQube will fail on startup because the database it expects (`sonarqube`) won't exist.

**Save these credentials — needed for the task definition:**

| Item | Value |
|---|---|
| Endpoint | `sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com` |
| Port | `5432` |
| Database | `sonarqube` |
| Username | `sonarqube` |

[SCREENSHOT: RDS instance — Status = Available]
[SCREENSHOT: Connectivity & Security tab — endpoint visible, Public accessibility = No]

---

### 4.8 ECS Cluster

**Console path:** ECS → Clusters → Create Cluster

| Field | Value |
|---|---|
| Cluster name | `sonarqube-cluster` |
| Infrastructure | **Fargate only** |
| Monitoring | Leave default |
| Encryption | Leave default |
| Tags | Skip |

**What "Service Connect" is:** optional internal DNS-based service discovery for ECS services calling each other. Not needed here — we only have one service.

[SCREENSHOT: Cluster — Status = Active, 1 service showing]

---

### 4.9 Task Definition

**Console path:** ECS → Task Definitions → Create new task definition

**Task-level settings:**

| Field | Value | Why |
|---|---|---|
| Task definition family | `sonarqube-task` | Name for this blueprint |
| Launch type | AWS Fargate | Serverless — no EC2 |
| Operating system | Linux/X86_64 | SonarQube's Docker image is built for Linux 64-bit |
| CPU | 1 vCPU | Minimum for SonarQube to run comfortably |
| Memory | 3 GB | SonarQube's Elasticsearch component needs ~2 GB alone |
| Task role | None | SonarQube doesn't call any AWS APIs |
| Task execution role | Create new role | Fargate needs permission to pull the Docker image and write to CloudWatch |
| Fault injection | Disabled | Chaos engineering feature — not needed |

**Task role vs. task execution role:**

| Role | Purpose |
|---|---|
| Task role | What your **container** can do in AWS (e.g. call S3, read Secrets Manager) |
| Task execution role | What **Fargate** can do to set up your container (pull image from ECR, write logs to CloudWatch) |

**Container settings:**

| Field | Value | Why |
|---|---|---|
| Container name | `sonarqube` | Label for this container |
| Image URI | `sonarqube:community` | Official free SonarQube image from Docker Hub |
| Port | `9000` TCP / HTTP | SonarQube's default web port |
| Read-only root filesystem | Disabled | SonarQube writes Elasticsearch indexes, logs, and plugin data to disk at runtime |

**Environment variables:**

| Key | Value |
|---|---|
| `SONAR_JDBC_URL` | `jdbc:postgresql://sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com:5432/sonarqube` |
| `SONAR_JDBC_USERNAME` | `sonarqube` |
| `SONAR_JDBC_PASSWORD` | `<your RDS password>` |

**Health check:**

| Field | Value |
|---|---|
| Command | `CMD-SHELL, curl -f http://localhost:9000/api/system/status \|\| exit 1` |
| Interval | 30 seconds |
| Timeout | 5 seconds |
| Start period | **120 seconds** |
| Retries | 3 |

> [!IMPORTANT]
> The **start period** of 120 seconds is critical. SonarQube starts three internal services (Elasticsearch, the web server, and the compute engine) at boot — this takes ~2 minutes. If health checks start before SonarQube is ready, ECS will kill and restart the task in a loop.

**Container timeouts:**

| Field | Value | Why |
|---|---|---|
| Start timeout | 120 seconds | Matches SonarQube's boot time |
| Stop timeout | 30 seconds | Gives SonarQube time to close database connections cleanly before force-kill |

**Ulimits — required for Elasticsearch:**

| Name | Soft limit | Hard limit |
|---|---|---|
| `nofile` | 65536 | 65536 |

> [!WARNING]
> Without the `nofile` ulimit, SonarQube's Elasticsearch component will refuse to start with a "max file descriptors too low" error. This is one of the most common reasons SonarQube fails on containerized platforms.

**Logging:**

| Field | Value |
|---|---|
| Use log collection | Enabled |
| Destination | Amazon CloudWatch |

**Other fields — all leave as default or skip:**
- Resource allocation limits: blank (single container gets all task-level CPU/RAM)
- Restart policy: disabled (let the whole task stop on crash so logs are readable)
- Docker configuration: blank (image has correct entrypoint already)
- Storage: blank (SonarQube data lives in RDS)

[SCREENSHOT: Task definition family sonarqube-task:1 created]
[SCREENSHOT: Container definition — port 9000, environment variables, health check confirmed]

---

### 4.10 Application Load Balancer + Target Group

**Console path:** EC2 → Load Balancers → Create → Application Load Balancer

**Basic configuration:**

| Field | Value |
|---|---|
| Load balancer name | `sonarqube-alb` |
| Scheme | Internet-facing |
| IP address type | IPv4 |

**Network mapping:**

| Field | Value |
|---|---|
| VPC | `sonarqube-demo-vpc` |
| Availability Zones | us-east-1a → `sonarqube-public-subnet-1`, us-east-1b → `sonarqube-public-subnet-2` |

**Security groups:**

| Field | Value |
|---|---|
| Security groups | `sonarqube-alb-sg` (remove `default` if pre-selected) |

**Listeners and routing:**

Click **Create target group** (opens in new tab)

**Target group settings:**

| Field | Value | Why |
|---|---|---|
| Target type | **IP addresses** | Fargate tasks have dynamic IPs — can't target EC2 instances |
| Target group name | `sonarqube-tg` | |
| Protocol | HTTP | SonarQube speaks HTTP internally |
| Port | 9000 | SonarQube's default web port |
| IP address type | IPv4 | |
| VPC | `sonarqube-demo-vpc` | |
| Protocol version | HTTP1 | |

**Health checks:**

| Field | Value |
|---|---|
| Health check protocol | HTTP |
| Health check path | `/api/system/status` |
| Healthy threshold | 2 |
| Unhealthy threshold | 3 |
| Timeout | 5 seconds |
| Interval | 30 seconds |
| Success codes | 200 |

> [!NOTE]
> `/api/system/status` is SonarQube's built-in health endpoint — it returns HTTP 200 only when the application is fully started and healthy, not just when the container is running. This is more reliable than checking `/`.

**Register targets page:** click through without adding any targets — leave the list empty. ECS registers Fargate task IPs automatically when the service starts.

Click **Create target group**, then return to the ALB tab.

**Back on the ALB create page:**
- Listener: HTTP : 80
- Default action: Forward to `sonarqube-tg`

Click **Create load balancer**.

**Save the ALB DNS name — needed for DNS and testing:**
`sonarqube-alb-1913243049.us-east-1.elb.amazonaws.com`

[SCREENSHOT: ALB — Status = Active, DNS name visible]
[SCREENSHOT: Target group — sonarqube-tg, Target type = IP, Health check path = /api/system/status]

---

### 4.11 ECS Service

**Console path:** ECS → Clusters → sonarqube-cluster → Services → Create

**Service details:**

| Field | Value |
|---|---|
| Task definition family | `sonarqube-task` |
| Task definition revision | `1 (latest)` |
| Service name | `sonarqube-service` |
| Environment | AWS Fargate |
| Existing cluster | `sonarqube-cluster` |

**Deployment configuration:**

| Field | Value |
|---|---|
| Scheduling strategy | Replica |
| Desired tasks | 1 |
| Health check grace period | **120 seconds** |

> [!WARNING]
> The **health check grace period** of 120 seconds is the most important setting on this page. Without it, the ALB starts checking `/api/system/status` the moment the task starts — SonarQube isn't ready yet, the checks fail, ECS marks the task unhealthy, kills it, and tries again in a loop. Never hitting a running state.

**Compute configuration:**

| Field | Value |
|---|---|
| Compute options | Capacity provider strategy |
| Capacity provider | FARGATE |
| Platform version | LATEST |

**Networking:**

| Field | Value |
|---|---|
| VPC | `sonarqube-demo-vpc` |
| Subnets | `sonarqube-private-subnet-1` and `sonarqube-private-subnet-2` |
| Security group | `sonarqube-ecs-sg` |
| Public IP | **Turned off** |

**Load balancing:**

| Field | Value |
|---|---|
| Use load balancing | Checked |
| Load balancer type | Application Load Balancer |
| Load balancer | `sonarqube-alb` |
| Listener | **Use an existing listener** → HTTP:80 |
| Target group | **Use an existing target group** → `sonarqube-tg` |

**Skip:** VPC Lattice, Service auto scaling, Volume, Tags

Click **Create service**.

[SCREENSHOT: Service — 1/1 tasks running, deployment = In progress then Complete]

---

### 4.12 SSL Certificate + HTTPS

**Console path:** Certificate Manager → Request → Public certificate

**Domain names:**

| Field | Value |
|---|---|
| Fully qualified domain name | `menniboefarm.com` |
| Add another name | `www.menniboefarm.com` |

**Validation and key:**

| Field | Value |
|---|---|
| Validation method | DNS validation |
| Key algorithm | RSA 2048 |
| Allow export | Disable export |

Click **Request**.

**Add DNS validation records in Namecheap:**

> [!NOTE]
> If Namecheap shows DNS is managed by cPanel/hosting, you must first change nameservers to **Namecheap BasicDNS** under Domain → Nameservers before you can add CNAME records. This disconnects the domain from cPanel hosting.

Go to Namecheap → Advanced DNS → Add New Record (×2):

| Type | Host | Target |
|---|---|---|
| CNAME | `_87f6cf6165b846738d8ca963bc00367c` | `_a4730df5afa623c582f1f9babf51a7c3.jkddzztszm.acm-validations.aws` |
| CNAME | `_f6e839aa03ba26c26c00a9903b2ab3c4.www` | `_40964a1dcd35d174a10f2a39c9060705.jkddzztszm.acm-validations.aws` |

> [!WARNING]
> Remove the trailing `.` from ACM's CNAME values before pasting into Namecheap — Namecheap adds it automatically and will reject or double-apply it if you include it manually.

Wait for certificate status to change from **Pending validation** → **Issued** (5–30 minutes).

**Add HTTPS listener to the ALB:**

EC2 → Load Balancers → sonarqube-alb → Listeners tab → **Add listener**

| Field | Value |
|---|---|
| Protocol | HTTPS |
| Port | 443 |
| Default action | Forward to `sonarqube-tg` |
| Security policy | `ELBSecurityPolicy-TLS13-1-2-Res-PQ-2025-09` (recommended default) |
| Certificate source | From ACM |
| Certificate | `menniboefarm.com` |

**Update HTTP:80 listener to redirect to HTTPS:**

Listeners tab → select HTTP:80 → Manage listener → **Edit listener**

Change default action from *Forward to target group* to **Redirect to URL**:

| Field | Value |
|---|---|
| Protocol | HTTPS |
| Port | 443 |
| Status code | 301 — Permanently moved |

Click **Save changes**.

**Point domain to the ALB (Namecheap Advanced DNS):**

| Type | Host | Target |
|---|---|---|
| CNAME | `@` | `sonarqube-alb-1913243049.us-east-1.elb.amazonaws.com` |

**Final traffic flow:**
```
http://menniboefarm.com
    ↓  301 redirect (HTTP:80 listener)
https://menniboefarm.com
    ↓  HTTPS:443 listener → forward
ALB → Target Group → Fargate task (port 9000)
    ↓
SonarQube responds ✅
```

[SCREENSHOT: ACM certificate — Status = Issued, both domains validated]
[SCREENSHOT: ALB listeners — HTTP:80 redirect + HTTPS:443 forward with certificate]
[SCREENSHOT: SonarQube login page at https://menniboefarm.com]

---

## 5. Errors & Fixes

| Error | Cause | Fix |
|---|---|---|
| ECS cluster creation: `Unable to assume the service linked role` | ECS service linked role doesn't exist in this account yet | IAM → Roles → confirm `AWSServiceRoleForECS` exists; if not, create an ECS role to trigger its creation |
| `A CloudFormation stack already exists for a failed cluster with the same name` | Previous failed cluster attempt left a CloudFormation stack behind | CloudFormation → Stacks → delete `Infra-ECS-Cluster-sonarqube-cluster-*` → retry |
| RDS VPC doesn't appear in the dropdown | No DB Subnet Group exists for the VPC yet | Create DB Subnet Group first (RDS → Subnet Groups) using both private subnets |
| Namecheap DNS records field is locked / can't add records | Domain DNS is managed by cPanel hosting, not Namecheap directly | Domain → change nameservers to Namecheap BasicDNS first |
| ALB listener port conflict on ECS service create | Port 80 listener already exists from when the ALB was created | Switch from "Create new listener" to "Use an existing listener" → select HTTP:80 |
| SonarQube task keeps restarting / never reaches healthy state | ALB health checks start before SonarQube finishes booting | Set health check grace period to 120 seconds on the ECS service |
| `www.menniboefarm.com` stays Pending validation in ACM | CNAME record had wrong format or trailing dot included | Verify Namecheap CNAME Host = `_hash.www` (no trailing dot), Target = full ACM value (no trailing dot) |

---

## 6. Acronyms

| Acronym | Meaning |
|---|---|
| VPC | Virtual Private Cloud — isolated network in AWS |
| IGW | Internet Gateway — connects VPC to the public internet |
| NAT GW | NAT Gateway — outbound-only internet proxy for private subnets |
| AZ | Availability Zone — a physically separate data center within a region |
| SG | Security Group — stateful, allow-only virtual firewall per resource |
| ACL | Access Control List — stateless subnet-level firewall |
| ECS | Elastic Container Service — AWS's container orchestration platform |
| ECR | Elastic Container Registry — AWS's private Docker image registry |
| ALB | Application Load Balancer — HTTP/HTTPS layer 7 load balancer |
| TG | Target Group — set of backend resources the ALB forwards traffic to |
| RDS | Relational Database Service — fully managed database |
| ACM | AWS Certificate Manager — free SSL/TLS certificates for AWS resources |
| JDBC | Java Database Connectivity — standard Java API for connecting to relational databases |
| ARN | Amazon Resource Name — globally unique identifier for any AWS resource |
| CIDR | Classless Inter-Domain Routing — IP address range notation (e.g. `10.0.0.0/16`) |
| CNAME | Canonical Name — a DNS record type that maps one domain name to another |
| SAS | Not applicable (AWS equivalent: pre-signed URL) |
| CPU | Central Processing Unit — in Fargate, measured in vCPU units (1024 = 1 vCPU) |
| RAM | Random Access Memory — in Fargate, specified in MB or GB |