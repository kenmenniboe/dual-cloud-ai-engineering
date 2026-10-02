# Commands: AWS Decoupling & Messaging Lab

All commands ran in **AWS CloudShell, us-east-1** (AWS CLI v2). Replace `<initials>` with your bucket suffix.
Parts 1–4 (SQS, SNS) were done in the console. See [notes.md](notes.md) for the exact Portal values.

---

## 1. Environment check

```bash
aws --version
```

---

## 2. Kinesis Data Streams: produce records

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-ama \
  --data "Order 3001: 3 goats" \
  --cli-binary-format raw-in-base64-out
```

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-kofi \
  --data "Order 3002: 50 kg tilapia" \
  --cli-binary-format raw-in-base64-out
```

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-ama \
  --data "Order 3003: 12 eggs trays" \
  --cli-binary-format raw-in-base64-out
```

---

## 3. Kinesis Data Streams: consume records

```bash
# List shards
aws kinesis list-shards --stream-name menniboe-farm-stream
```

```bash
# Get an iterator from the oldest record (TRIM_HORIZON) and save it
SHARD_ITERATOR=$(aws kinesis get-shard-iterator \
  --stream-name menniboe-farm-stream \
  --shard-id shardId-000000000000 \
  --shard-iterator-type TRIM_HORIZON \
  --query 'ShardIterator' \
  --output text)
```

```bash
# Read records (Data is base64-encoded)
aws kinesis get-records --shard-iterator "$SHARD_ITERATOR"
```

```bash
# Read and decode the Data field to plain text
aws kinesis get-records --shard-iterator "$SHARD_ITERATOR" \
  --query 'Records[].Data' --output text \
  | tr '\t' '\n' | while read d; do echo "$d" | base64 --decode; echo; done
```

---

## 4. Firehose test: send new records after Firehose is Active

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-ama \
  --data "Order 4001: 6 goats" \
  --cli-binary-format raw-in-base64-out
```

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-kofi \
  --data "Order 4002: 30 kg tilapia" \
  --cli-binary-format raw-in-base64-out
```

```bash
aws kinesis put-record \
  --stream-name menniboe-farm-stream \
  --partition-key customer-esi \
  --data "Order 4003: 2 pigs" \
  --cli-binary-format raw-in-base64-out
```

---

## 5. Cleanup (billing resources first)

```bash
# 1. Firehose
aws firehose delete-delivery-stream --delivery-stream-name menniboe-farm-firehose
aws firehose list-delivery-streams
```

```bash
# 2. Kinesis stream
aws kinesis delete-stream --stream-name menniboe-farm-stream
aws kinesis list-streams
```

```bash
# 3. Empty and delete the S3 bucket
aws s3 rm s3://menniboe-farm-datalake-<initials> --recursive
aws s3 rb s3://menniboe-farm-datalake-<initials>
```

```bash
# 4. SNS topic (also removes its subscriptions)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws sns delete-topic --topic-arn arn:aws:sns:us-east-1:${ACCOUNT_ID}:menniboe-farm-orders-topic
```

```bash
# 5. All four SQS queues
for q in menniboe-farm-orders menniboe-farm-orders.fifo menniboe-livestock-orders menniboe-produce-orders; do
  aws sqs delete-queue --queue-url "$(aws sqs get-queue-url --queue-name "$q" --query QueueUrl --output text)"
  echo "Deleted $q"
done
```

```bash
# 6. Firehose CloudWatch log group
aws logs delete-log-group --log-group-name /aws/kinesisfirehose/menniboe-farm-firehose
```

> IAM role `KinesisFirehoseServiceRole-menniboe-farm-…` and policy `KinesisFirehoseServicePolicy-menniboe-farm-…` were deleted in the IAM console.
> Do **not** delete `Default_CloudWatch_Alarms_Topic`.

---

## 6. Verify cleanup

```bash
aws firehose list-delivery-streams
aws kinesis list-streams
aws sqs list-queues
aws sns list-topics
```


