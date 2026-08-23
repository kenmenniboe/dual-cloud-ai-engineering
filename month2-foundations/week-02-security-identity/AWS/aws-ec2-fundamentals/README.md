# AWS EC2 Fundamentals

Advanced-level review of EC2 core concepts (skipping 101-level launch/SSH, since prior bastion-host and SSH key pair work already covered that ground), plus a full hands-on lab exercising every concept live.

## What I covered

- **Instance types & families** — naming convention (`family` + `generation` + `.size`), and matching General Purpose / Compute Optimized / Memory Optimized / Storage Optimized to workload shape.
- **Security Groups** — stateful behavior, allow-only rule model (no explicit deny), multi-SG union merging, SG-to-SG referencing, and the timeout-vs-connection-refused diagnostic signal.
- **IAM Roles for EC2** — why credentials never belong on an instance, instance profiles, and IAM's eventual-consistency propagation delay.
- **Purchasing options** — On-Demand, Reserved (standard + convertible), Savings Plans, Dedicated Host vs. Dedicated Instance, and Capacity Reservations, matched to workload predictability.
- **Spot Instances & Spot Fleets** — max price mechanics, the 2-minute interruption window, one-time vs. persistent requests, and Spot Fleet allocation strategies (`lowestPrice`, `diversified`, `capacityOptimized`, `priceCapacityOptimized`).

Every module also mapped to an Azure anchor (NSGs, Managed Identity, Azure Dedicated Host, Azure Spot VM eviction policy, VMSS Spot mix) to reinforce the dual-cloud portfolio angle.

## Key outputs / results (hands-on lab)

- Launched a `t3.micro` Amazon Linux 2 instance through the full launch wizard, tab by tab.
- Proved the **SG timeout signal** live: pulled the HTTP rule, watched the curl hang, restored it, confirmed it worked again — while SSH stayed unaffected the whole time.
- Proved **SG union behavior** live: attached a second, completely empty security group and confirmed it couldn't restrict anything the first SG already allowed.
- Created an IAM role (`IAMReadOnlyAccess`), attached it to the running instance, and watched `aws iam list-users` flip from `Unable to locate credentials` → real output → `Access Denied` after pulling the policy — all without touching the instance itself.
- Launched a **persistent** Spot request, then executed the correct teardown order (cancel the request → terminate the instance) and confirmed no auto-relaunch occurred.
- Full lab cleanup: instances terminated, both demo security groups deleted, IAM role deleted, key pair removed.

