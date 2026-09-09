# AWS RDS, Aurora & ElastiCache — SAA Study Session

**Date:** 2026-09-09
**Focus:** AWS Solutions Architect Associate — Relational Database Service (RDS), Amazon Aurora, and ElastiCache

## What I covered

**RDS Fundamentals (Modules 1–4)**
- Managed vs. self-hosted trade-offs, supported engines, Storage Auto Scaling trigger conditions
- Read Replicas (scale reads, async, promotable) vs. Multi-AZ (HA/DR, sync, standby unreadable)
- Automated Backups (5-min PITR, 1–35 day retention) vs. Manual Snapshots (never expire)
- RDS Custom (SSH access, Oracle/SQL Server only) and restore mechanics (always creates a new instance)
- Encryption at rest/in transit, IAM database authentication, RDS Proxy (connection pooling, up to 66% faster failover, IAM auth enforcement)

**Aurora (Modules 5–7)**
- Wire-compatible with MySQL/PostgreSQL, 5x/3x performance, 6-copies-across-3-AZ storage with 4/6 write and 3/6 read quorums
- Writer/Reader Endpoints, Replica Auto-Scaling, Custom Endpoints, Aurora Serverless (ACU-based)
- Global Database (<1s cross-region replication, <1min RTO), Aurora ML integration, Babelfish (T-SQL compatibility), Database Cloning (copy-on-write)

**ElastiCache (Module 8)**
- Redis (HA, replication, durability, Sorted Sets) vs. Memcached (sharding, no HA, no durability)
- Caching strategies: Lazy Loading, Write Through, Session Store (TTL-based)
- Security: Redis AUTH, IAM auth (Redis only), SASL (Memcached only)

Full write-up with real-world/Azure anchors: see [`notes.md`](./notes.md).

## Hands-on build & key outputs

Built and tore down two live environments end-to-end:

**1. Aurora MySQL Cluster** (`aurora-demo-cluster`, 1 writer + 1 reader)
- Connected from local machine via `mysql-client` + TLS to both the Writer and Reader endpoints
- Confirmed replication: a row written on the Writer appeared on the Reader
- Confirmed the reader/writer separation is enforced at the engine level:
  ```
  ERROR 1836 (HY000): Running in read-only mode
  ```

**2. ElastiCache Redis Cluster** (`demo-redis-cluster`, single node, no public access)
- Learned ElastiCache has **no public-access option** (unlike RDS) — had to launch an EC2 client inside the VPC to reach it
- Verified **Lazy Loading**: `GET` → `(nil)` → `SET` → `GET` → cached value
- Verified **TTL-based expiry** (session-store pattern): `EXPIRE key 30` → key auto-vanished after 30s
- Built a live **Sorted Set leaderboard**: `ZADD`, `ZINCRBY` (atomic score update), `ZREVRANGE` (auto-sorted output), `ZREVRANK`
