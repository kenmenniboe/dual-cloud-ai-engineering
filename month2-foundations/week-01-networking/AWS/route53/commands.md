# Route 53 Lab — Commands

All commands were run in **AWS CloudShell (us-east-1)** unless noted.

## 1. CloudShell setup

> Run this first in **every** new CloudShell session — installed packages do not persist across sessions.

```bash
sudo yum install -y bind-utils
```

## 2. EC2 user-data (bootstrap script)

Pasted into **Advanced details → User data** at launch. IMDSv2-aware version (required on Amazon Linux 2023).

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
EC2_AVAIL_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<h1>Hello World from $(hostname -f) in AZ $EC2_AVAIL_ZONE</h1>" > /var/www/html/index.html
```

### Fix for an already-running instance (via EC2 Instance Connect)

```bash
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
EC2_AVAIL_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
echo "<h1>Hello World from $(hostname -f) in AZ $EC2_AVAIL_ZONE</h1>" | sudo tee /var/www/html/index.html
```

## 3. Verify zone delegation

```bash
dig NS menniboefarm.com
```

## 4. Query records

```bash
# First record
nslookup test.menniboefarm.com
dig test.menniboefarm.com

# TTL countdown — run repeatedly and watch the number after the name
dig test.menniboefarm.com

# CNAME vs Alias comparison
dig myapp.menniboefarm.com
dig myalias.menniboefarm.com
dig menniboefarm.com

# Routing policies
dig simple.menniboefarm.com
dig weighted.menniboefarm.com
dig latency.menniboefarm.com
dig failover.menniboefarm.com
dig geo.menniboefarm.com
dig multi.menniboefarm.com
```

## 5. Browser tests (HTTP, not HTTPS)

```text
http://<instance-public-ip>
http://<alb-dns-name>
http://test.menniboefarm.com
http://myapp.menniboefarm.com
http://myalias.menniboefarm.com
http://menniboefarm.com
http://simple.menniboefarm.com
http://weighted.menniboefarm.com
http://latency.menniboefarm.com
http://failover.menniboefarm.com
http://geo.menniboefarm.com
http://multi.menniboefarm.com
```

