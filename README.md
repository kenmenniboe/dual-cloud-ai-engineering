# Cloud Lab Notebook — AWS · Azure · Terraform

Hands-on cloud engineering labs, built in real AWS and Azure accounts and documented step by step.

Every lab folder follows the same layout:

| File | Contents |
|------|----------|
| `README.md` | What was built and the result |
| `notes.md` | Full walkthrough: architecture, console steps, errors hit and how they were fixed |
| `commands.md` | CLI commands, copy-paste ready |
| `images/` | Architecture diagrams and screenshots |

---

## Highlights

| Lab | What it demonstrates |
|-----|----------------------|
| [SonarQube on ECS Fargate](docs/projects-portfolio/sonarqube-fargate) | SonarQube on Fargate with RDS PostgreSQL, ALB, ACM/HTTPS and secrets in SSM + KMS; a controlled upgrade deployment and a health-check bug fix |
| [CloudFront + S3 static site](month2-foundations/week-01-networking/AWS/aws-cloudfront-global-accelerator) | Private S3 origin with Origin Access Control, custom domain via ACM and Route 53, cache invalidation, geo-restriction applied and rolled back |
| [Global Accelerator failover](month2-foundations/week-01-networking/AWS/aws-global-accelerator) | Anycast entry point with health-checked endpoints in two regions; failover and failback tested |
| [Monitoring, audit and auto-remediation](month2-foundations/week-02-security-identity/AWS/aws-monitoring-audit-iam) | CloudWatch metric filter → alarm → SNS; CloudTrail → EventBridge alerts; AWS Config auto-remediation of SSH open to the world; IAM permission boundaries |
| [ECS on Fargate and EC2](month2-foundations/week-06-application-integration/AWS/aws-ecs-fargate-ec2) | Docker image → ECR → ECS service behind an ALB; target-tracking autoscaling under load; EC2 capacity provider; troubleshooting unhealthy targets |
| [Azure Application Gateway](month2-foundations/week-01-networking/Azure/azure-application-gateway) | Layer 7 path-based routing, TLS termination with Key Vault, Web Application Firewall |
| [Disaster recovery with AWS Backup](month2-foundations/week-07-dr-architectures-exam-prep/AWS/aws-dr-migrations-architectures) | CloudFormation stack, Session Manager access with no inbound ports, cross-region backup copy |

---

## Lab index

### Networking — AWS
- [VPC fundamentals](month2-foundations/week-01-networking/AWS/aws-vpc-fundamentals) · [VPC connectivity](month2-foundations/week-01-networking/AWS/aws-vpc-connectivity) · [EC2 networking and resilience](month2-foundations/week-01-networking/AWS/aws-ec2-networking-instance-resilience)
- [ELB + Auto Scaling](month2-foundations/week-01-networking/AWS/aws-elb-asg) · [Route 53](month2-foundations/week-01-networking/AWS/route53) · [RDS via bastion](month2-foundations/week-01-networking/AWS/aws-rds-bastion-access) · [IAM and DNS](month2-foundations/week-01-networking/AWS/aws-iam-dns-demo) · [Account setup and billing](month2-foundations/week-01-networking/AWS/aws-account-setup-billing)

### Networking — Azure
- [VNet peering](month2-foundations/week-01-networking/Azure/vnet-peering) · [Virtual WAN](month2-foundations/week-01-networking/Azure/azure-vwan) · [VPN Gateway site-to-site](month2-foundations/week-01-networking/Azure/azure-vpn-gateway-s2s) · [VPN point-to-site](month2-foundations/week-01-networking/Azure/azure-vpn-p2s)
- [Load Balancer](month2-foundations/week-01-networking/Azure/azure-load-balancer) · [Front Door](month2-foundations/week-01-networking/Azure/azure-front-door) · [Firewall](month2-foundations/week-01-networking/Azure/azure-firewall) · [Route tables](month2-foundations/week-01-networking/Azure/azure-route-table) · [NAT Gateway](month2-foundations/week-01-networking/Azure/azure-public-ip-nat-gateway)
- [Private Endpoint](month2-foundations/week-01-networking/Azure/azure-private-endpoint) · [Service Endpoint](month2-foundations/week-01-networking/Azure/azure-service-endpoint) · [Private DNS](month2-foundations/week-01-networking/Azure/azure-private-dns) · [Bastion](month2-foundations/week-01-networking/Azure/azure-bastion-jumpbox) · [NSGs](month2-foundations/week-01-networking/Azure/azure-nsg-overview) · [VNet with Terraform](month2-foundations/week-01-networking/Azure/terraform-az-vnet)

### Security and identity
- AWS: [IAM](month2-foundations/week-02-security-identity/AWS/aws-iam) · [Encryption, KMS, Secrets Manager, WAF](month2-foundations/week-02-security-identity/AWS/aws-security-encryption) · [EC2 fundamentals](month2-foundations/week-02-security-identity/AWS/aws-ec2-fundamentals)
- Azure: [Entra ID and RBAC](month2-foundations/week-02-security-identity/Azure/azure-entra-id-rbac)

### Storage, databases and analytics
- [S3](month2-foundations/week-03-storage/AWS/aws-s3) · [EC2 storage](month2-foundations/week-03-storage/AWS/ec2-storage) · [Storage Gateway, FSx, DataSync](month2-foundations/week-03-storage/AWS/aws-storage-extras)
- [RDS, Aurora, ElastiCache](month2-foundations/week-05-databases/aws-rds-aurora-elasticache) · [DynamoDB, Glue, Athena](month2-foundations/week-05-databases/aws-databases-analytics-ml)

### Application integration and serverless
- [SQS, SNS, Kinesis, Firehose](month2-foundations/week-06-application-integration/AWS/aws-decoupling-messaging) · [Lambda, API Gateway, DynamoDB](month2-foundations/week-06-application-integration/AWS/aws-serverless)

### Infrastructure as Code
- [Terraform: first EC2 instance](terraform/aws/terraform-first-ec2)

### Linux, web servers and scripting
- [Nginx on CentOS and Ubuntu](docs/projects-portfolio/nginx-centos-ubuntu) · [IIS with SSL](docs/projects-portfolio/windows-server-iis-ssl) · [Azure App Service custom domain](docs/projects-portfolio/azure-app-service-custom-domain) · [Azure Functions](docs/projects-portfolio/azure-functions-http-trigger)
- [Networking fundamentals](month1-foundations) · [Bash scripts](scripts/bash) · [Python](scripts/python) · [Git](git/git-github)

---

## Tools

AWS · Azure · Terraform · Docker · Linux · Bash · Python · Git
