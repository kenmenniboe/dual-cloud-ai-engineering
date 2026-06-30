# Notes

## SSM Parameter Store vs Secrets Manager
- Both can encrypt at rest using KMS.
- Parameter Store (SecureString, Standard tier) is free.
- Secrets Manager costs ~$0.40/secret/month + API charges, but adds native
  automatic rotation (e.g. auto-rotating RDS passwords on a schedule).
- For this lab (static demo password, manual rotation acceptable),
  Parameter Store SecureString was the right tradeoff.

## Type vs Data type (easy to mix up in the console)
- **Data type**: text / aws:ec2:image — describes the *format* of the value.
- **Type**: String / StringList / SecureString — describes whether it's
  *encrypted*. This is the field that actually matters for secrets.
  First attempt in this lab accidentally left Type = String (no encryption)
  — caught it by checking the Type column after creation.

## IAM least privilege
- Scoped `ssm:GetParameters` to one parameter ARN, not `ssm:*` or `Resource: *`.
- Reduces blast radius if the execution role's credentials are ever
  compromised — only one parameter exposed, not the whole SSM store.

## ValueFrom vs Value in ECS task definitions
- `Value` = literal plaintext stored directly in the task definition.
- `ValueFrom` = ECS resolves the value at task launch time from SSM
  Parameter Store or Secrets Manager, using the task execution role's
  permissions. Requires `ssm:GetParameters` + `kms:Decrypt` on that role.

## Execution role vs Task role
- **Execution role** (`ecsTaskExecutionRole`): used by ECS/Fargate itself
  to pull the container image, write logs, and resolve secrets.
- **Task role**: used by the application code *inside* the running
  container to call AWS APIs (not used in this task — shows as "-").
- Secrets resolution permissions belong on the **execution** role.

## Failure mode of a bad ValueFrom reference
- Bad ARN, missing IAM permission, or missing KMS access causes the task
  to fail before the container even starts (`ResourceInitializationError`
  in stopped reason). No silent fallback, no leaked plaintext — fails
  loudly and safely.