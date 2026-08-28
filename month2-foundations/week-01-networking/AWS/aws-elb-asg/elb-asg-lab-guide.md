# Lab Guide: Elastic Load Balancing & Auto Scaling Groups (ALB, NLB, ASG)

**Region:** any region works; labels below assume `us-east-1`. Note your actual region in your lab notes.

**Cost note:** t2.micro instances and the ASG itself are Free Tier eligible, but ALB/NLB have hourly charges (~$0.02–0.03/hr each) that are **not** fully Free Tier covered. Complete the Cleanup checklist (Part 18) at the end.

## Prerequisites
- [ ] AWS account with console access
- [ ] Default VPC available (or note your custom VPC ID)
- [ ] IAM permissions for EC2, Elastic Load Balancing, Auto Scaling, CloudWatch, ACM (optional)

---

## PART 1 — Launch Two EC2 Web Server Instances

Console: **EC2 → Instances → Launch instances**

### Step 1.1 — Name and tags
- Name: `My First Instance`
- Leave "Add additional tags" empty

### Step 1.2 — Application and OS Images (AMI)
- Quick Start tab → **Amazon Linux**
- AMI: **Amazon Linux 2 AMI (HVM)**, architecture **64-bit (x86)**
- Confirm the "Free tier eligible" badge is shown

### Step 1.3 — Instance type
- Instance type: **t2.micro** (Free tier eligible)

### Step 1.4 — Key pair (login)
- Key pair: **Proceed without a key pair (Not recommended)**
  - No SSH needed — use **EC2 Instance Connect** later if required

### Step 1.5 — Network settings
- Click **Edit**
- VPC: default VPC (or your lab VPC)
- Subnet: No preference
- Auto-assign public IP: **Enable**
- Firewall (security groups): **Select existing security group**
  - Choose `launch-wizard-1`, or create new:
    - Allow **SSH (22)** from My IP
    - Allow **HTTP (80)** from Anywhere (0.0.0.0/0) — temporary; locked down to the load balancer's SG in Part 4

### Step 1.6 — Configure storage
- Leave default: **8 GiB, gp2/gp3**

### Step 1.7 — Advanced details
- Scroll to **User data**, paste:
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
- Leave every other Advanced details field at default (IAM instance profile, shutdown behavior, termination protection, monitoring, tenancy — none needed here)

### Step 1.8 — Summary panel
- Number of instances: **2**
- Click **Launch instance**

### Step 1.9 — Rename the second instance
- **Instances** → wait for both "Running" → select the second → Rename to `My Second Instance`

### Step 1.10 — Verify each instance individually
- Copy Instance 1's Public IPv4 → browser → confirm "Hello World from instance i-xxxx..."
- Repeat for Instance 2 — confirm a **different** instance ID

✅ **Checkpoint:** Both instances respond with their own Hello World + unique instance ID.

---

## PART 2 — Create an Application Load Balancer (ALB)

Console: **EC2 → Load Balancers → Create load balancer → Application Load Balancer → Create**

### Step 2.1 — Basic configuration
- Name: `DemoALB`
- Scheme: **Internet-facing**
- IP address type: **IPv4**

### Step 2.2 — Network mapping
- VPC: default VPC
- Mappings: check **all Availability Zones**, select a subnet for each

### Step 2.3 — Security groups
- **Create new security group** (opens new tab):
  - Name: `demo-sg-load-balancer`
  - Description: `Allow HTTP into ALB`
  - Inbound: **HTTP (80)** from **Anywhere-IPv4 (0.0.0.0/0)**
  - Outbound: default (all traffic)
  - Create security group
- Back on ALB page: refresh → select `demo-sg-load-balancer` → **remove** the default SG

### Step 2.4 — Listeners and routing
- Listener: **HTTP : 80**
- Default action → **Create target group** (new tab):
  - Target type: **Instances**
  - Name: `demo-tg-alb`
  - Protocol: **HTTP**, Port: **80**, Protocol version: **HTTP1**
  - VPC: default VPC
  - Health check: protocol **HTTP**, path `/` (default) → **Next**
  - Register targets: select both instances → **Include as pending below** → **Create target group**
- Back on ALB page: refresh dropdown → select `demo-tg-alb`

### Step 2.5 — Add-ons / Tags
- Leave defaults; no tags required

### Step 2.6 — Review and create
- **Create load balancer** → **View load balancer**
- Wait for **State: Active** (~2–3 min)

### Step 2.7 — Test the ALB
- Copy the ALB's DNS name → browser → confirm Hello World
- Refresh repeatedly → confirm instance ID alternates between both instances

### Step 2.8 — Verify health checks
- **Target Groups → demo-tg-alb → Targets** → confirm both **Healthy**

✅ **Checkpoint:** ALB DNS round-robins between both instances; both Healthy.

---

## PART 3 — Observe Unhealthy Instance Behavior (optional, instructive)

- Stop "My First Instance" (**Instance state → Stop instance**)
- Wait ~30s → **Target Groups → demo-tg-alb → Targets** → confirm it shows **Unhealthy**
- Refresh ALB DNS repeatedly → only the second instance responds
- Start the instance again → wait for it to pass health checks → confirm alternating resumes

---

## PART 4 — Lock Down EC2 Security Group to Only Trust the ALB

Console: **EC2 → Instances → select an instance → Security tab → click the security group**

### Step 4.1 — Edit inbound rules
- **Edit inbound rules**
- **Delete** the HTTP rule with source `0.0.0.0/0`
- **Add rule**: Type **HTTP**, Source **Custom** → type "demo-sg-load-balancer" → select it (references the SG, not a CIDR)
- Leave the SSH rule as-is (or remove if not needed)
- **Save rules**

### Step 4.2 — Verify the lockdown
- Direct instance public IP in browser → should **time out**
- ALB DNS name → should still work

✅ **Checkpoint:** Direct instance access blocked; ALB access still works.

---

## PART 5 — Add an ALB Listener Rule (Path-Based Routing Demo)

Console: **Load Balancers → DemoALB → Listeners → HTTP:80 listener → Manage rules**

### Step 5.1 — Add rule
- **Add rule** → Name: `DemoRule`
- Condition: **Path** = `/error` → Confirm
- Action: **Return fixed response**
  - Response code: `404`
  - Response body: `Not found - custom error`
  - Content type: `text/plain`
- Priority: `5` → **Next** → review → **Create**

### Step 5.2 — Test
- Browse to `http://<ALB-DNS-name>/error` → confirm the custom 404 response

✅ **Checkpoint:** `/error` returns the custom response; other paths route normally.

---

## PART 6 — Create a Network Load Balancer (NLB)

Console: **EC2 → Load Balancers → Create load balancer → Network Load Balancer → Create**

### Step 6.1 — Basic configuration
- Name: `DemoNLB`
- Scheme: **Internet-facing**, IP address type: **IPv4**

### Step 6.2 — Network mapping
- VPC: default VPC
- Mappings: check **all Availability Zones**
- Note the assigned IPv4 per AZ (or select an Elastic IP per AZ if allocated)

### Step 6.3 — Security groups
- **Create new security group**:
  - Name: `demo-sg-nlb`
  - Description: `Allow HTTP into NLB`
  - Inbound: **HTTP (80)** from Anywhere-IPv4
  - Create
- Refresh → select `demo-sg-nlb` → remove default SG

### Step 6.4 — Listeners and routing
- Protocol: **TCP**, Port: **80**
- Default action → **Create target group**:
  - Target type: **Instances**
  - Name: `demo-tg-nlb`
  - Protocol: **TCP**, Port: **80**
  - VPC: default VPC
  - Health check protocol: **HTTP** (backend speaks HTTP)
  - Advanced health check settings: Healthy threshold `2`, Timeout `2s`, Interval `5s`
  - **Next** → register both instances → **Include as pending below** → **Create target group**
- Back on NLB page: refresh → select `demo-tg-nlb`

### Step 6.5 — Review and create
- **Create load balancer** → **View load balancer** → wait for **Active**

### Step 6.6 — Test (expect a failure first!)
- Browse to NLB DNS name → **will likely time out** the first time — expected, fixed in Part 7

---

## PART 7 — Fix the NLB Health Check Failure

### Step 7.1 — Diagnose
- **Target Groups → demo-tg-nlb → Targets** → confirm both **Unhealthy**

### Step 7.2 — Fix the EC2 security group
- Instance → Security tab → security group → **Edit inbound rules → Add rule**
  - Type **HTTP**, Source **Custom** → select `demo-sg-nlb`
- **Save rules**
- (You now have TWO HTTP source rules: one for `demo-sg-load-balancer`, one for `demo-sg-nlb`)

### Step 7.3 — Re-verify
- Wait ~30–60s → refresh target group → confirm **Healthy**
- Browse NLB DNS name → confirm Hello World, instance ID alternates on refresh

✅ **Checkpoint:** NLB healthy; EC2 SG trusts both load balancers via separate rules.

---

## PART 8 — Enable Sticky Sessions on the ALB Target Group

Console: **Target Groups → demo-tg-alb → Attributes tab → Edit**

### Step 8.1 — Configure stickiness
- Scroll to **Stickiness** → toggle **Turn on**
- Type: **Load balancer generated cookie**
- Duration: `1` day (default)
- **Save changes**

### Step 8.2 — Verify in browser dev tools
- Open Developer Tools → **Network** tab
- Browse ALB DNS, refresh several times → confirm **same instance ID** keeps responding
- Inspect response **Cookies** → look for `AWSALB` with an expiration date

### Step 8.3 — (Optional) Application-based cookie
- Repeat Step 8.1, choose **Application-based cookie**
- App cookie name: `MYCUSTOMCOOKIEAPP` (never `AWSALB`, `AWSALBAPP`, `AWSALBCORS`)

### Step 8.4 — Disable stickiness when done
- Toggle **Turn off** → **Save changes** (restores normal round-robin)

✅ **Checkpoint:** Confirmed cookie-based pinning, then reverted.

---

## PART 9 — Cross-Zone Load Balancing

### Step 9.1 — NLB (default OFF)
- **Load Balancers → DemoNLB → Attributes tab** → confirm **Cross-zone load balancing: Off**
- **Edit** → toggle **On** → note the inter-AZ data charge warning → **Save** (optional; revert after observing)

### Step 9.2 — ALB (always ON)
- **Load Balancers → DemoALB → Attributes tab** → confirm **Cross-zone load balancing: On** (not toggleable at LB level)

### Step 9.3 — Override at target group level (ALB only)
- **Target Groups → demo-tg-alb → Attributes tab → Edit**
- **Cross-zone load balancing**: options are **Inherit from load balancer** (default) / **On** / **Off**
- Leave as **Inherit from load balancer**

✅ **Checkpoint:** NLB defaults Off (chargeable if enabled); ALB always On (free); ALB target group can override.

---

## PART 10 — SSL/TLS Listener (Reference — Requires a Domain + ACM Certificate)

> Requires owning a domain and requesting/importing a certificate in ACM. Read through for reference if you don't have a domain handy.

### Step 10.1 — Request a certificate in ACM (prerequisite)
- **AWS Certificate Manager → Request a certificate → Request a public certificate**
- Domain name: `yourdomain.example.com`
- Validation method: **DNS validation** (recommended)
- Complete DNS validation via your domain's DNS provider

### Step 10.2 — Add an HTTPS listener to the ALB
- **DemoALB → Listeners → Add listener**
- Protocol: **HTTPS**, Port: **443**
- Default actions: forward to `demo-tg-alb`
- Security policy: default (or one supporting legacy TLS if needed)
- Default SSL certificate: **From ACM** → select your certificate
- (Optional) Add additional certificates for other domains — SNI handles selection automatically
- **Add**

### Step 10.3 — Add a TLS listener to the NLB
- **DemoNLB → Listeners → Add listener**
- Protocol: **TLS**, Port: **443**
- Forward to: `demo-tg-nlb`
- Security policy + certificate: same as Step 10.2
- Application layer protocol negotiation: leave default

---

## PART 11 — Deregistration Delay (Connection Draining)

Console: **Target Groups → demo-tg-alb (or demo-tg-nlb) → Attributes tab → Edit**

### Step 11.1 — Adjust the timer
- **Deregistration delay**: default `300` seconds → try `30` seconds → **Save changes**

### Step 11.2 — Observe draining
- **Targets** tab → select an instance → **Deregister**
- Watch **Status** show **draining** for up to your configured delay, then **unused**

✅ **Checkpoint:** Confirmed where this setting lives and how it behaves.

---

## PART 12 — Clean Up Instances Before the ASG Section

- **Instances** → select both → **Instance state → Terminate instance** → confirm
- Wait until both show **Terminated**

(Target groups/load balancers stay in place — the ASG registers new instances into `demo-tg-alb` automatically in Part 14.)

---

## PART 13 — Create a Launch Template

Console: **EC2 → Launch Templates → Create launch template**

### Step 13.1 — Name and description
- Name: `my-demo-template`
- Description: `Template for Demo ASG`
- Template tags: leave blank

### Step 13.2 — AMI
- Quick Start → **Amazon Linux** → **Amazon Linux 2 AMI (HVM)**, **64-bit (x86)**

### Step 13.3 — Instance type
- **t2.micro**

### Step 13.4 — Key pair
- Select an existing key pair, or **Don't include in launch template**

### Step 13.5 — Network settings
- Subnet: **Don't include in launch template** (ASG handles placement)
- Firewall (security groups): select `launch-wizard-1` (now trusts both ALB and NLB SGs)

### Step 13.6 — Configure storage
- Default: **8 GiB gp2/gp3**

### Step 13.7 — Advanced details
- **User data** — same script as Step 1.7:
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
- Leave every other field default (IAM instance profile, purchasing options, monitoring, tenancy)

### Step 13.8 — Create
- **Create launch template**

---

## PART 14 — Create the Auto Scaling Group

Console: **EC2 → Auto Scaling Groups → Create Auto Scaling group**

### Step 14.1 — Name and launch template
- Name: `Demo ASG`
- Launch template: `my-demo-template`, version **1 (Latest)** → **Next**

### Step 14.2 — Instance launch options
- Instance type requirements: **Use launch template** (no override)
- VPC: default VPC
- Availability Zones and subnets: select **all** available subnets
- AZ distribution: **Balanced best effort** → **Next**

### Step 14.3 — Advanced options (load balancer integration)
- **Attach to an existing load balancer**
- Choose from target groups: select `demo-tg-alb`
- VPC Lattice integration: **No**
- Zonal shift: default (off)
- Health checks:
  - **EC2 health checks**: enabled (default)
  - **Elastic Load Balancing health checks**: ✅ check this (lets ALB health feed the ASG's replacement logic)
  - Health check grace period: `300` seconds (default) → **Next**

### Step 14.4 — Group size and scaling
- Desired capacity: `1`
- Minimum capacity: `1`
- Maximum capacity: `1` (raised in Part 15/16)
- Automatic scaling: **No scaling policies** for now → **Next**

### Step 14.5 — Notifications
- Skip → **Next**

### Step 14.6 — Tags
- Skip → **Next**

### Step 14.7 — Review and create
- **Create Auto Scaling group**

### Step 14.8 — Verify
- **Demo ASG → Activity** tab → confirm "Launching a new EC2 instance"
- **Instance management** tab → confirm 1 instance, Running
- **Target Groups → demo-tg-alb → Targets** → confirm registers and shows **Healthy**
- Browse ALB DNS name → confirm Hello World

✅ **Checkpoint:** ASG-launched instance live, registered, serving traffic.

---

## PART 15 — Manually Test Scale Out / Scale In

### Step 15.1 — Scale out to 2
- **Demo ASG → Details → Edit** → Maximum capacity: `2`, Desired capacity: `2` → **Update**
- **Activity** tab → watch for "Launching a new EC2 instance"
- Confirm second instance registers Healthy
- Refresh ALB DNS repeatedly → both instance IDs alternate

### Step 15.2 — Scale back in to 1
- **Edit** → Desired capacity: `1` (Max stays 2) → **Update**
- **Activity** tab → watch for "Terminating EC2 instance"
- Confirm ASG settles to 1 healthy instance

✅ **Checkpoint:** Observed scale-out and scale-in end-to-end.

---

## PART 16 — Configure Target Tracking Scaling Policy

### Step 16.1 — Raise the ceiling
- **Demo ASG → Details → Edit** → Maximum capacity: `3` → **Update**

### Step 16.2 — Create the policy
- **Demo ASG → Automatic scaling tab → Create dynamic scaling policy**
- Policy type: **Target tracking scaling**
- Name: `target-tracking-policy`
- Metric type: **Average CPU utilization**
- Target value: `40`
- Warm-up settings: leave default → **Create**

✅ This auto-creates two CloudWatch alarms: `AlarmHigh` (scale-out) and `AlarmLow` (scale-in).

### Step 16.3 — Verify the alarms
- **CloudWatch → Alarms** → confirm both exist, tied to the ASG's CPU metric

---

## PART 17 — Stress Test to Trigger Scaling

### Step 17.1 — Connect to a running instance
- Instances → select the ASG-managed instance → **Connect → EC2 Instance Connect → Connect**

### Step 17.2 — Install and run the stress tool
```bash
sudo amazon-linux-extras install epel -y
sudo yum install -y stress
stress -c 4
```
(Leave running — drives CPU to ~100% with 4 workers)

### Step 17.3 — Watch scale-out happen
- **Demo ASG → Monitoring** tab → watch CPU Utilization climb
- **Activity** tab → wait for a scaling activity from `AlarmHigh` (default: CPU > 40% for 3 datapoints within 3 min)
- Confirm scale-out up to Max of 3

### Step 17.4 — Stop stress, watch scale-in
- Press **Ctrl+C** in the session, or reboot the instance from the console
- CPU drops toward 0
- Wait for `AlarmLow` (CPU < 28% sustained — can take ~15 min with defaults)
- **Activity** tab → confirm scale-in reduces capacity back toward 1

✅ **Checkpoint:** Watched full target-tracking lifecycle — alarm creation, scale-out under load, scale-in after.

---

## PART 18 — Cleanup Checklist (Avoid Ongoing Charges)

Delete in this order to avoid dependency errors:

1. [ ] **Auto Scaling Groups** → `Demo ASG` → Delete (auto-terminates its instances)
2. [ ] **Load Balancers** → delete `DemoALB` and `DemoNLB`
3. [ ] **Target Groups** → delete `demo-tg-alb` and `demo-tg-nlb`
4. [ ] **Launch Templates** → delete `my-demo-template`
5. [ ] **CloudWatch → Alarms** → delete the two target-tracking alarms if not auto-removed
6. [ ] **Security Groups** → delete `demo-sg-load-balancer` and `demo-sg-nlb` (only after their load balancers are gone)
7. [ ] **EC2 → Instances** → confirm nothing is still running
8. [ ] (If done) **ACM** → delete any test certificate requested in Part 10

---

## Troubleshooting Reference

| Symptom | Likely Cause | Fix |
|---|---|---|
| Target Unhealthy right after launch | Instance still bootstrapping | Wait 1–2 min; check `curl localhost` on the instance |
| NLB target Unhealthy but ALB fine | EC2 SG doesn't allow the NLB's SG | Add inbound rule for `demo-sg-nlb` (Part 7) |
| Direct instance IP still works | EC2 SG still has `0.0.0.0/0` HTTP rule | Redo Part 4 |
| ASG instance loops unhealthy → replaced | User data script error or SG misconfig | Instance Connect in, check `/var/log/cloud-init-output.log` |
| Scaling policy doesn't trigger | Alarm needs sustained threshold breach | Be patient — default 3 datapoints/3 min for high, more for low |
| Unexpected inter-AZ charges | Cross-zone enabled on NLB/GWLB | Review Part 9 — disable if not needed |

---

*Lab sequence: Scalability & HA fundamentals → Load balancing → ALB → NLB → GWLB (conceptual) → Security groups → Sticky sessions → Cross-zone balancing → SSL/TLS & SNI → Connection draining → ASG fundamentals → Scaling policies.*