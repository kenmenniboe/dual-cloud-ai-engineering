# Day: AWS Account Setup + Billing Alarm

## Topic
Configure AWS Account and Set Billing Alarm + Install AWS CLI

## Course
AWS Networking Fundamentals — Udemy

## Date
2026-06-04

## What I Did
- Signed into AWS as root user
- Created a custom IAM sign-in URL alias
- Enabled IAM user and role access to Billing
- Enabled Billing Alerts in Billing Preferences
- Switched to us-east-1 region
- Created a CloudWatch billing alarm with SNS email notification
- Verified the SNS email subscription
- Installed AWS CLI v2 on macOS

## Key Takeaways
- Billing alarms must be created in **us-east-1** — that's where AWS stores billing metrics
- IAM billing access must be **manually enabled by root** before IAM users can view billing
- **SNS** handles the email notification for CloudWatch alarms
- The alarm won't trigger until you **confirm the SNS subscription email**
- AWS CLI lets you manage AWS resources directly from the terminal

## Lab Folder
`day-aws-account-billing-alarm/`