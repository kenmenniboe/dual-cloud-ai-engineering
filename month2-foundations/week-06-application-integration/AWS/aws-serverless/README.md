# AWS Serverless (SAA-C03) — Lambda, DynamoDB, API Gateway, Cognito, Step Functions

![Lab architecture](diagrams/00-lab-architecture.svg)

## What I learned

Worked through the full **Serverless** section of the AWS Solutions Architect Associate course in 13 modules, then built and tested a real serverless API.

- **Serverless** means AWS runs the servers; I ship code and pay per use. Shared responsibility still applies.
- **Lambda**: 15-minute max, 128 MB–10 GB memory (more memory = more CPU), 1,000 concurrency per Region (a soft quota; my account showed **10**).
- **Concurrency**: reserved concurrency caps *and* guarantees capacity; provisioned concurrency removes cold starts (costs money). Sync callers get **429**; async callers retry up to 6 hours, then DLQ.
- **Lambda in a VPC** needs subnets + security group + ENI, loses internet without NAT, and pairs with **RDS Proxy** for connection pooling.
- **Edge**: CloudFront Functions (JS, viewer only, <1 ms) vs Lambda@Edge (Node/Python, all four hooks, authored in us-east-1).
- **DynamoDB**: tables only, primary key fixed at creation, 400 KB items, on-demand vs provisioned, DAX (reads faster), Streams (writes trigger actions), Global Tables, TTL, PITR, and every restore creates a **new** table.
- **API Gateway**: Lambda / HTTP / AWS service integrations; Edge-optimized, Regional, Private endpoints; 29-second timeout; ACM cert in us-east-1 for edge-optimized.
- **Cognito**: User Pool = ID badge (sign-in, token checked by API Gateway/ALB); Identity Pool = room key (temporary AWS credentials).
- **Step Functions**: visual workflows with Choice, Parallel, Wait, Retry/Catch; Standard (1 year) vs Express (5 min).
- **Architectures**: MyTodoList, MyBlog.com, microservices, and CloudFront offloading of software updates.

## Hands-on result

Built the **Menniboe Farm egg log API**: API Gateway (REST, Regional) → Lambda (Python 3.14, arm64) → DynamoDB (on-demand).

| Check | Result |
|---|---|
| Lambda test before IAM fix | `AccessDeniedException` on `dynamodb:PutItem` (expected) |
| Lambda test after least-privilege inline policy | **201 Created**, item written |
| Cold start report | Init 504 ms, Duration 523 ms, Billed 1028 ms, 98 MB of 128 MB used |
| `POST /eggs` (API Gateway test) | **201**, `south` coop, 9 eggs |
| `GET /dev/eggs` (browser) | Both items returned (`north` 12, `south` 9) |
| CLI cleanup + leftover check | All queries returned `[]` |

![Final GET result](screenshots/28-browser-get-two-items.png)

## Files

- [notes.md](notes.md) — full reference guide, module by module, plus the step-by-step lab redo
- [commands.md](commands.md) — every CLI command, grouped by stage
- [diagrams/](diagrams/) — one architecture diagram per module
- [screenshots/](screenshots/) — console screenshots (account IDs redacted or cropped)

## Areas to revisit

Module 3 (limits), 4A (concurrency), 4B (cold starts), 5A/5B (VPC and RDS), and 10 (Cognito pools).
