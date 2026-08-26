# EC2 Storage — Commands

Every CLI / user-data / shell command from the session, grouped by hands-on stage. Console-only steps (creating volumes, snapshots, AMIs, EFS file systems via the AWS Console UI) aren't CLI commands and are covered in `notes.md` instead.

## Stage 5 — Custom AMI: Base Instance User Data

Installs and enables Apache on the instance that will be imaged into the AMI.

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
```

## Stage 5 — Verify Apache Is Running

Run via EC2 Instance Connect on the base instance before imaging it.

```bash
sudo systemctl status httpd
```

## Stage 5 — Custom AMI: AMI-Launched Instance User Data

Only writes the index page — httpd is already baked into the AMI, so no reinstall needed.

```bash
#!/bin/bash
echo "Hello from Menniboe Farm" > /var/www/html/index.html
```

## Stage 6 — EFS Verification: Instance A (AZ-A)

```bash
sudo su
echo "hello world" > /mnt/efs/fs1/hello.txt
cat /mnt/efs/fs1/hello.txt
```

## Stage 6 — EFS Verification: Instance B (AZ-B)

Confirms the file written on Instance A is visible from Instance B — proof of the shared, multi-AZ mount.

```bash
ls /mnt/efs/fs1/
cat /mnt/efs/fs1/hello.txt
```