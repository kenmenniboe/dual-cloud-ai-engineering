# AWS S3 — Commands Reference

> [!NOTE]
> Today's hands-on lab was done entirely in the **AWS Console** — no CLI commands were actually run in this session. The commands below are the **AWS CLI equivalents** for every action performed, provided as a reference for redoing the lab via CLI or for scripting it later. Replace `<bucket>` with your actual bucket name (including the Account Regional namespace suffix) throughout.

## Bucket Setup

```bash
# Create a General Purpose bucket
aws s3api create-bucket --bucket <bucket> --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket <bucket> \
  --versioning-configuration Status=Enabled

# Confirm versioning status
aws s3api get-bucket-versioning --bucket <bucket>
```

## Upload / Versioning

```bash
# Upload a file (creates version 1)
aws s3 cp intro.sh s3://<bucket>/intro.sh

# Overwrite with the same key (creates version 2)
aws s3 cp intro.sh s3://<bucket>/intro.sh

# List all versions of an object
aws s3api list-object-versions --bucket <bucket> --prefix intro.sh

# Normal delete (adds a delete marker, does not destroy bytes)
aws s3api delete-object --bucket <bucket> --key intro.sh

# Permanent delete of a specific version ID
aws s3api delete-object --bucket <bucket> --key intro.sh --version-id <version-id>

# Restore an object by deleting its delete marker
aws s3api delete-object --bucket <bucket> --key intro.sh --version-id <delete-marker-version-id>
```

## Public Access / Bucket Policy

```bash
# Disable Block Public Access on the bucket
aws s3api put-public-access-block \
  --bucket <bucket> \
  --public-access-block-configuration \
  BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false

# Attach a bucket policy from a local JSON file
aws s3api put-bucket-policy --bucket <bucket> --policy file://bucket-policy.json

# View the current bucket policy
aws s3api get-bucket-policy --bucket <bucket>

# Remove the bucket policy
aws s3api delete-bucket-policy --bucket <bucket>
```

`bucket-policy.json`:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::<bucket>/*"]
    }
  ]
}
```

## Static Website Hosting

```bash
# Enable static website hosting
aws s3 website s3://<bucket>/ --index-document index.html

# Upload the index document
aws s3 cp index.html s3://<bucket>/index.html
```

## Encryption

```bash
# Set bucket default encryption to SSE-S3
aws s3api put-bucket-encryption \
  --bucket <bucket> \
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Upload a single object with SSE-KMS override, using the default aws/s3 key
aws s3 cp intro.sh s3://<bucket>/intro.sh \
  --sse aws:kms \
  --sse-kms-key-id alias/aws/s3
```

## Lifecycle Rules

```bash
# Apply a lifecycle configuration from a local JSON file
aws s3api put-bucket-lifecycle-configuration \
  --bucket <bucket> \
  --lifecycle-configuration file://lifecycle.json

# View current lifecycle rules
aws s3api get-bucket-lifecycle-configuration --bucket <bucket>
```

`lifecycle.json`:
```json
{
  "Rules": [
    {
      "ID": "demo-lifecycle-rule",
      "Status": "Enabled",
      "Filter": {},
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" }
      ],
      "Expiration": { "Days": 365 }
    }
  ]
}
```

## Pre-Signed URLs

```bash
# Generate a pre-signed GET URL, 300 seconds (5 minutes) expiry
aws s3 presign s3://<bucket>/intro.sh --expires-in 300
```

## Server Access Logging

```bash
# Create a separate logging bucket in the same region
aws s3api create-bucket --bucket <bucket>-logs --region us-east-1

# Enable logging on the main bucket, pointing at the logging bucket
aws s3api put-bucket-logging \
  --bucket <bucket> \
  --bucket-logging-status '{"LoggingEnabled":{"TargetBucket":"<bucket>-logs","TargetPrefix":"logs/"}}'
```

---

## Git — Push to Repo

```bash
git add aws-s3/ && git commit -m "Add AWS S3 fundamentals to advanced notes + hands-on lab" && git push
```