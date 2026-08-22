# AWS Free Tier Credit Challenge

Completed all five "Explore AWS" credit activities on a newly created AWS account (post-July 15, 2025 credit-based Free Tier model), earning the full additional $100 in credits on top of the $100 sign-up credit.

## What I did

| # | Activity | Service configuration |
|---|---|---|
| 1 | AWS Budgets | Zero spend budget — alerts on any spend above $0 |
| 2 | Amazon Bedrock | Ran a prompt against Claude in the Chat/Text playground; completed the one-time Anthropic use-case form |
| 3 | AWS Lambda | Python 3.13 function with a public Function URL, returning rendered HTML |
| 4 | Amazon EC2 | Launched and terminated a `t3.micro` instance (Amazon Linux 2023) |
| 5 | Aurora PostgreSQL | Created via the new Express Configuration flow (GA March 2026); Serverless v2, within the 4-ACU / 1-GiB Free Tier cap |

## Key results

- $100 sign-up credit + $100 activity credit = **$200 total** available on the account
- Confirmed this account draws EC2/RDS usage straight from the credit balance — no separate 750-hrs/month pool like legacy (pre-July 2025) accounts get
- All resources except the Zero spend budget were torn down after verification (Lambda function + its auto-created IAM role, EC2 security group + key pair, Aurora cluster)
- Learned Aurora's storage architecture is fundamentally different from the RDS PostgreSQL setup used in the earlier SonarQube stack — see `notes.md` for the full comparison and diagram

## Files in this folder

- `notes.md` — full mini-tutorial: concepts, step-by-step console walkthroughs, knowledge checks
- `commands.md` — copy-paste-ready code/commands used during the session
- `diagram.svg` — Aurora vs. standard RDS storage architecture comparison