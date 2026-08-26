# Week 1 — EC2 Networking & Instance Resilience

## What I Learned Today

Covered five EC2/VPC networking concepts that form the backbone of instance-level networking on the AWS SAA-C03 exam, then combined all five into a single hands-on build.

| # | Module | Core Idea |
|---|--------|-----------|
| 1 | Public vs. Private IPv4 | Private IP is sticky for the instance's life; default public IP is dynamic and changes on every stop/start |
| 2 | Elastic IP (EIP) | A public IPv4 you own, that stays fixed across stop/start — but AWS recommends DNS/Load Balancer over EIPs at scale |
| 3 | Placement Groups | Cluster (low latency, 1 AZ), Spread (max 7/AZ, hardware isolation), Partition (up to 7 partitions/AZ, scales to hundreds) |
| 4 | Elastic Network Interface (ENI) | A detachable virtual NIC — can be pre-created, hot-attached, and moved between instances for low-budget failover |
| 5 | EC2 Hibernate | Dumps RAM to the encrypted root EBS volume on stop, reloads it on start — OS is never actually rebooted |

Each module included an Azure anchor for cross-cloud comparison (Proximity Placement Groups, Availability Sets, NICs, VM Hibernation, Static Public IPs).

## Key Outputs / Results

- **IP behavior verified:** stopping/starting an instance without an EIP changes its public IPv4; the private IPv4 never changes.
- **EIP verified:** once an Elastic IP was associated, the public IPv4 stayed fixed across a stop/start cycle.
- **Placement Group built:** `demo-spread-group` (Spread strategy, rack-level), holding two t2.micro instances on separate hardware.
- **ENI failover demonstrated:** created `demo-eni`, attached it to `demo-instance-a`, then detached (via Force Detach — normal detach didn't take at first) and reattached it to `demo-instance-b`, confirming the private IP moved with it.
- **Hibernate verified:** `uptime` on `demo-instance-a` continued counting after a hibernate → start cycle instead of resetting to 0, confirming the OS was never rebooted.
- All lab resources (EIP, ENI, instances, placement group) were cleaned up in order to avoid ongoing charges.

## Files in This Folder

- `notes.md` — full reference guide: concepts, redo steps, errors/fixes, architecture diagram
- `commands.md` — every CLI/terminal command used, grouped by stage
- `images/architecture-diagram.svg` — final architecture from the combined hands-on demo

