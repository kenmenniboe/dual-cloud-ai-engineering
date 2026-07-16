# AWS IAM, SSH Key Pairs & Route 53 DNS

## What I Learned
Set up core AWS account security and DNS fundamentals using the AWS Console.

## Topics Covered
- Created an IAM user with console access and AdministratorAccess policy
- Enabled MFA on IAM user via authenticator app
- Created a monthly cost budget alert ($10 threshold)
- Generated an SSH key pair and stored it securely on macOS
- Configured Route 53 hosted zone and A record

## Key Outputs
- IAM user: `demo-user` with MFA enabled
- Budget alert: $10/month with email notification
- SSH key: `demo-keypair.pem` stored in `~/.ssh/`
- Route 53 hosted zone: `demo.com` with A record pointing to EC2 public IP

## Key Concepts
- Principle of least privilege — IAM users over root account
- MFA = something you know + something you have
- `.pem` files must be stored in `~/.ssh/` with `chmod 400` permissions
- A record maps domain name → IP address
- NS record points to authoritative name servers