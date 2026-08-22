# AWS IAM & CLI — Commands

All CLI commands from this session, grouped by workflow stage. Copy-paste ready — swap `glory_jr` for your own profile/username where relevant.

## CLI Verification

```bash
aws --version
```

## Configuring a Named Profile

```bash
# See what profiles already exist
aws configure list-profiles
cat ~/.aws/credentials
cat ~/.aws/config

# Add a new profile without touching existing ones
aws configure --profile glory_jr
```

## Testing IAM Permissions

```bash
# Confirm authentication and list users
aws iam list-users --profile glory_jr

# Same command, run again after removing the user from Admin_group
# (expected result: Access Denied)
aws iam list-users --profile glory_jr

# Same command, run again after restoring group membership
# (expected result: succeeds, returns user list)
aws iam list-users --profile glory_jr
```

## Profile Management Reference

```bash
# Use a profile for a single command
aws <command> --profile glory_jr

# Or set it as the active profile for a terminal session
export AWS_PROFILE=glory_jr

# Revert to the default profile
unset AWS_PROFILE
```