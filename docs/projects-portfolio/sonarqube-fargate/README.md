# SonarQube on AWS Fargate — Lab Summary

**Date:** June 28, 2025
**Duration:** Full session
**Folder:** `sat-jun-28-sonarqube-fargate`

---

## What I Built

Deployed a fully production-style **SonarQube** code quality scanner on **AWS Fargate** — from scratch, using only the AWS Console. Every resource was manually provisioned to understand how each piece connects.

---

## Architecture Overview

| Layer | Resource | Purpose |
|-------|----------|---------|
| Network | VPC, Subnets, IGW, NAT GW, Route Tables | Isolated network foundation |
| Security | 3 Security Groups | Layered firewall rules |
| Database | RDS PostgreSQL (`db.t4g.micro`) | SonarQube data store |
| Compute | ECS Cluster + Fargate Task | Runs SonarQube container |
| Load Balancing | ALB + Target Group | Public entry point, health checks |
| SSL | ACM Certificate + HTTPS Listener | Encrypted traffic |
| DNS | Namecheap CNAME → ALB | Custom domain routing |

---

## Key Outputs

| Output | Value |
|--------|-------|
| SonarQube URL | `https://menniboefarm.com` |
| ALB DNS | `sonarqube-alb-1913243049.us-east-1.elb.amazonaws.com` |
| RDS Endpoint | `sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com` |
| ECS Cluster | `sonarqube-cluster` |
| Region | `us-east-1` |

---

## Why Fargate Over EC2?

| Factor | Fargate | EC2 |
|--------|---------|-----|
| Server management | None — AWS handles it | You patch, scale, maintain |
| Billing | Pay per task CPU/RAM second | Pay per instance hour (even idle) |
| Scaling | Automatic | Manual or Auto Scaling setup |
| Best for | Stateless containerized workloads | Full OS control, persistent workloads |

For SonarQube: Fargate eliminates EC2 overhead, auto-recovers crashed containers, and scales cleanly with demand.

---

## Result

SonarQube Community Edition is live, accessible via HTTPS with a custom domain, backed by a managed PostgreSQL database, and running on serverless Fargate infrastructure. ✅

---


## Screenshot Placeholders

- [ ] SonarQube login page at `https://menniboefarm.com`
- [ ] ECS cluster showing 1 running task
- [ ] RDS instance — Available status
- [ ] ALB listeners — HTTP:80 redirect + HTTPS:443 forward
- [ ] ACM certificate — Issued status