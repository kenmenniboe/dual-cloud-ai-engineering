# Commands — RDS / Aurora / ElastiCache Session

All commands used during the hands-on build, grouped by tool/workflow stage. Copy-paste ready.

## macOS Local Setup — MySQL Client

```bash
# Check if mysql client already exists
mysql --version

# Install client only (not a full local server)
brew install mysql-client

# mysql-client is keg-only — add it to PATH
echo 'export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Verify
mysql --version
```

## Connecting to Aurora (from local machine)

```bash
# Download AWS's TLS certificate bundle (required — Aurora enforces TLS by default)
curl -o global-bundle.pem https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

# Connect to the WRITER endpoint (cluster endpoint, no "-ro-")
mysql -h aurora-demo-cluster.cluster-cudiqo68gvb2.us-east-1.rds.amazonaws.com -P 3306 -u admin -p --ssl-mode=VERIFY_IDENTITY --ssl-ca=./global-bundle.pem

# Connect to the READER endpoint (has "-ro-" in the hostname)
mysql -h aurora-demo-cluster.cluster-ro-cudiqo68gvb2.us-east-1.rds.amazonaws.com -P 3306 -u admin -p --ssl-mode=VERIFY_IDENTITY --ssl-ca=./global-bundle.pem
```

## SQL — Proving Writer/Reader Replication

```sql
-- On the WRITER connection
USE mydb;
CREATE TABLE demo_table (id INT AUTO_INCREMENT PRIMARY KEY, note VARCHAR(50));
INSERT INTO demo_table (note) VALUES ('hello from writer');
SELECT * FROM demo_table;

-- On the READER connection (separate terminal tab)
USE mydb;
SELECT * FROM demo_table;              -- succeeds, shows replicated row

INSERT INTO demo_table (note) VALUES ('trying to write from reader');
-- ERROR 1836 (HY000): Running in read-only mode
```

## EC2 Client Setup (for reaching ElastiCache — VPC-internal only)

```bash
# SSH into the EC2 client instance
ssh -i your-key.pem ec2-user@<ec2-public-ip>

# On the instance — update packages
sudo yum update

# Install a Redis-compatible CLI (binary ends up named redis6-cli, not redis-cli)
sudo dnf install -y redis6

# Confirm which binaries the package actually installed
rpm -ql redis6 | grep bin
```

## Connecting to ElastiCache Redis (from EC2 client, inside the VPC)

```bash
redis6-cli -h demo-redis-cluster.1zare3.ng.0001.use1.cache.amazonaws.com -p 6379
```

## Redis — Lazy Loading & TTL / Session Store Pattern

```
GET user:1001                                    # (nil) — cache miss
SET user:1001 "Kenneth - Cloud AI Engineer"       # simulate writing DB result into cache
GET user:1001                                     # cache hit — instant value
EXPIRE user:1001 30                               # TTL, like a session timeout
GET user:1001                                     # (nil) after 30s — auto-expired
```

## Redis — Sorted Sets (Leaderboard)

```
ZADD leaderboard 1500 "alice"
ZADD leaderboard 2200 "bob"
ZADD leaderboard 1800 "carol"

ZREVRANGE leaderboard 0 -1 WITHSCORES             # highest score first, auto-ranked

ZINCRBY leaderboard 800 "alice"                   # atomic score update

ZREVRANGE leaderboard 0 -1 WITHSCORES             # alice re-ranked automatically

ZREVRANK leaderboard "alice"                      # 0 = first place
```

## Cleanup

```
# Exit redis-cli / mysql sessions
exit
```

> Aurora cluster, ElastiCache cluster, and the EC2 client instance were deleted/terminated via the AWS Console (see `notes.md` for the exact console steps).