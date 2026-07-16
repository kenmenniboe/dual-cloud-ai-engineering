# Commands: Connecting to Private RDS Outside of Fargate (Bastion Host)

All commands used in this session, copy-paste ready, grouped by workflow stage.

---

## AWS CLI Authentication

```bash
# Check current credentials/identity
aws sts get-caller-identity

# Configure CLI with IAM user access keys
aws configure
```

---

## Discovery (CLI alternative to console steps)

```bash
# Get VPC ID(s)
aws ec2 describe-vpcs --query "Vpcs[*].{ID:VpcId,CIDR:CidrBlock,Tag:Tags}" --output table

# Get subnets for a given VPC (check Public=True for public subnet)
aws ec2 describe-subnets --filters "Name=vpc-id,Values=YOUR_VPC_ID" \
  --query "Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,Public:MapPublicIpOnLaunch}" --output table

# Get RDS endpoint and attached security group
aws rds describe-db-instances --query "DBInstances[*].{Endpoint:Endpoint.Address,Port:Endpoint.Port,SG:VpcSecurityGroups}" --output table
```

---

## Local Key Management (Mac)

```bash
# Locate a .pem file if path is forgotten
find ~ -iname "*.pem" 2>/dev/null

# Check Downloads folder as a fallback
ls -la ~/Downloads/*.pem

# Move key to standard location
mkdir -p ~/.ssh
mv /path/where/you/found/it/bastion-key.pem ~/.ssh/

# Set correct key permissions (required by SSH)
chmod 400 ~/.ssh/bastion-key.pem
```

---

## SSH — Connecting to the Bastion

```bash
ssh -i ~/.ssh/bastion-key.pem ec2-user@<bastion-public-ip>
```

---

## On the Bastion — Installing PostgreSQL Client

```bash
# Amazon Linux 2023 (uses dnf)
sudo dnf install -y postgresql15
```

---

## On the Bastion — Connecting to RDS

```bash
psql -h <rds-endpoint> -U <master-username> -d <database-name> -p 5432
```

Example (structure only, values redacted):
```bash
psql -h sonarqube-db.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com -U sonarqube -d sonarqube -p 5432
```

---

## Inside psql — Verification

```sql
-- List all tables in the connected database
\dt

-- Pager controls (when output is paginated with --More--)
-- space = scroll down, q = quit pager
```

---

## Daily Lab Folder Setup (this session)

```bash
mkdir -p tue-jun-30-rds-bastion-access && touch tue-jun-30-rds-bastion-access/{README.md,notes.md,commands.md}
```