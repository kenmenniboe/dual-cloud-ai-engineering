# AWS S3 — Fundamentals to Advanced (AWS SAA)

**Dates:** September 15–18, 2026
**Source material:** Amazon S3 — Introduction, Advanced S3, S3 Security (3 lecture sets)
**Cert alignment:** AWS SAA

## What I covered

A 10-module, Socratic-style tutoring pass across the full S3 exam domain, followed by an 8-step hands-on lab in the AWS Console.

| # | Module |
|---|---|
| 1 | Fundamentals — buckets, objects, keys |
| 2 | Security — IAM vs bucket policies, Block Public Access, static website hosting |
| 3 | Versioning & MFA Delete |
| 4 | Replication (CRR / SRR) |
| 5 | Storage Classes, Lifecycle Rules, Express One Zone, Requester Pays |
| 6 | Encryption — SSE-S3, SSE-KMS, SSE-C, client-side, in-transit |
| 7 | Event Notifications, EventBridge, Batch Operations |
| 8 | Performance & Storage Lens |
| 9 | CORS, Pre-signed URLs, Access Logs |
| 10 | Object Lock, Glacier Vault Lock, Access Points, Object Lambda |

## Key outputs / results

- Built a General Purpose bucket via the **Account Regional namespace** with versioning enabled at creation
- Confirmed S3 has no real "folders" — proved it by overwriting `intro.sh`, watching versions stack, deleting the current version (delete marker only), then deleting the marker to restore the file
- Attached a public bucket policy (`Principal: "*"`, `s3:GetObject`, `/*` resource) after first disabling Block Public Access — hit and fixed a missing `Principal` field and a missing `/*` on the Resource ARN
- Enabled static website hosting; tested a live rollback by uploading a new `index.html` version and then deleting it to instantly revert the public site with zero downtime
- Confirmed SSE-S3 is the bucket default, then overrode one object to SSE-KMS — confirmed the override created a **new version** rather than rewriting history
- Built a lifecycle rule (Standard → Standard-IA @ 30d → Glacier Flexible Retrieval @ 90d → Expire @ 365d) — hit and fixed a missing cost-acknowledgment checkbox and a blank "days" field on an unused noncurrent-version transition
- Generated a pre-signed URL, confirmed it worked (rendered a `.png` inline, downloaded a `.sh` file), and confirmed it failed after the 5-minute expiry
- Enabled server access logging to a separate, same-region logging bucket

## Full reference

- [`notes.md`](notes.md) — full tutorial, acronym glossary, copy-paste redo guide with every error/fix inline, architecture diagram
- [`commands.md`](commands.md) — CLI reference (session itself was Console-only; equivalents included for future use)