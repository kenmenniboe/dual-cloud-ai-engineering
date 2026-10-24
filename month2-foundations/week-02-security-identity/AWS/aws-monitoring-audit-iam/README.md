# AWS Monitoring, Audit, IAM Advanced and Organizations

AWS SAA-C03 Sections 24–25: CloudWatch, EventBridge, CloudTrail, AWS Config, Organizations and SCPs, IAM conditions, policy evaluation, permission boundaries, IAM Identity Center, Directory Service and Control Tower, with four console labs built around the Menniboe Farm order system.

![Day 3 big picture](images/diagrams/00-day3-big-picture.svg)

## What I learned

- **CloudWatch** watches performance: default vs agent metrics, log groups and retention, metric filters (count) vs subscription filters (stream), alarms with recover / scale / notify actions, composite alarms and missing-data handling.
- **EventBridge** reacts to events: schedule vs pattern rules, default / partner / custom buses, archive and replay.
- **CloudTrail** records who did what: 90-day Event history vs trails to S3, management vs data vs Insights events, real-time API alerts through EventBridge.
- **AWS Config** tracks configuration and compliance: detective rules, SSM Automation remediation, and a timeline joined to CloudTrail.
- **Organizations and SCPs** cap whole accounts; **permission boundaries** cap single identities; effective permissions are the overlap, and an explicit deny always wins.
- **Identity Center**, **Directory Service** and **Control Tower** handle sign-in and governance at multi-account scale.

## Lab results

| Lab | Built | Result |
|---|---|---|
| 1 Metric filter → alarm → SNS | Log group, `PaymentFailures` filter, alarm `>= 3 / 1 min`, email topic | 4 log lines → data point **3.0** → ALARM email in ~90 s → back to OK automatically |
| 2 CloudTrail → EventBridge → SNS | Multi-region trail to S3, rule on `AuthorizeSecurityGroupIngress` | Alert with who / what / where in **under 1 minute**; same event found in Event history |
| 3 Config `restricted-ssh` + remediation | Recorder (SGs only), managed rule, least-privilege SSM role | SSH `0.0.0.0/0` flagged **NONCOMPLIANT**, revoked automatically, **COMPLIANT** at re-evaluation |
| 4 Permission boundary | `AdministratorAccess` role capped to S3 + CloudWatch read | S3 allowed; `iam:CreateUser` and `ec2:RunInstances` **implicitly denied by the boundary** in the simulator and live via Switch Role |

## Issues solved

- **Detection gap:** editing an SG rule calls `ModifySecurityGroupRules`, which the EventBridge pattern did not match. Config still caught the open port, and the pattern fix is documented.
- **Audit finding:** CloudTrail Event history showed root-user changes to the default security group.
- Caught before creation: SNS FIFO vs Standard, alarm `>` vs `>=`, missing-data treatment, missing OK notification.
- Console changes: EventBridge rules now live inside event buses; empty event pattern fixed with the JSON editor; Config remediation retries must be 1–25.
- Automatic remediation did not run until a fresh evaluation; a role was created without its boundary and fixed with *Set permissions boundary*.
- Full teardown verified with CLI: every check returned empty.

## Files

| File | Contents |
|---|---|
| [notes.md](notes.md) | 13 module reference sections with diagrams, the CloudWatch / CloudTrail / Config comparison, four labs with console values, screenshots and inline fixes, troubleshooting log, cheat sheet, acronyms |
| [commands.md](commands.md) | Every command by lab, CLI equivalents for a CLI-only redo, teardown and verification |
| `images/diagrams/` | 18 SVG architecture diagrams |
| `images/screenshots/` | 45 redacted lab screenshots |
