# Connecting to Private RDS Outside of Fargate (Bastion Host)

## What I Learned
Today I learned how to securely connect to a **private RDS PostgreSQL instance** (built during the AWS Fargate/SonarQube lab) from my local Mac, even though the database has no public IP and lives in a private subnet.

Core pattern: **Bastion Host** — a small EC2 instance in a public subnet that acts as a secure jump point between my Mac and the private network where RDS lives.

## Key Concepts Covered
- Why RDS should stay in a private subnet (no public IP, no internet route)
- Security Groups as additive, narrowly-scoped trust rules (not exclusive/replacing)
- Why `0.0.0.0/0` on a database port is a critical security risk
- Bastion Host pattern: public subnet + SSH + `.pem` key + SG-to-SG trust
- IAM access keys: why root keys should never be used, even for throwaway demos
- SSM Session Manager as a keyless, portless alternative to a traditional bastion

## Key Outputs / Results
- Launched a `t3.micro` bastion EC2 instance (Amazon Linux 2023) in the existing Fargate lab's public subnet
- Locked bastion SSH access down to my IP only (`My IP` rule, not `0.0.0.0/0`)
- Added a dedicated `bastion-sg` inbound rule to the RDS security group (port 5432), alongside the existing `ecs-tasks-sg` rule
- Successfully SSH'd into the bastion, installed `postgresql15` client via `dnf`
- Successfully connected from the bastion to RDS using `psql` over TLS 1.3
- Confirmed live SonarQube schema visible via `\dt` (`projects`, `issues`, `users`, `quality_gates`, etc.)

## Errors Hit & Fixes
| Error | Cause | Fix |
|---|---|---|
| `Identity file ... not accessible: No such file or directory` | Wrong/forgotten `.pem` path | Used `find ~ -iname "*.pem"` to locate key, moved to `~/.ssh/` |
| `Permission denied (publickey...)` | Used the wrong key pair (mismatched with launched instance) | Confirmed correct key pair name from EC2 console, retried |
| `password authentication failed for user "sonarqube"` | Password typo (no terminal feedback while typing) | Retried `psql` command with correct password |

