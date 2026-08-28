# AWS High Availability & Scalability — ELB & ASG

AWS SAA study session covering Elastic Load Balancing (ALB, NLB, GWLB, CLB) and Auto Scaling Groups — 13 concept modules followed by a full hands-on build.

## What I covered

- **Scalability vs. High Availability** — vertical/horizontal scaling vs. surviving an AZ failure
- **Load balancing fundamentals** — health checks, managed service model
- **All four load balancer types** — CLB (deprecated), ALB (Layer 7), NLB (Layer 4), GWLB (Layer 3)
- **ALB deep dive** — target groups, path/host/query routing, `X-Forwarded-*` headers
- **NLB deep dive** — static IPs per AZ, TCP/UDP, NLB-in-front-of-ALB pattern
- **GWLB** — third-party appliance chaining via GENEVE
- **Security group chaining** — locking EC2 instances to only trust the load balancer's SG
- **Sticky sessions** — cookie-based session affinity and its load-imbalance trade-off
- **Cross-zone load balancing** — default behavior and cost differences per LB type
- **SSL/TLS & SNI** — termination, ACM, multi-domain certs
- **Deregistration delay / connection draining**
- **Auto Scaling Groups** — min/desired/max, launch templates, LB integration
- **ASG scaling policies** — target tracking, step/simple, scheduled, predictive; cooldown

## Hands-on build

Built and tested a full stack in the AWS Console:
- 2× EC2 instances (Amazon Linux 2, `t2.micro`) running Apache with a "Hello World + instance ID" page
- An **Application Load Balancer** (`DemoALB`) with a path-based `/error` rule and sticky sessions
- A **Network Load Balancer** (`DemoNLB`) fronting the same instances
- Security-group chaining so instances only accept traffic from the load balancers
- A **Launch Template** and **Auto Scaling Group** (`Demo ASG`) attached to the ALB's target group
- A **target tracking scaling policy** (CPU 40%) validated with a live `stress` test — confirmed scale-out and scale-in end to end

## Key outputs / results

- ✅ Confirmed ALB and NLB both load-balance correctly across 2 instances (alternating instance IDs)
- ✅ Reproduced and fixed the classic **NLB health-check failure** caused by a missing security-group rule
- ✅ Verified security lockdown: direct instance IP access blocked, load-balancer access still works
- ✅ Verified sticky sessions via the `AWSALB` cookie in browser dev tools
- ✅ Watched the ASG scale out (1 → 2 → 3 instances) under CPU load and scale back in after load dropped
- ✅ All lab resources cleaned up (see `notes.md` → Part 18) to avoid ongoing ALB/NLB charges

## Files in this folder

- `notes.md` — full tutorial + copy-paste redo guide with exact Portal values, inline errors/fixes, and the architecture diagram
- `commands.md` — every CLI command used, grouped by stage
- `images/architecture-diagram.svg` — final architecture diagram