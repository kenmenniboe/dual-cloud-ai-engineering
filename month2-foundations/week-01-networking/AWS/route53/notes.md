# Amazon Route 53 — Reference Guide & Lab Redo

> Cert: AWS SAA-C03 · Domain: `menniboefarm.com` · Regions: eu-central-1, us-east-1, ap-southeast-1

## Table of contents

- [Part 1 — Theory](#part-1--theory)
  - [1. DNS fundamentals](#1-dns-fundamentals)
  - [2. Route 53 basics](#2-route-53-basics)
  - [3. TTL](#3-ttl)
  - [4. CNAME vs Alias](#4-cname-vs-alias)
  - [5. Routing policies I — Simple, Weighted, Latency](#5-routing-policies-i--simple-weighted-latency)
  - [6. Health checks](#6-health-checks)
  - [7. Routing policies II — Failover, Geolocation, Geoproximity, IP-based, Multi-value](#7-routing-policies-ii--failover-geolocation-geoproximity-ip-based-multi-value)
  - [8. Registrar vs DNS service & Route 53 Resolver](#8-registrar-vs-dns-service--route-53-resolver)
  - [Routing policy cheat sheet](#routing-policy-cheat-sheet)
  - [Weak-spot review](#weak-spot-review)
- [Part 2 — Hands-on redo guide](#part-2--hands-on-redo-guide)
  - [Final architecture](#final-architecture)
  - [Step 0 — Hosted zone ready](#step-0--hosted-zone-ready)
  - [Step 1 — EC2 in three regions](#step-1--ec2-in-three-regions)
  - [Step 2 — ALB in eu-central-1](#step-2--alb-in-eu-central-1)
  - [Step 3 — First A record + dig/nslookup](#step-3--first-a-record--dignslookup)
  - [Step 4 — TTL demo](#step-4--ttl-demo)
  - [Step 5 — CNAME, Alias, apex error](#step-5--cname-alias-apex-error)
  - [Step 6 — Simple, Weighted, Latency](#step-6--simple-weighted-latency)
  - [Step 7 — Health checks + break one](#step-7--health-checks--break-one)
  - [Step 8 — Failover, Geolocation, Multi-value](#step-8--failover-geolocation-multi-value)
  - [Step 9 — Cleanup](#step-9--cleanup)
- [Errors & fixes index](#errors--fixes-index)
- [Acronyms](#acronyms)
- [Azure anchors](#azure-anchors)

---

# Part 1 — Theory

## 1. DNS fundamentals

**DNS (Domain Name System)** translates human-friendly hostnames (`www.example.com`) into IP addresses. Nothing else in networking works until this step succeeds.

### Name anatomy (read right to left)

```
api.www.example.com.
 │    │     │    │  └─ root (trailing dot, usually hidden)
 │    │     │    └──── TLD (top-level domain): .com
 │    │     └───────── second-level domain: example.com
 │    └─────────────── subdomain: www.example.com
 └──────────────────── FQDN (fully qualified domain name)
```

### How a lookup resolves

| Role | Who runs it | What it knows |
|---|---|---|
| Browser | You | Nothing yet |
| Local DNS server (recursive resolver) | ISP / company | Cached answers only |
| Root server | ICANN | Where each TLD's servers are |
| TLD server (`.com`) | IANA | Which name servers handle each `.com` domain |
| Authoritative server | Route 53 / GoDaddy / etc. | The actual records |

```
Browser ──"example.com?"──▶ Local DNS
   ① ──▶ Root server        ◀── "don't know; .com NS is at 1.2.3.4"
   ② ──▶ .com TLD server    ◀── "example.com NS is at 5.6.7.8"
   ③ ──▶ Route 53 (5.6.7.8) ◀── "A record → 9.10.11.12"
Browser ◀── 9.10.11.12 ─── Local DNS (caches for TTL)
Browser ──HTTP──▶ 9.10.11.12
```

> [!IMPORTANT]
> Only the **last** server has the real answer. Root and TLD hand out **NS referrals**. The local resolver does all the legwork (recursive) and caches the result. DNS never checks whether anything is *listening* at the IP — that is what health checks are for.

### Terminology

| Term | Meaning |
|---|---|
| Domain registrar | Sells / renews the domain name (Amazon Registrar, GoDaddy…) |
| Authoritative DNS | Holds the editable zone file and answers queries for it |
| Recursive resolver | Walks the chain on the client's behalf and caches |
| Zone file | All records for a domain |
| Name server | Server that answers DNS queries |

> [!NOTE]
> **Q I got wrong:** "A DNS service lets a company create/edit/delete its own records — what is it called?" → **Authoritative**, not registrar. A registrar sells the name; it may or may not also host the records.

---

## 2. Route 53 basics

- Highly available, scalable, fully managed, **authoritative** DNS.
- Also a **domain registrar**.
- Only AWS service with a **100% availability SLA**.
- Named after **port 53** (DNS).
- **Hosted zone** = container of records for a domain and its subdomains. $0.50/month each. Domain registration from ~$12/year.

| Hosted zone | Who can query | Example |
|---|---|---|
| Public | Anyone on the internet | `app.mypublicdomain.com` |
| Private | Only inside the associated VPC | `api.example.internal` |

### Every record has five parts

1. Name · 2. Type · 3. Value · 4. Routing policy · 5. TTL

### Must-know record types

| Type | Maps | Example |
|---|---|---|
| A | hostname → IPv4 | `example.com → 1.2.3.4` |
| AAAA | hostname → IPv6 | `example.com → 2001:db8::1` |
| CNAME | hostname → another hostname | `www.example.com → my-alb.amazonaws.com` |
| NS | name servers for the hosted zone | 4 × `awsdns` servers |

A new hosted zone always contains **NS** and **SOA** records — never delete them.

> [!WARNING]
> **CNAME cannot exist at the zone apex** (`example.com` itself). Subdomains only. Route 53 rejects it with `RRSet of type CNAME ... is not permitted at apex`. The fix is an Alias record (section 4).

---

## 3. TTL

**TTL (Time To Live)** = seconds a resolver may cache an answer before asking Route 53 again.

| TTL | Route 53 traffic / cost | Risk |
|---|---|---|
| High (24 h) | Low | Changes take up to 24 h to propagate |
| Low (60 s) | High (billed per query) | Changes propagate fast |

### Safe record-change strategy

1. Lower TTL to ~60 s → **wait the old TTL** so every cache picks it up
2. Change the record value
3. Raise TTL back up

### Reading `dig` output

```
test.menniboefarm.com.  297  IN  A  11.22.33.44
                        ^^^ seconds LEFT in cache, not the configured TTL
```

Run `dig` repeatedly: the number counts down, then resets to the configured TTL with the fresh answer.

> [!NOTE]
> **Q I got wrong:** `dig` shows 120 then 45 — the 45 is the **cache countdown**, not the record's TTL. Alias records are the only records with no user-set TTL.

> [!TIP]
> Alternative: raising TTL is the simplest lever to cut a large Route 53 query bill when records rarely change.

---

## 4. CNAME vs Alias

| | CNAME | Alias |
|---|---|---|
| Points to | Any hostname | AWS resources only |
| Works at zone apex | **No** | **Yes** |
| Record type shown | CNAME | A or AAAA |
| TTL | You set it | Route 53 manages it |
| Query cost | Charged | **Free** |
| Health check | No | Native (Evaluate target health) |
| Follows target IP changes | n/a | Automatic |

**Valid Alias targets:** ELB, CloudFront, API Gateway, Elastic Beanstalk, S3 **websites** (not plain buckets), VPC interface endpoints, Global Accelerator, other Route 53 records in the same zone.

> [!WARNING]
> **Not** a valid Alias target: **EC2 instance DNS name**. Use an A record (ideally with an Elastic IP).

### Decision rule

- Target is an **AWS resource** → **Alias** (always: free, apex-capable, health-aware, follows IPs)
- Target is a **non-AWS hostname** → **CNAME**, subdomain only

> [!IMPORTANT]
> Two rules that are easy to conflate:
> - **CNAME can't live at:** the zone apex
> - **Alias can't point to:** an EC2 DNS name

> [!NOTE]
> Questions I got wrong in this module (1/4): apex → Alias not CNAME; the FALSE Alias statement is "you can set a custom TTL"; CloudFront + "zero query charges" → Alias, not CNAME. Pattern: AWS resource + any bonus requirement = Alias.

---

## 5. Routing policies I — Simple, Weighted, Latency

> [!IMPORTANT]
> A routing policy controls **how Route 53 answers**. Route 53 never carries traffic — it returns an IP and the client connects directly.

**Simple**
- One record, one or more values. Multiple values → client picks one at random.
- **No health checks** → may return a dead IP.
- With Alias, only one AWS resource.

**Weighted**
- Several records, same name and type, each with a weight.
- Share = weight ÷ sum of weights. Need not total 100.
- Weight 0 = stop traffic. All 0 = equal split.
- Supports health checks. Use: canary / blue-green, cross-region balancing.

**Latency**
- Answers with the region giving the user the lowest measured latency (network, not geography).
- Each record is tagged with the AWS region of its resource — Route 53 can't infer region from an IP.
- Supports health checks. A German user *may* be sent to the US if faster.

---

## 6. Health checks

| Type | Monitors | Use |
|---|---|---|
| Endpoint | Public IP or hostname | Public resources |
| Calculated | Other health checks (≤256 children; AND / OR / NOT; "at least N of M") | Single "site up" signal; maintenance without alarms |
| CloudWatch alarm | Alarm state | **Private resources** (VPC-internal, on-prem) |

**Endpoint details**
- 8 checker regions × ~2 checkers ≈ **16** global checkers, IP range **`15.177.x.x`**
- Interval **30 s** standard or **10 s** fast (extra cost); failure threshold default 3
- HTTP / HTTPS / TCP; healthy on **2xx / 3xx** only
- String matching in first **5,120 bytes**
- Healthy if **>18%** of checkers report healthy
- Security group / firewall **must allow the checker IP range** or every probe times out

> [!WARNING]
> "Connection timed out" on a health check while the site loads in your browser = **security group** blocking the checkers.

> [!NOTE]
> **Q I got wrong:** private-subnet EC2 health → **CloudWatch alarm health check**. Checkers live on the public internet and cannot reach a private IP.

---

## 7. Routing policies II — Failover, Geolocation, Geoproximity, IP-based, Multi-value

**Failover**
- Exactly one **primary** + one **secondary**. Primary **must** have a health check.
- Primary unhealthy → Route 53 answers with secondary; fails back automatically. Active-passive DR.

**Geolocation**
- Routes by user location: continent → country → US state (most specific wins).
- **Always create a Default record** — unmatched users otherwise get **no answer**.
- Supports health checks. Use: localization, licensing/content restriction.

| Latency | Geolocation |
|---|---|
| "fastest region" | "user is in country X" |
| measured network performance | physical location |
| German user *might* get US | German user *always* gets the Germany record |

**Geoproximity**
- Location of users **and** resources, with a **bias** (−99…+99) that expands or shrinks a resource's catchment area.
- AWS resources: specify region. Non-AWS: latitude/longitude.
- Requires **Route 53 Traffic Flow**. Exam trigger: "shift traffic from one region to another".

**IP-based**
- Map client **CIDR blocks** → resources. Use: known ISP/corporate ranges, performance or network-cost optimization.

**Multi-value**
- Returns up to **8 healthy** records; client picks. Supports health checks (that's the difference from Simple-with-multiple-values). Client-side load balancing, **not** an ELB replacement.

> [!NOTE]
> Questions I got wrong: Geolocation with no Default → **no answer** (not "nearest region"); a **CIDR** in the question → **IP-based**, not Geolocation.

---

## 8. Registrar vs DNS service & Route 53 Resolver

**Registrar vs DNS service** — separate jobs, often bundled. To keep a domain at GoDaddy but manage DNS in Route 53:
1. Create a **public hosted zone** in Route 53
2. Copy the **4 name servers** from its NS record
3. At the registrar → custom name servers → paste the 4

**Route 53 Resolver** answers EC2 local names, private hosted zones, and public records. For hybrid DNS (needs VPN or Direct Connect):

| Endpoint | Direction (from AWS's view) | Solves |
|---|---|---|
| **Inbound** | On-prem → AWS | On-prem resolves names in private hosted zones |
| **Outbound** | AWS → On-prem | EC2 resolves names on on-prem DNS |

---

## Routing policy cheat sheet

| Trigger phrase | Policy |
|---|---|
| single resource / random pick, no health check | Simple |
| percentages, canary, A/B | Weighted |
| fastest / lowest latency | Latency |
| primary + standby, DR | Failover |
| user's country/continent, localization, licensing | Geolocation |
| shift traffic between regions, bias | Geoproximity |
| known CIDR / IP ranges | IP-based |
| multiple healthy IPs, client-side LB | Multi-value |

## Weak-spot review

Session quiz score: **21 / 30**. Concepts missed at least once:

| Concept | The rule |
|---|---|
| Registrar vs authoritative | Registrar **sells**; authoritative **holds and answers** records |
| CNAME at apex | Never on the bare domain; subdomains only |
| `dig` TTL countdown | Number after the name = seconds **left in cache** |
| Alias facts | apex ✔ · free ✔ · health check ✔ · follows IPs ✔ · **no custom TTL** · **no EC2 target** |
| CNAME vs Alias | AWS resource → Alias; non-AWS hostname → CNAME (subdomain) |
| Private resource health check | CloudWatch alarm |
| Geolocation default | No Default → no answer for unmatched users |
| CIDR in the question | IP-based routing |

---

# Part 2 — Hands-on redo guide

## Final architecture

![Final architecture](images/architecture-diagram.svg)

**Scratch file to keep open during the lab:**

```
eu-central-1  : 51.102.145.124
us-east-1     : 100.59.36.116
ap-southeast-1: 54.251.176.39
ALB DNS       : demoroute53alb-1761828054.eu-central-1.elb.amazonaws.com
```
*(IPs change every redo — replace with yours.)*

---

## Step 0 — Hosted zone ready

**If the domain is registered in Route 53:** Route 53 → Hosted zones → open the domain → confirm **NS** (4 servers) and **SOA** exist.

**If registered elsewhere:**
1. Route 53 → Hosted zones → **Create hosted zone**
   - Domain name: `menniboefarm.com` · Type: **Public hosted zone** · Tags: none → Create
2. Open zone → copy the 4 name servers from the NS record
3. Registrar → Nameservers → **Custom** → paste all 4 → save

**Verify in CloudShell:**

```bash
sudo yum install -y bind-utils
dig NS menniboefarm.com
```

> [!WARNING]
> **Error hit:** `bash: dig: command not found`
> **Fix:** `sudo yum install -y bind-utils`. CloudShell keeps your home directory but **not installed packages** — rerun this in every new session (hit it again in Step 3).

Expected ANSWER SECTION — four `awsdns` servers with TTL `86400` (a round number identical on all four = configured TTL, not a countdown):

```
menniboefarm.com.  86400  IN  NS  ns-1341.awsdns-39.org.
menniboefarm.com.  86400  IN  NS  ns-1606.awsdns-08.co.uk.
menniboefarm.com.  86400  IN  NS  ns-500.awsdns-62.com.
menniboefarm.com.  86400  IN  NS  ns-828.awsdns-39.net.
```

📸 `images/step0-dig-ns.png` — dig NS output

---

## Step 1 — EC2 in three regions

One instance **per region**. Security groups are regional — create a new one in each region.

| Instance | Region |
|---|---|
| `route53-demo-eu` | eu-central-1 (Frankfurt) |
| `route53-demo-us` | us-east-1 (N. Virginia) |
| `route53-demo-ap` | ap-southeast-1 (Singapore) |

**User-data script** (paste into Advanced details → User data):

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

**EC2 → Instances → Launch instances** (repeat per region):

| Section | Field | Value |
|---|---|---|
| Name and tags | Name | `route53-demo-eu` / `-us` / `-ap` |
| Application and OS Images | Quick Start | Amazon Linux |
| | AMI | Amazon Linux 2023 |
| | Architecture | 64-bit (x86) |
| Instance type | Type | `t2.micro` (or `t3.micro`) |
| Key pair | | **Proceed without a key pair** |
| Network settings → Edit | VPC | default |
| | Subnet | No preference |
| | Auto-assign public IP | **Enable** |
| | Firewall | **Create security group** |
| | SG name | `route53-demo-sg` |
| | Description | `HTTP and SSH for Route 53 lab` |
| | Rule 1 | SSH · TCP · 22 · Anywhere 0.0.0.0/0 |
| | Rule 2 (Add rule) | HTTP · TCP · 80 · Anywhere 0.0.0.0/0 |
| Configure storage | | 1 × 8 GiB gp3 (default) |
| Advanced details | everything | default |
| | User data | script above |
| Summary | Number of instances | 1 → **Launch instance** |

**Verify:** wait ~2 min → copy Public IPv4 → open `http://<ip>` (HTTP, not HTTPS).

> [!WARNING]
> **Error hit (first launch):** page showed `Hello World from ip-172-31-38-145.eu-central-1.compute.internal in AZ` — **blank AZ**.
> **Cause:** Amazon Linux 2023 defaults to **IMDSv2**, which requires a session token. The course's original one-line `curl` (IMDSv1) returned nothing.
> **Fix (already applied in the script above):** request a token with `PUT /latest/api/token`, then pass it in the `X-aws-ec2-metadata-token` header.
> **Fix for a running instance:** EC2 → Connect → **EC2 Instance Connect**, then:
> ```bash
> TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
> EC2_AVAIL_ZONE=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)
> echo "<h1>Hello World from $(hostname -f) in AZ $EC2_AVAIL_ZONE</h1>" | sudo tee /var/www/html/index.html
> ```

Expected results:

```
Hello World from ip-172-31-38-145.eu-central-1.compute.internal in AZ eu-central-1b
Hello World from ip-172-31-85-151.ec2.internal in AZ us-east-1b
Hello World from ip-172-31-25-211.ap-southeast-1.compute.internal in AZ ap-southeast-1b
```

> [!NOTE]
> us-east-1 hostnames end in `ec2.internal` while other regions use `<region>.compute.internal` — legacy naming for AWS's oldest region. Nothing to fix.

📸 `images/step1-three-hello-worlds.png`

---

## Step 2 — ALB in eu-central-1

Switch to **Frankfurt**. EC2 → Load Balancers → **Create load balancer** → Application Load Balancer → Create.

| Section | Field | Value |
|---|---|---|
| Basic configuration | Name | `DemoRoute53ALB` |
| | Scheme | Internet-facing |
| | IP address type | IPv4 |
| Network mapping | VPC | default |
| | Mappings | tick all three AZs, default subnets |
| Security groups | | remove default; select `route53-demo-sg` |
| Listeners and routing | Protocol / Port | HTTP / 80 |
| | Default action | **Create target group** ↓ |
| Target group (new tab) | Target type | Instances |
| | Name | `demo-tg-route53` |
| | Protocol / Port | HTTP / 80 |
| | IP address type | IPv4 |
| | VPC | default |
| | Protocol version | HTTP1 |
| | Health checks | HTTP, path `/` (defaults) → Next |
| | Register targets | tick `route53-demo-eu` → **Include as pending below** → Create target group |
| Back in ALB tab | Default action | refresh ↻ → select `demo-tg-route53` |
| Global Accelerator | | unchecked |
| Tags | | none |
| Summary | | **Create load balancer** |

**Verify:** State = Active (2–3 min) → copy DNS name → `http://<alb-dns>` → Hello World from eu-central-1b.

📸 `images/step2-alb-hello-world.png`

---

## Step 3 — First A record + dig/nslookup

Route 53 → Hosted zones → `menniboefarm.com` → **Create record** (Quick create).

| Field | Value |
|---|---|
| Record name | `test` |
| Record type | A – Routes traffic to an IPv4 address |
| Alias | off |
| Value | `11.22.33.44` (deliberately fake) |
| TTL | `300` |
| Routing policy | Simple routing |

```bash
sudo yum install -y bind-utils    # new session → reinstall
nslookup test.menniboefarm.com
dig test.menniboefarm.com
```

> [!WARNING]
> **Error hit:** `bash: nslookup: command not found` — new CloudShell session, packages gone. Reinstall `bind-utils`.

Expected:

```
Non-authoritative answer:            ← nslookup asked the local resolver (127.0.0.11), not Route 53 directly
Name:    test.menniboefarm.com
Address: 11.22.33.44

;; ANSWER SECTION:
test.menniboefarm.com.  297  IN  A  11.22.33.44      ← 297 = cache countdown from 300
```

Browser `http://test.menniboefarm.com` → **fails**. DNS did its job (name → IP); nothing is listening at that IP. DNS never verifies reachability.

> [!TIP]
> "Query it" simply means "ask DNS what this name resolves to." `dig`/`nslookup` show the answer without opening a page; the browser does the same thing silently.

📸 `images/step3-nslookup-dig.png`

---

## Step 4 — TTL demo

1. Select `test` → **Edit record** → Value: **eu-central-1 IP** → Save
2. Run `dig test.menniboefarm.com` repeatedly — old IP returned while the countdown runs
3. When it resets to `300` with the new IP, reload `http://test.menniboefarm.com` → Hello World from eu-central-1b

```
test.menniboefarm.com.  300  IN  A  51.102.145.124   ← fresh answer, TTL reset
```

📸 `images/step4-ttl-reset.png` · `images/step4-test-hello-world.png`

---

## Step 5 — CNAME, Alias, apex error

### 5a — CNAME (subdomain → ALB)

| Field | Value |
|---|---|
| Record name | `myapp` |
| Record type | CNAME |
| Alias | off |
| Value | ALB DNS name |
| TTL / Routing | 300 / Simple |

### 5b — Alias (subdomain → ALB)

| Field | Value |
|---|---|
| Record name | `myalias` |
| Record type | A |
| Alias | **ON** |
| Route traffic to | Alias to Application and Classic Load Balancer |
| Region | Europe (Frankfurt) |
| Load balancer | `DemoRoute53ALB` |
| Routing policy | Simple |
| Evaluate target health | Yes |

> [!NOTE]
> No TTL field appears on an Alias record — Route 53 manages it.

### 5c — CNAME at the apex (expected failure)

Record name **empty** · Type CNAME · Value = ALB DNS name → Create.

> [!WARNING]
> **Error hit (expected):**
> `RRSet of type CNAME with DNS name menniboefarm.com. is not permitted at apex in zone menniboefarm.com.`
> **Fix:** use an Alias A record at the apex (5d). This is the exam's favorite Route 53 trap.

📸 `images/step5-cname-apex-error.png`

### 5d — Alias at the apex

Same as 5b with Record name **empty**. Test `http://menniboefarm.com` → Hello World via ALB.

> [!NOTE]
> The record list shows the value as `dualstack.demoroute53alb-….elb.amazonaws.com.` — Route 53 adds the `dualstack.` prefix so the alias can serve IPv4 and IPv6.

### Compare with dig

```bash
dig myapp.menniboefarm.com
dig myalias.menniboefarm.com
```

```
# CNAME — 3 answers, two hops
myapp.menniboefarm.com.  300  IN  CNAME  demoroute53alb-….elb.amazonaws.com.
demoroute53alb-….          60  IN  A      63.178.32.164
demoroute53alb-….          60  IN  A      3.65.66.242

# Alias — 2 answers, one hop, TTL inherited from the ALB (60)
myalias.menniboefarm.com.  60  IN  A  3.65.66.242
myalias.menniboefarm.com.  60  IN  A  63.178.32.164
```

📸 `images/step5-dig-cname-vs-alias.png` · `images/step5-apex-hello-world.png`

---

## Step 6 — Simple, Weighted, Latency

### 6a — Simple with multiple values

| Field | Value |
|---|---|
| Record name | `simple` |
| Type / Alias | A / off |
| Value | ap-southeast-1 IP |
| TTL | `20` |
| Routing policy | Simple |

Test → Singapore. Then **Edit** → add us-east-1 IP on a second line → Save. After 20 s, `dig simple.menniboefarm.com` returns two A records; browser lands randomly.

### 6b — Weighted (3 records, one create action)

Record name `weighted` · Type A · Routing policy **Weighted** · TTL `3` each · no health check.

| Value | Weight | Record ID |
|---|---|---|
| ap-southeast-1 IP | 10 | `southeast` |
| us-east-1 IP | 70 | `us-east` |
| eu-central-1 IP | 20 | `eu` |

Refresh `http://weighted.menniboefarm.com` ~15× → mostly us-east-1, occasional eu / ap.

### 6c — Latency (3 records)

Record name `latency` · Type A · Routing policy **Latency** · TTL `60`.

| Value | Region | Record ID |
|---|---|---|
| ap-southeast-1 IP | Asia Pacific (Singapore) | `ap-southeast-1` |
| us-east-1 IP | US East (N. Virginia) | `us-east-1` |
| eu-central-1 IP | Europe (Frankfurt) | `eu-central-1` |

> [!IMPORTANT]
> Record name must be **identical** on all three (that makes them one set). **Record ID is required.** The Region dropdown must match where the IP actually lives — Route 53 cannot infer region from an IP.

From CloudShell (us-east-1):

```
latency.menniboefarm.com.  60  IN  A  100.59.36.116   ← single answer, the us-east-1 instance
```

Browser (US) → us-east-1b. To see other regions, use a VPN (course used Canada / Hong Kong).

📸 `images/step6-weighted-table.png` · `images/step6-dig-latency.png`

---

## Step 7 — Health checks + break one

Route 53 → Health checks → **Create health check** ×3 (newer single-page console):

| Field | Value |
|---|---|
| Name | `eu-central-1` / `us-east-1` / `ap-southeast-1` |
| Resource | Endpoint |
| Specify endpoint by | IP address |
| IP address | that region's instance IP |
| Protocol | HTTP (port 80 implied — field only shown for other protocols) |
| Path | `/` or blank |
| Request interval | Standard (30 seconds) |
| Failure threshold | 3 |
| String matching / Latency graphs | off |
| Invert / Disable | unchecked |
| Health checker Regions | leave all 8 ticked |
| Host name / Tags | blank / none |

Wait 1–2 min → all **Healthy**.

### Break Singapore

1. Region → **Asia Pacific (Singapore)** → EC2 → Instances → `route53-demo-ap`
2. **Security** tab → click the SG → **Inbound rules** → **Edit inbound rules**
3. **Delete** the HTTP · TCP · 80 · 0.0.0.0/0 row → **Save rules** (leave SSH)
4. Wait ~2 min (3 × 30 s) → Health checks → `ap-southeast-1` = **Unhealthy**

Health checkers tab shows every checker failing:

```
Asia Pacific (Tokyo)      15.177.42.187   Failure: Connection timed out…
Asia Pacific (Singapore)  15.177.50.109   Failure: Connection timed out…
Asia Pacific (Sydney)     15.177.58.51    Failure: Connection timed out…
```

> [!NOTE]
> Two checkers per region × 8 regions ≈ 16 — the "about 15 checkers" from the course. All from `15.177.x.x`, the range to whitelist if you don't open port 80 to the world.

### Calculated health check

| Field | Value |
|---|---|
| Name | `calculated-all` |
| Resource | Calculated health check |
| Health checks to monitor | tick all three |
| Report healthy when | **all** selected health checks are healthy |

→ **Unhealthy** while Singapore is down. (Edit to "at least 2" to see the maintenance use case flip it Healthy.)

📸 `images/step7-health-checks-one-unhealthy.png` · `images/step7-health-checkers-timeout.png`

---

## Step 8 — Failover, Geolocation, Multi-value

### 8a — Failover

Record name `failover` · Type A · Routing policy **Failover** · TTL `60`.

| Value | Failover record type | Health check | Record ID |
|---|---|---|---|
| eu-central-1 IP | Primary | `eu-central-1` (**required**) | `eu` |
| us-east-1 IP | Secondary | `us-east-1` (optional) | `us` |

Test → eu-central-1b. **Break Frankfurt** (delete HTTP rule on its SG) → wait ~2 min for `eu-central-1` Unhealthy → refresh → **us-east-1b**. Restore the rule → fails back.

### 8b — Geolocation

Record name `geo` · Type A · Routing policy **Geolocation** · TTL `60`.

| Value | Location | Record ID |
|---|---|---|
| ap-southeast-1 IP | Asia (continent) | `asia` |
| us-east-1 IP | United States (country) | `us` |
| eu-central-1 IP | **Default** | `default-eu` |

US client → us-east-1b. Anywhere unlisted (e.g. Mexico) → Default. Without a Default record, unlisted users get no answer.

### 8c — Multi-value

Record name `multi` · Type A · Routing policy **Multivalue answer** · TTL `60` · one record per region, **each with its own health check attached** · Record IDs `us` / `asia` / `eu`.

```bash
dig multi.menniboefarm.com    # Singapore unhealthy → 2 answers
# restore Singapore HTTP rule, wait for Healthy
dig multi.menniboefarm.com    # → 3 answers
```

📸 `images/step8-failover-us-east.png` · `images/step8-dig-multi-2-then-3.png`

---

## Step 9 — Cleanup

1. **Restore** any deleted HTTP rules first
2. Route 53 → Health checks → delete **`calculated-all` first**, then the three endpoint checks

> [!WARNING]
> **Error hit:** `InvalidInput — Health check 0a2789da-… is still referenced from parent health check(s): ed9f128f-…`
> **Fix:** delete the calculated (parent) check before its children. Same dependency ordering as ALB → target group, and as Terraform destroy.

3. Hosted zone → delete lab records: `test`, `myapp`, `myalias`, apex A alias, `simple`, `weighted`, `latency`, `failover`, `geo`, `multi`

> [!IMPORTANT]
> **Keep NS and SOA.** Keep the hosted zone (domain is owned; $0.50/mo). Delete the apex Alias — once the ALB is gone it points at nothing.

4. eu-central-1: delete `DemoRoute53ALB` → delete `demo-tg-route53` → terminate `route53-demo-eu`
5. us-east-1: terminate `route53-demo-us`
6. ap-southeast-1: terminate `route53-demo-ap`
7. Optional: delete the three `route53-demo-sg` groups after instances terminate

---

## Errors & fixes index

| # | Where | Error | Fix |
|---|---|---|---|
| 1 | Step 0 / 3 | `dig` / `nslookup: command not found` | `sudo yum install -y bind-utils` each session |
| 2 | Step 1 | Blank AZ in Hello World (AL2023 IMDSv2) | Token-based metadata calls in user-data; Instance Connect fix for running instance |
| 3 | Step 5c | `CNAME … not permitted at apex` | Alias A record at the apex |
| 4 | Step 7 | Health check "Connection timed out" | Security group blocking checkers (deliberate in the lab) |
| 5 | Step 9 | Health check "still referenced from parent" | Delete calculated parent first |

---

## Acronyms

| Acronym | Meaning |
|---|---|
| DNS | Domain Name System |
| FQDN | Fully Qualified Domain Name |
| TLD | Top-Level Domain (.com, .org…) |
| NS | Name Server (record) |
| SOA | Start of Authority (record) |
| A / AAAA | Address record (IPv4 / IPv6) |
| CNAME | Canonical Name (record) |
| TTL | Time To Live |
| SLA | Service Level Agreement |
| ICANN | Internet Corporation for Assigned Names and Numbers |
| IANA | Internet Assigned Numbers Authority |
| VPC | Virtual Private Cloud |
| ALB / ELB / CLB | Application / Elastic / Classic Load Balancer |
| AZ | Availability Zone |
| SG | Security Group |
| CIDR | Classless Inter-Domain Routing |
| IMDS(v2) | Instance Metadata Service (version 2, token-based) |
| DR | Disaster Recovery |
| RRSet | Resource Record Set |
| IaC | Infrastructure as Code |

## Azure anchors

| Route 53 | Azure |
|---|---|
| Public hosted zone | Azure DNS zone |
| Private hosted zone | Azure Private DNS zone (VNet-linked) |
| Alias record | Azure DNS alias record set |
| Simple / Weighted / Latency | Traffic Manager: record set / Weighted / **Performance** |
| Failover / Geolocation | Traffic Manager: **Priority** / **Geographic** |
| IP-based / Multi-value | Traffic Manager: **Subnet** / **MultiValue** |
| Geoproximity | no direct equivalent |
| Health checks | Traffic Manager endpoint monitoring |
| Resolver inbound/outbound endpoints | Azure DNS Private Resolver inbound/outbound endpoints |