# AWS CloudFront & Global Accelerator

**AWS Certified Solutions Architect – Associate (SAA-C03) · Edge Services**

Full theory walkthrough of Amazon CloudFront and AWS Global Accelerator, followed by a
hands-on lab: a private S3 bucket served globally through CloudFront with Origin Access
Control, then published on a custom domain over HTTPS.

![Architecture diagram](images/architecture-diagram.svg)

---

## What I Learned

**CloudFront (Modules 1–7)**

- A CDN caches content at edge locations so global users get low latency
- Request flow: cache **hit** vs **miss**, and how **TTL** controls freshness
- **Cache invalidation** vs **versioned file names** — when to use each
- **Origins**: S3 with **OAC**, custom HTTP origins, and why the S3 *website* endpoint can't use OAC
- **VPC origins** vs the older public-origin + security-group method
- **Geo restriction** — allow list vs block list, and when to use WAF geo match instead
- **CloudFront vs S3 Cross-Region Replication** — caching vs bucket copying

**Global Accelerator (Modules 8–10)**

- The problem: single-region apps + global users = many public-internet hops
- **Unicast vs Anycast** IP addressing
- 2 static anycast IPs, the AWS private backbone, endpoint groups, health checks, sub-minute failover
- **CloudFront vs Global Accelerator** — the most-tested comparison in this section

**Bonus detour**

- **Stateful (Security Group) vs stateless (NACL)** — and why neither overrides the other

---

## What I Built

```
Users → menniboefarm.com (Route 53 alias)
      → CloudFront distribution (Free plan, TLS via ACM)
      → OAC-signed request
      → PRIVATE S3 bucket (Block Public Access fully ON)
```

| Component | Detail |
|---|---|
| S3 bucket | `menniboe-cdn-lab-kmn-01` · us-east-1 · fully private · 11 objects |
| CloudFront | Free plan · $0/month · default root object `index.html` |
| Security | OAC + bucket policy scoped to one distribution · WAF enabled · TLSv1.2_2021 |
| DNS | Namecheap registrar → Route 53 hosted zone → A + AAAA alias records |
| Certificate | ACM public cert in **us-east-1**, DNS-validated, auto-renewing |

---

## Key Outputs

**OAC bucket policy — written automatically by CloudFront**

```json
{
  "Sid": "AllowCloudFrontServicePrincipal",
  "Effect": "Allow",
  "Principal": { "Service": "cloudfront.amazonaws.com" },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::menniboe-cdn-lab-kmn-01/*",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:cloudfront::<ACCOUNT_ID>:distribution/<DISTRIBUTION_ID>"
    }
  }
}
```

**The bucket stayed private the whole time**

```
"BlockPublicAcls": true,  "IgnorePublicAcls": true,
"BlockPublicPolicy": true, "RestrictPublicBuckets": true
```

**Cache behaviour proven on the wire**

| Check | Result |
|---|---|
| First request | `x-cache: Miss from cloudfront` |
| Second request | `x-cache: Hit from cloudfront`, `age: 12` |
| After editing S3, before invalidation | old content, `age: 690` |
| After invalidation | new content, `age: 1` |

**Geo restriction proven live**

| State | Result |
|---|---|
| `RestrictionType: blacklist`, `Items: ["US","CN"]` | `HTTP status: 403` — *"configured to block access from your country"* |
| Reverted to `none` | `HTTP status: 200` |

**Custom domain live**

```
https://menniboefarm.com/       → 200
https://www.menniboefarm.com/   → 200
http://menniboefarm.com/        → 301 Moved Permanently (Server: CloudFront)
```

---

## Results Snapshot

**Before — pre-signed S3 URL: the HTML renders, every image is broken**

![Pre-signed URL with broken images](screenshots/05-presigned-broken-images.png)

**After — the same page through CloudFront, bucket still fully private**

![Full page served through CloudFront](screenshots/13c-cloudfront-working.png)

**Geo restriction proven by locking myself out**

![CloudFront 403 blocking my own country](screenshots/22a-geo-blocked-403-browser.png)

**Live on the custom domain over HTTPS**

![Site live on the custom domain](screenshots/29a-custom-domain-live.png)

- Direct S3 object URL → **403 AccessDenied** before *and* after CloudFront was working
- Pre-signed S3 URL rendered the HTML but **every image stayed broken** — proof each object is separately private
- Same page through CloudFront → **all 10 images rendered**, bucket unchanged
- Bare distribution domain went from **403 → 200** after setting the default root object
- Geo block on my own country returned a **CloudFront-generated HTML 403**, distinct from S3's **XML 403**

---

## Findings the Course Video Didn't Cover

| Finding | Detail |
|---|---|
| Geo restriction moved | No longer in the console **Security** tab on the Free plan — had to use the CLI |
| API vs console wording | API uses `blacklist` / `whitelist`; console says block list / allow list |
| WAF now included | Free plan includes WAF at no extra charge (video had to skip it for cost) |
| Plan-gated features | **VPC origin** and **L7 DDoS** require the Business plan; **cache tags** require Pro |
| Route-domains shortcut | CloudFront's *"Route domains to CloudFront"* button creates the **apex only** — `www` must be added manually |
| Edge nodes disagree | A GET and a HEAD seconds apart returned different cached versions — an edge location is a cluster, not one server |

---

## Files

| File | Contents |
|---|---|
| `README.md` | This summary |
| `notes.md` | Full reference guide — theory, acronyms, copy-paste redo guide, errors and fixes |
| `commands.md` | Every CLI command, grouped by workflow stage |
| `images/architecture-diagram.svg` | Final architecture diagram |
| `screenshots/` | 46 lab screenshots, embedded inline in `notes.md` at the step where each was taken |

> All screenshots have been machine-redacted: AWS account ID, local username and hostname are
> blacked out. Exported config files (`dist-config*.json`) are gitignored because they contain
> the account ID.

---
