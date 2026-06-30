# Commands / Console Steps

## 1. Create the SecureString parameter
Console: Systems Manager → Parameter Store → Create parameter

```
Name: /sonarqube/db/password
Tier: Standard
Type: SecureString
KMS key source: My current account (alias/aws/ssm)
Value: Sonar1234!
```

CLI equivalent:
```bash
aws ssm put-parameter \
  --name "/sonarqube/db/password" \
  --type "SecureString" \
  --value "Sonar1234!" \
  --key-id "alias/aws/ssm"
```

## 2. IAM inline policy on ecsTaskExecutionRole
Policy name: `SonarDbPasswordReadAccess`

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ReadSonarDbPassword",
      "Effect": "Allow",
      "Action": "ssm:GetParameters",
      "Resource": "arn:aws:ssm:us-east-1:860945038667:parameter/sonarqube/db/password"
    },
    {
      "Sid": "DecryptWithSsmKey",
      "Effect": "Allow",
      "Action": "kms:Decrypt",
      "Resource": "arn:aws:kms:us-east-1:860945038667:key/*"
    }
  ]
}
```

## 3. Update task definition
ECS → Task Definitions → sonarqube-task → Create new revision

Environment variables:
```
SONAR_JDBC_PASSWORD  | valueFrom | arn:aws:ssm:us-east-1:860945038667:parameter/sonarqube/db/password
SONAR_JDBC_URL        | value     | jdbc:postgresql://sonarqube-db.cq58k4e88cql.us-east-1.rds.amazonaws.com:5432/sonarqube
SONAR_JDBC_USERNAME   | value     | sonarqube
```

Result: new revision `sonarqube-task:2` created.

## 4. Deploy
ECS → Clusters → sonarqube-cluster → sonarqube-service → Update service
- Task definition revision: 2
- Force new deployment: checked

## 5. Verify
- ECS → service → Tasks tab → confirm task on `sonarqube-task:2`,
  Last status = Running, Desired status = Running
- Browser: https://menniboefarm.com → SonarQube loads and DB-backed
  features work (login, project list) → confirms password resolved
  correctly and RDS auth succeeded