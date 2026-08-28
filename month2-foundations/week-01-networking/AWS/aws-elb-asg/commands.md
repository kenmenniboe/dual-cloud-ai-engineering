# Commands — AWS High Availability & Scalability Lab

This lab was built primarily through the AWS Console. The commands below were run **inside the EC2 instances** (as user data on launch, and interactively via EC2 Instance Connect for the stress test).

## EC2 User Data — Web Server Bootstrap

Used when launching the two standalone instances (Part 1) and in the Launch Template for the ASG (Part 13).

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
EC2_AVAIL_ZONE=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
echo "<h1>Hello World from instance $INSTANCE_ID in AZ $EC2_AVAIL_ZONE</h1>" > /var/www/html/index.html
```

## Stress Testing — Triggering Auto Scaling (Part 17)

Run interactively via **EC2 Instance Connect** on the running ASG-managed instance.

```bash
# Install the stress utility
sudo amazon-linux-extras install epel -y
sudo yum install -y stress

# Drive CPU to ~100% using 4 workers (leave running to trigger scale-out)
stress -c 4
```

Stop the stress test with `Ctrl+C` in the same session, or reboot the instance from the console.