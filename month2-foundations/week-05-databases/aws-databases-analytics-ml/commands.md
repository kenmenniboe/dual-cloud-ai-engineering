# Commands: Databases, Data and Analytics, ML (SAA-C03 Sections 21–23)

All commands run in **AWS CloudShell** (us-east-1). Both labs were built in the console. The commands under **Session commands** are the ones run during the labs, and the **CLI equivalents** sections rebuild the same resources from the CLI for a redo.

## Contents

- [CloudShell utilities](#cloudshell-utilities)
- [DynamoDB](#dynamodb)
- [S3 data lake](#s3-data-lake)
- [Glue](#glue)
- [Athena](#athena)
- [Teardown verification](#teardown-verification)
- [IAM cleanup](#iam-cleanup)
- [Zsh vs bash fixes](#zsh-vs-bash-fixes)

---

## CloudShell utilities

```bash
# Unix epoch timestamp 10 minutes from now (for DynamoDB TTL)
date -d '+10 minutes' +%s

# Check which shell CloudShell is running
echo $0
```

---

## DynamoDB

### Session commands

```bash
# Verify the table is gone after deletion
aws dynamodb describe-table --table-name menniboe-farm-orders
```

### CLI equivalents (Lab 1 redo)

```bash
# Create the table: partition key customerId, sort key orderDate, on-demand
aws dynamodb create-table \
  --table-name menniboe-farm-orders \
  --attribute-definitions AttributeName=customerId,AttributeType=S AttributeName=orderDate,AttributeType=S \
  --key-schema AttributeName=customerId,KeyType=HASH AttributeName=orderDate,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --tags Key=Project,Value=SAA-Day2

aws dynamodb wait table-exists --table-name menniboe-farm-orders

# Add the three items (DynamoDB JSON: S = string, N = number)
aws dynamodb put-item --table-name menniboe-farm-orders --item \
  '{"customerId":{"S":"C001"},"orderDate":{"S":"2026-10-01"},"product":{"S":"heirloom tomatoes"},"qty":{"N":"5"},"total":{"N":"22.50"}}'
aws dynamodb put-item --table-name menniboe-farm-orders --item \
  '{"customerId":{"S":"C001"},"orderDate":{"S":"2026-10-15"},"product":{"S":"organic peppers"},"qty":{"N":"3"},"total":{"N":"9.00"}}'
aws dynamodb put-item --table-name menniboe-farm-orders --item \
  '{"customerId":{"S":"C002"},"orderDate":{"S":"2026-10-10"},"product":{"S":"sweet corn"},"qty":{"N":"12"},"total":{"N":"18.00"}}'

# Query: one partition, sort key begins with 2026-10
aws dynamodb query --table-name menniboe-farm-orders \
  --key-condition-expression "customerId = :c AND begins_with(orderDate, :m)" \
  --expression-attribute-values '{":c":{"S":"C001"},":m":{"S":"2026-10"}}' \
  --return-consumed-capacity TOTAL

# Scan with a filter: reads every item, returns matches
aws dynamodb scan --table-name menniboe-farm-orders \
  --filter-expression "product = :p" \
  --expression-attribute-values '{":p":{"S":"sweet corn"}}' \
  --return-consumed-capacity TOTAL

# Add a TTL attribute (Number, epoch seconds) to C002
EXP=$(date -d '+10 minutes' +%s)
aws dynamodb update-item --table-name menniboe-farm-orders \
  --key '{"customerId":{"S":"C002"},"orderDate":{"S":"2026-10-10"}}' \
  --update-expression "SET expiresAt = :e" \
  --expression-attribute-values "{\":e\":{\"N\":\"$EXP\"}}"

# Turn on TTL and check its status
aws dynamodb update-time-to-live --table-name menniboe-farm-orders \
  --time-to-live-specification "Enabled=true, AttributeName=expiresAt"
aws dynamodb describe-time-to-live --table-name menniboe-farm-orders

# Teardown
aws dynamodb delete-table --table-name menniboe-farm-orders
```

---

## S3 data lake

### Session commands

```bash
mkdir -p ~/lab2 && cd ~/lab2

cat > sales-09.csv <<'EOF'
order_id,product,quantity,price
901,heirloom tomatoes,4,4.50
902,sweet corn,10,1.50
903,organic peppers,2,3.00
EOF

cat > sales-10.csv <<'EOF'
order_id,product,quantity,price
1001,heirloom tomatoes,5,4.50
1002,organic peppers,3,3.00
1003,sweet corn,12,1.50
EOF

# Upload into Hive-style partition prefixes
aws s3 cp sales-09.csv s3://menniboe-sales-lake-lab/sales/year=2026/month=09/sales.csv
aws s3 cp sales-10.csv s3://menniboe-sales-lake-lab/sales/year=2026/month=10/sales.csv

# List everything in the data bucket
aws s3 ls s3://menniboe-sales-lake-lab/ --recursive
```

### CLI equivalents (bucket creation and teardown)

```bash
aws s3 mb s3://menniboe-sales-lake-lab --region us-east-1
aws s3 mb s3://menniboe-athena-results-lab --region us-east-1
aws s3api put-bucket-tagging --bucket menniboe-sales-lake-lab --tagging 'TagSet=[{Key=Project,Value=SAA-Day2}]'
aws s3api put-bucket-tagging --bucket menniboe-athena-results-lab --tagging 'TagSet=[{Key=Project,Value=SAA-Day2}]'

# Teardown: empty and delete in one command
aws s3 rb s3://menniboe-sales-lake-lab --force
aws s3 rb s3://menniboe-athena-results-lab --force
```

---

## Glue

### CLI equivalents (Lab 2 redo)

```bash
# Database
aws glue create-database --database-input '{"Name":"menniboe_sales_db","Description":"Day 2 farm sales data lake"}'

# Crawler IAM role: trust policy for the Glue service
cat > glue-trust.json <<'EOF'
{ "Version": "2012-10-17",
  "Statement": [{ "Effect": "Allow", "Principal": { "Service": "glue.amazonaws.com" }, "Action": "sts:AssumeRole" }] }
EOF
aws iam create-role --role-name AWSGlueServiceRole-menniboe --assume-role-policy-document file://glue-trust.json
aws iam attach-role-policy --role-name AWSGlueServiceRole-menniboe \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole

# Least-privilege S3 read on the sales/ prefix (inline policy)
cat > glue-s3.json <<'EOF'
{ "Version": "2012-10-17",
  "Statement": [
    { "Effect": "Allow", "Action": "s3:ListBucket", "Resource": "arn:aws:s3:::menniboe-sales-lake-lab" },
    { "Effect": "Allow", "Action": "s3:GetObject", "Resource": "arn:aws:s3:::menniboe-sales-lake-lab/sales/*" } ] }
EOF
aws iam put-role-policy --role-name AWSGlueServiceRole-menniboe --policy-name sales-read --policy-document file://glue-s3.json

# Crawler pointed at sales/ (not the bucket root)
aws glue create-crawler --name menniboe-sales-crawler \
  --role AWSGlueServiceRole-menniboe \
  --database-name menniboe_sales_db \
  --targets '{"S3Targets":[{"Path":"s3://menniboe-sales-lake-lab/sales/"}]}' \
  --tags Project=SAA-Day2

aws glue start-crawler --name menniboe-sales-crawler
aws glue get-crawler --name menniboe-sales-crawler --query 'Crawler.{State:State,LastRun:LastCrawl.Status}'

# Inspect the table and partitions
aws glue get-table --database-name menniboe_sales_db --name sales \
  --query 'Table.{Columns:StorageDescriptor.Columns,Partitions:PartitionKeys,Location:StorageDescriptor.Location}'
aws glue get-partitions --database-name menniboe_sales_db --table-name sales --query 'Partitions[].Values'

# Teardown
aws glue delete-crawler --name menniboe-sales-crawler
aws glue delete-database --name menniboe_sales_db
```

---

## Athena

### SQL run in the query editor

```sql
-- Read everything (scans all partitions)
SELECT * FROM sales;

-- Same query the Glue "Table data" link generates (fully qualified name)
SELECT * FROM "menniboe_sales_db"."sales" limit 10;

-- One partition only (partition pruning); partitions are strings, so quote them
SELECT product,
       SUM(quantity)         AS total_qty,
       SUM(quantity * price) AS revenue
FROM sales
WHERE year = '2026' AND month = '10'
GROUP BY product
ORDER BY revenue DESC;
```

### CLI equivalents

```bash
# Set the result location on the workgroup (durable, unlike the console's Query settings)
aws athena update-work-group --work-group primary \
  --configuration-updates 'ResultConfigurationUpdates={OutputLocation=s3://menniboe-athena-results-lab/}'

# Run a query and read its stats and results
QID=$(aws athena start-query-execution --work-group primary \
  --query-execution-context Database=menniboe_sales_db \
  --query-string "SELECT * FROM sales" --query 'QueryExecutionId' --output text)

aws athena get-query-execution --query-execution-id "$QID" \
  --query 'QueryExecution.{State:Status.State,BytesScanned:Statistics.DataScannedInBytes,Output:ResultConfiguration.OutputLocation}'
aws athena get-query-results --query-execution-id "$QID"
```

---

## Teardown verification

```bash
aws s3 ls | grep menniboe                                        # no output = buckets gone
aws glue get-crawler --name menniboe-sales-crawler               # EntityNotFoundException
aws glue get-database --name menniboe_sales_db                   # EntityNotFoundException
aws dynamodb describe-table --table-name menniboe-farm-orders    # ResourceNotFoundException
aws iam get-role --role-name AWSGlueServiceRole-menniboe --query 'Role.Arn'   # NoSuchEntity once deleted
```

---

## IAM cleanup

Deletes the wizard-created lab roles and their leftover customer-managed policies. Service-linked roles (`AWSServiceRoleFor…`) and `ecsTaskExecutionRole` are excluded. **These deletions can't be undone; preview first.**

```bash
setopt nobanghist 2>/dev/null   # zsh: stop "!" history expansion (harmless in bash)

# 1. Preview the roles to delete
ROLES=$(aws iam list-roles --query "Roles[?starts_with(RoleName,'AWSGlueServiceRole-menniboe') || starts_with(RoleName,'KinesisFirehoseServiceRole-menniboe') || starts_with(RoleName,'hello-lambda-webapp-role') || starts_with(RoleName,'StorageGatewayBucketAccessRole')].RoleName" --output text)
echo "$ROLES" | tr '\t' '\n'

# 2. Delete a role: detach managed policies, delete inline policies, remove from instance profiles, delete
delete_role() {
  R="$1"; echo "== $R"
  for P in $(aws iam list-attached-role-policies --role-name "$R" --query 'AttachedPolicies[].PolicyArn' --output text); do
    aws iam detach-role-policy --role-name "$R" --policy-arn "$P"
  done
  for P in $(aws iam list-role-policies --role-name "$R" --query 'PolicyNames[]' --output text); do
    aws iam delete-role-policy --role-name "$R" --policy-name "$P"
  done
  for IP in $(aws iam list-instance-profiles-for-role --role-name "$R" --query 'InstanceProfiles[].InstanceProfileName' --output text); do
    aws iam remove-role-from-instance-profile --instance-profile-name "$IP" --role-name "$R"
  done
  aws iam delete-role --role-name "$R" && echo "deleted $R"
}

# 3. Run it once per role (one name per line: works in zsh and bash)
echo "$ROLES" | tr '\t' '\n' | while read -r R; do delete_role "$R"; done

# 4. Preview unattached wizard-created policies
aws iam list-policies --scope Local --query "Policies[?AttachmentCount==\`0\` && (contains(PolicyName,'menniboe') || contains(PolicyName,'StorageGateway'))].[PolicyName,Arn]" --output table

# 5. Delete a policy: remove non-default versions first, then the policy
delete_policy() {
  A="$1"; echo "== $A"
  aws iam list-policy-versions --policy-arn "$A" --query 'Versions[?!IsDefaultVersion].VersionId' --output text | tr '\t' '\n' | while read -r V; do
    [ -n "$V" ] && aws iam delete-policy-version --policy-arn "$A" --version-id "$V"
  done
  aws iam delete-policy --policy-arn "$A" && echo "deleted $A"
}

aws iam list-policies --scope Local --query "Policies[?AttachmentCount==\`0\` && (contains(PolicyName,'menniboe') || contains(PolicyName,'StorageGateway'))].Arn" --output text | tr '\t' '\n' | while read -r A; do
  delete_policy "$A"
done

# 6. Verify
aws iam list-roles --query "Roles[?starts_with(RoleName,'AWSServiceRoleFor') == \`false\`].RoleName"   # ["ecsTaskExecutionRole"]
aws iam list-policies --scope Local --query "Policies[].PolicyName"                                    # []
```

---

## Zsh vs bash fixes

| Problem | Error | Fix |
|---|---|---|
| A loop over a variable runs once with every value joined | `ValidationError … roleName is invalid` | `echo "$VAR" \| tr '\t' '\n' \| while read -r X; do …; done` |
| `!` inside double quotes | `zsh: event not found: …` | `setopt nobanghist`, or write `== \`false\`` instead of `!` |

```bash
# Turn history expansion off for the current zsh session
setopt nobanghist

# JMESPath "not starts_with" without using "!"
aws iam list-roles --query "Roles[?starts_with(RoleName,'AWSServiceRoleFor') == \`false\`].RoleName"
```
