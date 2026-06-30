# Day - Jun 30 - Securing RDS Credentials with SSM Parameter Store + KMS

## Goal
Remove the plaintext RDS PostgreSQL password from the SonarQube ECS task
definition and replace it with a KMS-encrypted secret pulled at runtime.

## Problem
The Fargate task definition for `sonarqube-task` stored
`SONAR_JDBC_PASSWORD` as a plain `Value` environment variable:

```
SONAR_JDBC_PASSWORD = Sonar1234!
```

This is visible in plaintext to anyone with `ecs:DescribeTaskDefinition`
permission, in the console, in the API response, and in task definition
revision history.

## Solution
1. Store the password as a **SecureString** parameter in SSM Parameter Store
   (KMS-encrypted at rest, using the AWS-managed `alias/aws/ssm` key).
2. Grant the ECS **task execution role** (`ecsTaskExecutionRole`) least-
   privilege IAM permissions to read and decrypt only this one parameter.
3. Update the task definition to use `ValueFrom` (referencing the parameter
   ARN) instead of a plaintext `Value` for `SONAR_JDBC_PASSWORD`.
4. Deploy a new task revision and force a new service deployment.

## Result
- New task revision (`sonarqube-task:2`) launched successfully.
- ECS agent resolved the secret via SSM + KMS before the container started.
- Verified live at menniboefarm.com — app connects to RDS successfully.
- Old plaintext value no longer exists in any active revision.

## Key takeaway
ECS resolves `ValueFrom` secrets *before* the container starts. If the ARN
is wrong or IAM/KMS permissions are missing, the task fails fast with a
`ResourceInitializationError` — it does not start with a missing password
or fall back to anything insecure. This is a safe failure mode.

## Follow-up (not done yet)
Currently using the AWS-managed `alias/aws/ssm` KMS key, which all
principals in the account can use to decrypt. A customer-managed KMS key
with a scoped key policy would tighten this further — left as a future
lab.