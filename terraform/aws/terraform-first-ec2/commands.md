# Commands: Terraform Block 1, First EC2 Instance

Every command from this lab, grouped by workflow stage. Run from `dual-cloud-ai-engineering/terraform/aws/terraform-first-ec2/` unless noted.

## 1. Tooling

```bash
# Refresh the HashiCorp tap and upgrade Terraform
brew update
git -C "$(brew --repository hashicorp/tap)" pull
brew upgrade hashicorp/tap/terraform
terraform version

# AWS CLI version
aws --version

# If Homebrew reports Terraform isn't linked
brew link --overwrite hashicorp/tap/terraform
```

## 2. AWS credentials and profiles

```bash
# Store the terraform-lab access key in a named profile
aws configure --profile terraform-lab

# Make sure no leftover variables override the profile
env | grep AWS_

# Confirm which identity a profile resolves to
aws sts get-caller-identity --profile terraform-lab

# Set a missing region on a profile
aws configure set region us-east-1 --profile terraform-lab
aws configure set region us-east-1 --profile success-demo

# Inspect profiles safely (no secrets printed)
cat ~/.aws/config
grep '^\[' ~/.aws/credentials
aws configure list

# Clear overriding environment variables (if any were found)
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
```

## 3. Project setup

```bash
# Project folder and empty main.tf
mkdir -p terraform-first-ec2 && cd terraform-first-ec2 && touch main.tf && code main.tf

# Create the shared Terraform .gitignore in the repo's terraform/ folder
code ../../.gitignore

# Prove .terraform/ is ignored and main.tf / lock file are not
git check-ignore -v .terraform/ .terraform.lock.hcl main.tf
```

## 4. Terraform workflow

```bash
terraform init          # download hashicorp/aws ~> 6.0, write .terraform.lock.hcl
terraform fmt           # format to HashiCorp style
terraform validate      # syntax and schema check, no AWS calls
terraform plan          # preview: Plan: 1 to add
terraform apply         # type yes: creates aws_instance.my_first_ec2
terraform apply         # second run: No changes (idempotence)
terraform destroy       # type yes: Resources: 1 destroyed
```

Optional variants:

```bash
terraform init -upgrade            # move to the newest version allowed by constraints
terraform fmt -check               # CI gate: fail if not formatted
terraform plan -out=tfplan         # save the plan
terraform apply tfplan             # apply exactly the saved plan, no prompt
```

## 5. Verification and teardown

```bash
# Instance state after destroy
aws ec2 describe-instances \
  --instance-ids i-0c3528b067ca05338 \
  --profile terraform-lab \
  --query "Reservations[].Instances[].State.Name" \
  --output text
# terminated

# Access keys left on terraform-lab (run as the admin profile)
aws iam list-access-keys --user-name terraform-lab --profile success-demo
# { "AccessKeyMetadata": [] }
```

## 6. CLI-only equivalents of the console steps

Use these for a CLI-only redo, run with an admin profile (`success-demo`).

```bash
# Step 2: IAM user, policy, tag, access key
aws iam create-user --user-name terraform-lab --tags Key=Project,Value=terraform-block1 --profile success-demo
aws iam attach-user-policy --user-name terraform-lab \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --profile success-demo
aws iam create-access-key --user-name terraform-lab --profile success-demo
# Copy AccessKeyId and SecretAccessKey into: aws configure --profile terraform-lab

# Step 4e: latest Amazon Linux 2023 x86 AMI in us-east-1 (public SSM parameter)
aws ssm get-parameter \
  --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 \
  --query "Parameter.Value" --output text \
  --region us-east-1 --profile success-demo

# Step 7b: instance details
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=first-terraform-ec2" \
  --query "Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Placement.AvailabilityZone]" \
  --output table --profile terraform-lab

# Step 8c: delete the access key (deactivate first, then delete)
aws iam list-access-keys --user-name terraform-lab --profile success-demo
aws iam update-access-key --user-name terraform-lab --access-key-id <ACCESS_KEY_ID> --status Inactive --profile success-demo
aws iam delete-access-key --user-name terraform-lab --access-key-id <ACCESS_KEY_ID> --profile success-demo

# Full user removal (only when Terraform labs are finished)
aws iam detach-user-policy --user-name terraform-lab \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess --profile success-demo
aws iam delete-user --user-name terraform-lab --profile success-demo
```
