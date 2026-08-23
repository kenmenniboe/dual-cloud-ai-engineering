# AWS EC2 Fundamentals — Commands

Every CLI command used this session, grouped by stage. Copy-paste ready — swap `<public-ip>` and key filename for your own.

## Key Pair Setup

```bash
# Restrict permissions on the downloaded private key (required before SSH will accept it)
chmod 0400 ec2-fundamentals-demo-key.pem
```

## Connecting to the Instance

```bash
# SSH in as the default Amazon Linux 2 user
ssh -i ec2-fundamentals-demo-key.pem ec2-user@<public-ip>
```

## Testing HTTP / Security Group Behavior

```bash
# Baseline check and post-fix re-check (Phase B)
curl http://<public-ip>

# Same command, run again after deleting the port 80 SG rule —
# expect a hang/timeout, not an error response
curl http://<public-ip>
```

## IAM Role Verification (run on the instance, via SSH or EC2 Instance Connect)

```bash
# Before any role is attached — expect "Unable to locate credentials"
aws iam list-users

# After attaching ec2-fundamentals-demo-role (IAMReadOnlyAccess) — expect real output
aws iam list-users

# After removing the IAMReadOnlyAccess policy from the role — expect Access Denied
aws iam list-users
```

> [!WARNING]
> `aws configure` never appears in this list on purpose — see notes.md, Module 3. Credentials never get typed into an EC2 instance.