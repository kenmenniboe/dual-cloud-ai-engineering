# Commands — AWS Serverless lab

The lab was built in the **console** (steps in [notes.md](notes.md)). These commands were used for **cleanup and verification**, plus the code and JSON pasted during the build.

> [!TIP]
> On macOS zsh, run `setopt interactivecomments` first so pasted `#` comment lines don't error.

## 1. Shell setup

```bash
setopt interactivecomments
REGION=us-east-1
ROLE=MenniboeEggLogger-role-<your-suffix>
API_ID=<your-api-id>
```

## 2. Cleanup

### API Gateway

```bash
aws apigateway delete-rest-api --rest-api-id $API_ID --region $REGION
```

### Lambda function and log group

```bash
aws lambda delete-function --function-name MenniboeEggLogger --region $REGION
aws logs delete-log-group --log-group-name /aws/lambda/MenniboeEggLogger --region $REGION
```

### IAM role (inline policy → managed policy → role)

```bash
aws iam delete-role-policy --role-name $ROLE --policy-name MenniboeEggLogAccess
POLICY_ARN=$(aws iam list-attached-role-policies --role-name $ROLE --query 'AttachedPolicies[0].PolicyArn' --output text)
aws iam detach-role-policy --role-name $ROLE --policy-arn $POLICY_ARN
aws iam delete-policy --policy-arn $POLICY_ARN
aws iam delete-role --role-name $ROLE
```

### DynamoDB table

```bash
aws dynamodb delete-table --table-name MenniboeEggLog --region $REGION --query 'TableDescription.TableStatus'
```

## 3. Leftover check (each should return `[]`)

```bash
aws apigateway get-rest-apis --region $REGION --query "items[?name=='MenniboeEggAPI'].id"
aws lambda list-functions --region $REGION --query "Functions[?FunctionName=='MenniboeEggLogger'].FunctionName"
aws logs describe-log-groups --region $REGION --log-group-name-prefix /aws/lambda/MenniboeEgg --query "logGroups[].logGroupName"
aws iam list-roles --query "Roles[?starts_with(RoleName, 'MenniboeEggLogger')].RoleName"
aws iam list-policies --scope Local --query "Policies[?starts_with(PolicyName, 'AWSLambdaBasicExecutionRole')].PolicyName"
aws dynamodb list-tables --region $REGION --query "TableNames[?@=='MenniboeEggLog']"
aws resourcegroupstaggingapi get-resources --region $REGION --tag-filters Key=Project,Values=menniboe-serverless-lab --query "ResourceTagMappingList[].ResourceARN"
```

## 4. Test and browser checks

```text
GET  https://<api-id>.execute-api.us-east-1.amazonaws.com/dev/eggs
```

Lambda test event `post-eggs`:

```json
{
  "httpMethod": "POST",
  "body": "{\"coop\": \"north\", \"eggs\": 12}"
}
```

API Gateway POST test request body:

```json
{"coop": "south", "eggs": 9}
```

## 5. IAM inline policy (`MenniboeEggLogAccess`)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "MenniboeEggLogAccess",
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem", "dynamodb:Scan"],
      "Resource": "arn:aws:dynamodb:us-east-1:*:table/MenniboeEggLog"
    }
  ]
}
```

## 6. Lambda code (`lambda_function.py`)

```python
import json
import os
import uuid
from datetime import datetime, timezone

import boto3

table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    method = event.get("httpMethod", "POST")

    if method == "GET":
        items = table.scan(Limit=25).get("Items", [])
        return response(200, items)

    body = json.loads(event.get("body") or "{}")
    item = {
        "collection_id": str(uuid.uuid4()),
        "coop": body.get("coop", "main"),
        "eggs": int(body.get("eggs", 0)),
        "collected_at": datetime.now(timezone.utc).isoformat(),
    }
    table.put_item(Item=item)
    return response(201, item)


def response(status, payload):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(payload, default=str),
    }
```

## 7. Git

```bash
git add aws-serverless/
git commit -m "AWS SAA serverless section + Menniboe egg API lab"
git push
```
