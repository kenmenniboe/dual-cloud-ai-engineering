# Commands — CloudFront & Global Accelerator Lab

Every CLI command from the session, grouped by workflow stage. Copy-paste ready.

**Substitute these placeholders:**

```
<BUCKET>            your S3 bucket name
<DISTRIBUTION_ID>   e.g. E1XXXXXXXXXXXX
<DIST_DOMAIN>       e.g. dXXXXXXXXXXXXX.cloudfront.net
<ACCOUNT_ID>        your 12-digit AWS account ID
<CERT_ARN>          arn:aws:acm:us-east-1:<ACCOUNT_ID>:certificate/<uuid>
<ETAG>              version token from get-distribution-config
yourdomain.com      your registered domain
```

---

## Table of Contents

- [0. Shell setup](#0-shell-setup)
- [1. Image preparation](#1-image-preparation)
- [2. S3 bucket creation and upload](#2-s3-bucket-creation-and-upload)
- [3. Verify the bucket is private](#3-verify-the-bucket-is-private)
- [4. CloudFront distribution checks](#4-cloudfront-distribution-checks)
- [5. Cache behaviour testing](#5-cache-behaviour-testing)
- [6. Cache invalidation](#6-cache-invalidation)
- [7. Geo restriction via CLI](#7-geo-restriction-via-cli)
- [8. DNS and certificate](#8-dns-and-certificate)
- [9. Final verification](#9-final-verification)
- [10. Teardown](#10-teardown)
- [11. Git](#11-git)

---

## 0. Shell setup

```bash
# Fix: zsh does not treat # as a comment interactively by default.
# Without this, pasting a comment line gives: zsh: unknown file attribute: h
setopt interactive_comments

# Make it permanent
echo 'setopt interactive_comments' >> ~/.zshrc
```

```bash
# Confirm CLI identity and region
aws sts get-caller-identity
aws configure get region
```

---

## 1. Image preparation

```bash
# Convert AVIF to JPEG — macOS, built in
sips -s format jpeg input.avif --out output.jpg

# Convert AVIF to JPEG — ImageMagick, any OS
magick input.avif output.jpg
```

```bash
# Verify the page renders locally before uploading anything
cd ~/Desktop/menniboe-cdn-lab
open index.html
```

```bash
# Confirm every referenced image actually exists
cd ~/Desktop/menniboe-cdn-lab
for f in $(grep -o 'images/[^"]*' index.html); do
  [ -f "$f" ] && echo "OK   $f" || echo "MISS $f"
done
```

---

## 2. S3 bucket creation and upload

```bash
# Create the bucket (console alternative)
aws s3 mb s3://<BUCKET> --region us-east-1
```

```bash
# Upload the site — sync preserves the images/ folder structure
cd ~/Desktop/menniboe-cdn-lab
aws s3 sync . s3://<BUCKET>/
```

```bash
# Verify the upload — expect 11 objects
aws s3 ls s3://<BUCKET>/ --recursive --human-readable
```

```bash
# Re-upload a single file after an edit
aws s3 cp index.html s3://<BUCKET>/index.html
aws s3 cp images/goats.jpg s3://<BUCKET>/images/goats.jpg
```

```bash
# Confirm S3 has the newest version
aws s3api head-object --bucket <BUCKET> --key index.html \
  --query "{LastModified:LastModified,Size:ContentLength}"
```

---

## 3. Verify the bucket is private

```bash
# All four values must be true
aws s3api get-public-access-block --bucket <BUCKET>
```

```bash
# BEFORE creating the distribution — expect NoSuchBucketPolicy
aws s3api get-bucket-policy --bucket <BUCKET>
```

```bash
# AFTER creating the distribution — expect the OAC policy
aws s3api get-bucket-policy --bucket <BUCKET> --output text | python3 -m json.tool
```

---

## 4. CloudFront distribution checks

```bash
# List distributions — get the ID, domain and status
aws cloudfront list-distributions \
  --query "DistributionList.Items[].{Id:Id,Domain:DomainName,Status:Status}" \
  --output table
```

```bash
# Poll deployment status — re-run until it says Deployed
aws cloudfront get-distribution --id <DISTRIBUTION_ID> \
  --query "Distribution.Status" --output text
```

```bash
# Inspect current restrictions
aws cloudfront get-distribution --id <DISTRIBUTION_ID> \
  --query "Distribution.DistributionConfig.Restrictions" --output json
```

```bash
# Confirm the root now serves index.html
curl -sI https://<DIST_DOMAIN> | head -5
```

---

## 5. Cache behaviour testing

```bash
# Run twice: expect "Miss from cloudfront" then "Hit from cloudfront"
curl -sI https://<DIST_DOMAIN>/index.html | grep -i -E "x-cache|^age|content-type"
curl -sI https://<DIST_DOMAIN>/index.html | grep -i -E "x-cache|^age|content-type"
```

```bash
# Check what content the edge is actually serving, three times,
# to expose disagreement between cache nodes
for i in 1 2 3; do
  curl -s  https://<DIST_DOMAIN>/ | grep "<h1>"
  curl -sI https://<DIST_DOMAIN>/ | grep -i -E "x-cache|^age"
  echo "---"
done
```

```bash
# Simple status check
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" https://<DIST_DOMAIN>/
```

---

## 6. Cache invalidation

```bash
# Invalidate the page. Invalidate BOTH /index.html and / —
# they are separate cache entries.
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/index.html" "/"
```

```bash
# Wildcard — counts as ONE path regardless of how many files it clears
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/images/*"
```

```bash
# Invalidate everything
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

```bash
# Check invalidation status: InProgress -> Completed
aws cloudfront list-invalidations --distribution-id <DISTRIBUTION_ID> --output table
```

```bash
# Verify the fix landed
sleep 30
for i in 1 2 3; do
  curl -s  https://<DIST_DOMAIN>/ | grep "<h1>"
  curl -sI https://<DIST_DOMAIN>/ | grep -i -E "x-cache|^age"
  echo "---"
done
```

---

## 7. Geo restriction via CLI

Needed because geo restriction is no longer in the console Security tab on the Free plan.

```bash
cd ~/Desktop/menniboe-cdn-lab

# Export the current config and read the ETag + Restrictions
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID> > dist-config.json

cat dist-config.json | python3 -c "
import json,sys
d = json.load(sys.stdin)
print('ETag:', d['ETag'])
print('Restrictions:', json.dumps(d['DistributionConfig']['Restrictions'], indent=2))
"
```

```bash
# Build a BLOCK LIST config.
# API uses legacy 'blacklist' / 'whitelist' — the console says block/allow list.
python3 - <<'EOF'
import json
d = json.load(open('dist-config.json'))
cfg = d['DistributionConfig']
cfg['Restrictions'] = {
    "GeoRestriction": {
        "RestrictionType": "blacklist",
        "Quantity": 2,
        "Items": ["US", "CN"]
    }
}
json.dump(cfg, open('dist-config-updated.json','w'), indent=2)
print("Wrote dist-config-updated.json")
print(json.dumps(cfg['Restrictions'], indent=2))
EOF
```

```bash
# Apply. --if-match is optimistic locking using the ETag.
aws cloudfront update-distribution \
  --id <DISTRIBUTION_ID> \
  --if-match <ETAG> \
  --distribution-config file://dist-config-updated.json \
  --query "Distribution.DistributionConfig.Restrictions" \
  --output json
```

```bash
# Wait for Deployed, then test — expect 403
aws cloudfront get-distribution --id <DISTRIBUTION_ID> \
  --query "Distribution.Status" --output text

curl -s -o /dev/null -w "HTTP status: %{http_code}\n" https://<DIST_DOMAIN>/
```

```bash
# REVERT — re-export first, because the ETag changed
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID> > dist-config2.json

python3 - <<'EOF'
import json
d = json.load(open('dist-config2.json'))
print('New ETag:', d['ETag'])
cfg = d['DistributionConfig']
cfg['Restrictions'] = {
    "GeoRestriction": {
        "RestrictionType": "none",
        "Quantity": 0
    }
}
json.dump(cfg, open('dist-config-revert.json','w'), indent=2)
print("Wrote dist-config-revert.json")
EOF
```

```bash
aws cloudfront update-distribution \
  --id <DISTRIBUTION_ID> \
  --if-match <NEW_ETAG> \
  --distribution-config file://dist-config-revert.json \
  --query "Distribution.DistributionConfig.Restrictions" \
  --output json
```

```bash
# Confirm access restored — expect 200
curl -s -o /dev/null -w "HTTP status: %{http_code}\n" https://<DIST_DOMAIN>/
```

---

## 8. DNS and certificate

```bash
# Confirm the registrar has delegated to Route 53
dig NS yourdomain.com +short
```

```bash
# List hosted zones
aws route53 list-hosted-zones \
  --query "HostedZones[].{Name:Name,Id:Id}" --output table
```

```bash
# List every record in the zone
aws route53 list-resource-record-sets --hosted-zone-id <ZONE_ID> \
  --query "ResourceRecordSets[].{Name:Name,Type:Type}" --output table
```

```bash
# List certificates — must be us-east-1 for CloudFront
aws acm list-certificates --region us-east-1 \
  --query "CertificateSummaryList[].{Domain:DomainName,Arn:CertificateArn}" \
  --output table
```

```bash
# Poll certificate status: PENDING_VALIDATION -> ISSUED
aws acm describe-certificate --region us-east-1 \
  --certificate-arn <CERT_ARN> \
  --query "Certificate.Status" --output text
```

```bash
# Resolve the domain to confirm the alias records work
dig yourdomain.com +short
dig www.yourdomain.com +short
```

---

## 9. Final verification

```bash
# Both domains over HTTPS — expect 200
curl -s -o /dev/null -w "%{http_code}\n" https://yourdomain.com/
curl -s -o /dev/null -w "%{http_code}\n" https://www.yourdomain.com/
```

```bash
# HTTP should redirect — expect 301 Moved Permanently, Server: CloudFront
curl -sI http://yourdomain.com/ | head -3
```

```bash
# Inspect the TLS certificate being served
curl -sIv https://yourdomain.com/ 2>&1 | grep -i -E "subject:|issuer:|SSL connection"
```

```bash
# Full header dump
curl -sI https://yourdomain.com/
```

---

## 10. Teardown

```bash
# 1. Empty the bucket
aws s3 rm s3://<BUCKET> --recursive
```

```bash
# 2. Disable the distribution — required before deletion
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID> > teardown.json

python3 - <<'EOF'
import json
d = json.load(open('teardown.json'))
print('ETag:', d['ETag'])
cfg = d['DistributionConfig']
cfg['Enabled'] = False
json.dump(cfg, open('teardown-disabled.json','w'), indent=2)
print("Wrote teardown-disabled.json")
EOF

aws cloudfront update-distribution \
  --id <DISTRIBUTION_ID> \
  --if-match <ETAG> \
  --distribution-config file://teardown-disabled.json \
  --query "Distribution.Status" --output text
```

```bash
# 3. Wait for Deployed, then delete using the ETag from AFTER the disable
aws cloudfront get-distribution-config --id <DISTRIBUTION_ID> \
  --query "ETag" --output text

aws cloudfront delete-distribution --id <DISTRIBUTION_ID> --if-match <NEW_ETAG>
```

```bash
# 4. Delete the bucket
aws s3 rb s3://<BUCKET>
```

```bash
# 5. Local cleanup
rm -f dist-config*.json teardown*.json
```

**Global Accelerator teardown (Lab B, for reference)**

```bash
# Disable before delete
aws globalaccelerator update-accelerator \
  --accelerator-arn <ACCELERATOR_ARN> --no-enabled --region us-west-2

aws globalaccelerator delete-accelerator \
  --accelerator-arn <ACCELERATOR_ARN> --region us-west-2

# Terminate EC2 instances in BOTH regions
aws ec2 terminate-instances --instance-ids <ID> --region us-east-1
aws ec2 terminate-instances --instance-ids <ID> --region eu-west-1
```

---

## 11. Git

```bash
# Keep exported configs out of the repo — they contain your AWS account ID
echo 'dist-config*.json'  >> .gitignore
echo 'teardown*.json'     >> .gitignore
```

```bash
# Scaffold the folder and files
mkdir -p aws-cloudfront-global-accelerator/images && touch aws-cloudfront-global-accelerator/{README.md,notes.md,commands.md}
```

```bash
# Stage, commit and push in one shot
git add . && git commit -m "Add CloudFront + Global Accelerator notes and OAC lab" && git push
```

```bash
# For commit messages containing special characters
git commit -F commit-message.txt
```
