# Week 1 — EC2 Networking & Instance Resilience — Reference Guide

Full redo-ready notes for AWS SAA-C03 prep: IP addressing, Elastic IPs, Placement Groups, Elastic Network Interfaces, and EC2 Hibernate.

## Table of Contents

- [Overview](#overview)
- [Acronym Glossary](#acronym-glossary)
- [Module 1 Public vs Private IPv4 Addressing](#module-1-public-vs-private-ipv4-addressing)
  - [Module 1 Concept and Real World Example](#module-1-concept-and-real-world-example)
  - [Module 1 Azure Anchor](#module-1-azure-anchor)
  - [Hands On Launch the Lab Instance](#hands-on-launch-the-lab-instance)
  - [Hands On Verify IP Behavior](#hands-on-verify-ip-behavior)
- [Module 2 Elastic IP Addresses](#module-2-elastic-ip-addresses)
  - [Module 2 Concept and Real World Example](#module-2-concept-and-real-world-example)
  - [Module 2 Azure Anchor](#module-2-azure-anchor)
  - [Hands On Allocate and Associate an Elastic IP](#hands-on-allocate-and-associate-an-elastic-ip)
  - [Hands On Verify and Clean Up the Elastic IP](#hands-on-verify-and-clean-up-the-elastic-ip)
- [Module 3 EC2 Placement Groups](#module-3-ec2-placement-groups)
  - [Module 3 Concept and Real World Example](#module-3-concept-and-real-world-example)
  - [Module 3 Azure Anchor](#module-3-azure-anchor)
  - [Hands On Create a Placement Group](#hands-on-create-a-placement-group)
  - [Hands On Launch an Instance Into the Group](#hands-on-launch-an-instance-into-the-group)
- [Module 4 Elastic Network Interfaces ENI](#module-4-elastic-network-interfaces-eni)
  - [Module 4 Concept and Real World Example](#module-4-concept-and-real-world-example)
  - [Module 4 Azure Anchor](#module-4-azure-anchor)
  - [Hands On Create a Standalone ENI](#hands-on-create-a-standalone-eni)
  - [Hands On Attach Detach and Move the ENI](#hands-on-attach-detach-and-move-the-eni)
- [Module 5 EC2 Hibernate](#module-5-ec2-hibernate)
  - [Module 5 Concept and Real World Example](#module-5-concept-and-real-world-example)
  - [Module 5 Azure Anchor](#module-5-azure-anchor)
  - [Hands On Launch With Hibernation Enabled](#hands-on-launch-with-hibernation-enabled)
  - [Hands On Test Hibernation](#hands-on-test-hibernation)
- [Combined Hands On Demo Resilient Two Node Setup](#combined-hands-on-demo-resilient-two-node-setup)
  - [Phase 1 Placement Group](#phase-1-placement-group)
  - [Phase 2 Launch Two Instances](#phase-2-launch-two-instances)
  - [Phase 3 Confirm Baseline Networking](#phase-3-confirm-baseline-networking)
  - [Phase 4 Elastic IP on Instance A](#phase-4-elastic-ip-on-instance-a)
  - [Phase 5 ENI Failover Between A and B](#phase-5-eni-failover-between-a-and-b)
  - [Phase 6 Hibernate Test on Instance A](#phase-6-hibernate-test-on-instance-a)
  - [Phase 7 Cleanup](#phase-7-cleanup)
- [Final Architecture Diagram](#final-architecture-diagram)
- [Exam Style Scenario Reference](#exam-style-scenario-reference)
- [Cleanup Checklist](#cleanup-checklist)

---

## Overview

Five EC2/VPC networking building blocks, taught in the order they naturally build on each other: address fundamentals → a fix for the "address changes" problem → physical placement control → detachable networking identity → memory-state persistence across restarts. Closed out with one combined lab that uses all five together.

---

## Acronym Glossary

| Acronym | Meaning |
|---|---|
| **IPv4** | Internet Protocol version 4 — the four-octet (0–255) addressing scheme, e.g. `10.0.1.10` |
| **VPC** | Virtual Private Cloud — your isolated private network in AWS |
| **AZ** | Availability Zone — an isolated physical data center location within a Region |
| **AMI** | Amazon Machine Image — the OS/software template used to launch an instance |
| **EBS** | Elastic Block Store — persistent block storage volumes attached to EC2 instances |
| **EIP** | Elastic IP — a static, account-owned public IPv4 address |
| **ENI** | Elastic Network Interface — a virtual network card (NIC) that can be created, attached, detached, and moved independently of any instance |
| **IGW** | Internet Gateway — the VPC component that allows public subnet traffic to/from the internet |
| **KMS** | Key Management Service — used here to encrypt the root EBS volume required for hibernation |
| **NIC** | Network Interface Card — the general networking term; Azure's direct equivalent resource to an AWS ENI |
| **SG** | Security Group — instance-level virtual firewall, attachable per-ENI |
| **CIDR** | Classless Inter-Domain Routing — the `/24`-style notation used for subnet address ranges |
| **HA** | High Availability — minimizing downtime; ENI-move failover is a "low-budget HA" pattern |
| **PPG** | Proximity Placement Group — Azure's equivalent to an AWS Cluster Placement Group |
| **SAA-C03** | The current AWS Certified Solutions Architect – Associate exam code |

---

## Module 1 Public vs Private IPv4 Addressing

### Module 1 Concept and Real World Example

Every instance in a VPC gets a **private IPv4** (unique only inside its own network, sticky for the instance's life). If it's in a public subnet with auto-assign on, it also gets a **public IPv4** (globally unique, internet-reachable) — but that one is **dynamic by default**: it's released on stop and reassigned on start.

> [!NOTE]
> Two completely separate private networks (two different VPCs, two different companies) can reuse the exact same private IP range with zero conflict. Public IPs, by contrast, must be globally unique.

Real-world analogy: an office phone system. Internal extensions (private IPs) only work desk-to-desk inside the building. The main switchboard number (public IP) is the only number reachable from outside.

### Module 1 Azure Anchor

Azure VMs get a **Private IP** from the VNet's subnet range (persistent, same as AWS). A **Public IP** is a separate Azure resource attached to the NIC — and it's *dynamic* by default too, releasing/reassigning on stop/deallocate, exactly like AWS.

### Hands On Launch the Lab Instance

Full EC2 Launch Instance wizard, every tab:

1. **Name and tags** — `networking-lab`
2. **Application and OS Images (AMI)** — Amazon Linux 2
3. **Instance type** — t2.micro (Free Tier)
4. **Key pair** — select or create one
5. **Network settings**
   - VPC: default
   - Subnet: a **public** subnet (has a route to an Internet Gateway)
   - Auto-assign public IP: **Enable**
   - Firewall (security group): allow inbound SSH (port 22) from your IP
6. **Configure storage** — default 8 GiB gp3 root volume
7. **Advanced details** — leave default for now
8. **Launch instance**

![Screenshot: EC2 launch wizard Network settings tab with Auto-assign public IP enabled](images/screenshot-placeholder.png)

### Hands On Verify IP Behavior

1. Instances → select instance → **Details** tab → note the **Public IPv4** and **Private IPv4** values
2. SSH in using the **public** IP → succeeds
3. Try SSH using the **private** IP from your laptop → fails/times out
4. **Stop** the instance (not Reboot)
5. **Start** the instance again
6. Compare addresses: Public IPv4 has changed; Private IPv4 has not

> [!TIP]
> This is the exact problem Module 2 (Elastic IP) solves — keep this instance running for the next section.

---

## Module 2 Elastic IP Addresses

### Module 2 Concept and Real World Example

An **Elastic IP** is a public IPv4 you own until you release it. Unlike the default dynamic public IP, it stays fixed through stop/start cycles, and can be moved to a different instance for quick failover.

- Default limit: **5 EIPs per account** (soft limit, raisable via support request)
- AWS's own guidance: avoid EIPs where possible — prefer a DNS name (Route 53), ideally pointed at a Load Balancer, over hardcoding a fixed IP

> [!IMPORTANT]
> An Elastic IP is billed hourly (~$0.005/hr, ~$3.50/month) **whether or not it's attached to a running instance** — AWS specifically charges for *unused* allocated EIPs to discourage hoarding addresses. Always release ones you're not using. New accounts get 750 hrs/month of public IPv4 usage under the Free Tier.

Real-world analogy: a ported phone number — you own it, and can move it from one physical device to another; callers reach you regardless of which device you're using.

### Module 2 Azure Anchor

Azure's direct analog is a **Public IP address resource with Static allocation** (vs. the default Dynamic). Same billing philosophy: Azure charges hourly for a Public IP whether or not it's attached to a running resource.

### Hands On Allocate and Associate an Elastic IP

1. VPC console → **Elastic IPs** → **Allocate Elastic IP address**
2. Network Border Group: default (your Region)
3. Public IPv4 address pool: **Amazon's pool of IPv4 addresses**
4. Tags: optional, e.g. `Name = lab-eip`
5. **Allocate**
6. Select the new EIP → **Actions → Associate Elastic IP address**
7. Resource type: **Instance**
8. Instance: your running lab instance
9. Private IP address: auto-filled (only one available)
10. **Associate**

### Hands On Verify and Clean Up the Elastic IP

1. Instance **Details** tab → Public IPv4 now equals the Elastic IP
2. SSH in using the EIP → works
3. **Stop** the instance, then **Start** it again → Public IPv4 (the EIP) is unchanged this time — compare against Module 1's behavior
4. Elastic IPs → select it → **Actions → Disassociate Elastic IP address**
5. **Actions → Release Elastic IP address**

---

## Module 3 EC2 Placement Groups

### Module 3 Concept and Real World Example

| Strategy | What it does | Trade-off | Limit |
|---|---|---|---|
| **Cluster** | Packs instances close together, single AZ, low-latency hardware | High throughput (~10 Gbps), but correlated failure risk | No hard instance cap |
| **Spread** | Each instance on distinct hardware, can span multiple AZs | Minimizes simultaneous-failure risk | Max 7 instances per AZ per group |
| **Partition** | Up to 7 partitions per AZ, each on its own rack | Failure isolated to one partition; scales to hundreds of instances | Up to 7 partitions/AZ, spans multiple AZs in a Region |

Real-world analogy: Cluster = seating your whole team at one conference table (fast collaboration, but the table can collapse). Spread = putting critical staff in different buildings across town. Partition = a large event split into sections, each on its own power circuit.

### Module 3 Azure Anchor

- Cluster ↔ **Proximity Placement Group** (co-locates VMs for low latency)
- Spread ↔ **Availability Set** (spreads VMs across fault/update domains in one datacenter)
- Partition has no exact Azure equivalent — closest is combining **Availability Zones** with Availability Sets underneath each zone

### Hands On Create a Placement Group

1. EC2 console → **Network & Security → Placement Groups** → **Create placement group**
2. Name — `demo-critical-group` (or per strategy, see below)
3. Placement strategy — Cluster / Spread / Partition
   - If **Spread**: Spread level — `rack` (default; `host` is Outposts-only)
   - If **Partition**: Number of partitions — 1 to 7
4. Tags — optional
5. **Create group**

### Hands On Launch an Instance Into the Group

1. Launch Instance wizard → **Advanced details** tab → **Placement group name** → select your group
2. Launch

> [!WARNING]
> Placement group **strategy cannot be changed after creation**. If you pick the wrong one, delete the group and recreate it — you can only delete a placement group once it has no instances in it.

> [!WARNING]
> Spread groups are capped at **7 instances per AZ per group**. Launching an 8th instance into the same AZ/group fails — either use another AZ or switch to a Partition group.

---

## Module 4 Elastic Network Interfaces ENI

### Module 4 Concept and Real World Example

An ENI is the virtual network card itself. AWS auto-creates a primary one (`eth0`) at launch, but you can also create ENIs independently, attach a second one (`eth1`) to a running instance, and detach/reattach one between two different instances entirely.

Each ENI carries, independent of the instance: primary + secondary private IPv4s, an optional Elastic IP, one or more security groups, a MAC address, and a delete-on-termination flag.

> [!NOTE]
> An ENI is bound to a specific subnet (and therefore AZ) for its entire life — it cannot be moved to an instance in a different AZ.

Real-world analogy: a SIM card. Your number/identity lives on the SIM, not the phone — pop it into a different phone and calls resume seamlessly. This is the "low-budget high availability" pattern: move the ENI from a dead instance to a healthy one.

> [!WARNING]
> Attaching **two public ENIs to the same instance does not reliably give you two working public IPs** — without custom routing, there's no guarantee return traffic exits through the interface it arrived on. This is a known exam trap.

### Module 4 Azure Anchor

Azure's **Network Interface (NIC)** resource is the direct equivalent. The difference: in Azure the NIC is always an explicit resource attached at VM creation, whereas AWS auto-creates the primary ENI implicitly. Multi-NIC VMs (size permitting) support the same dual-homing pattern.

### Hands On Create a Standalone ENI

1. VPC console → **Network Interfaces** → **Create network interface**
2. Description — `demo-eni`
3. Subnet — must match the AZ of the instance you'll attach it to
4. Private IPv4 address — Auto-assign
5. Security groups — select/attach one
6. Tags — optional
7. **Create network interface**

### Hands On Attach Detach and Move the ENI

1. Select the ENI → **Actions → Attach** → choose an instance
2. Instance's **Networking** tab now shows two network interfaces
3. Select the ENI → **Actions → Detach**

> [!WARNING]
> **Error/Fix:** A plain **Detach** can fail to complete or leave the ENI stuck in a detaching state while the instance is still using it. If Detach doesn't finish cleanly, use **Actions → Force Detach** instead, then refresh — the error clears and the ENI becomes available.

4. Once detached, **Actions → Attach** → select the *other* instance
5. Confirm the private IP moved with it — that instance now shows 2 ENIs, the original now shows 1

> [!NOTE]
> On termination, the auto-created primary ENI is deleted (Delete on Termination = true by default). A manually created ENI **survives termination** unless you delete it yourself.

---

## Module 5 EC2 Hibernate

### Module 5 Concept and Real World Example

A normal stop discards RAM — starting again means a cold OS boot. **Hibernate** dumps the full contents of RAM to a file on the **root EBS volume** before shutdown, then reloads it into memory on start. The OS is never actually rebooted; every open process and warmed cache survives.

Requirements: root volume must be **EBS-backed, encrypted, and large enough** to hold the instance's RAM. RAM must be under roughly 150 GB. Not supported on bare metal. Works on Linux and Windows, on On-Demand/Reserved/Spot. Max hibernation duration: **60 days**.

> [!TIP]
> Hibernate is also a configurable **Spot Instance interruption behavior** — instead of a plain stop/terminate on interruption, you can set it to hibernate, so the instance resumes exactly where it left off once Spot capacity frees up again.

Real-world analogy: closing a laptop lid (hibernate, instant resume with everything intact) vs. a full shutdown (cold start, relaunch everything).

### Module 5 Azure Anchor

Azure has the same feature, called **VM Hibernation** — RAM state is written to the OS disk before deallocation and reloaded on resume, avoiding a cold boot, with the same OS-disk free-space requirement.

### Hands On Launch With Hibernation Enabled

1. Name and tags
2. AMI — Amazon Linux 2
3. Instance type — t2.micro (1 GiB RAM)
4. Key pair
5. Network settings — security group allowing SSH
6. Configure storage → expand **Advanced** → **Encrypted: Yes**, default `aws/ebs` KMS key; 8 GiB default is plenty for a 1 GiB RAM dump
7. Advanced details → **Stop - Hibernate behavior** → Enable
8. Launch

> [!WARNING]
> **Error/Fix:** If you enable Stop-Hibernate behavior on **Advanced details** without first encrypting the root volume back on the **Configure storage** step, the Portal surfaces a validation warning that hibernation requires an encrypted root volume with enough free space for the full RAM size. Go back to Configure storage → Advanced → set Encrypted to Yes before completing the launch.

### Hands On Test Hibernation

1. Connect via EC2 Instance Connect
2. Run `uptime` — note the value (near 0 minutes on a fresh instance)
3. Disconnect
4. **Instance state → Stop instance → Hibernate** (not a plain Stop)
5. Wait for **stopped** state
6. **Start** the instance again
7. Reconnect, run `uptime` again — it **continues counting** rather than resetting to 0
8. Terminate when done

---

## Combined Hands On Demo Resilient Two Node Setup

A single scenario combining all five modules: a 2-instance spread-placement setup with a fixed public endpoint, a movable network identity, and a warm-restart capability.

### Phase 1 Placement Group

1. Network & Security → **Placement Groups** → Create placement group
2. Name: `demo-spread-group`
3. Strategy: **Spread**, spread level: `rack`
4. Create group

### Phase 2 Launch Two Instances

Repeat for `demo-instance-a` and `demo-instance-b`:

1. Name and tags
2. AMI: Amazon Linux 2
3. Instance type: t2.micro
4. Key pair: same one for both
5. Network settings: same VPC, same public subnet, auto-assign public IP **Enable**, security group allowing SSH
6. Configure storage → Advanced → **Encrypted: Yes** (`aws/ebs` key)
7. Advanced details → **Placement group name**: `demo-spread-group`; **Stop-Hibernate behavior: Enable**
8. Launch

### Phase 3 Confirm Baseline Networking

- Note each instance's Public IPv4 and Private IPv4 on the Details tab
- SSH into `demo-instance-a` via its public IP → confirm it connects

### Phase 4 Elastic IP on Instance A

1. VPC → Elastic IPs → Allocate Elastic IP address → Amazon's pool → Allocate
2. Select it → Actions → Associate → Instance: `demo-instance-a` → Associate
3. Stop, then Start instance A (plain stop, not hibernate) → confirm the public IP is unchanged

### Phase 5 ENI Failover Between A and B

1. VPC → Network Interfaces → Create network interface
2. Description: `demo-eni`, Subnet: same subnet/AZ as the instances, Private IPv4: auto-assign, Security group: same as the instances → Create
3. Select it → Actions → Attach → `demo-instance-a` → confirm it now shows 2 ENIs on the Networking tab
4. Actions → Detach

> [!WARNING]
> If Detach doesn't complete (ENI stuck showing in-use), use **Actions → Force Detach**, then refresh.

5. Actions → Attach → `demo-instance-b` → confirm the private IP has moved

### Phase 6 Hibernate Test on Instance A

1. Connect to `demo-instance-a` via EC2 Instance Connect, run `uptime`, note the value
2. Disconnect → Instance state → Stop instance → **Hibernate**
3. Wait for "stopped," then Start it again
4. Reconnect, run `uptime` again → confirm it continued rather than reset to 0

### Phase 7 Cleanup

Order matters — do it in this sequence:

1. Elastic IPs → disassociate → release
2. Network Interfaces → delete `demo-eni` (must be detached first)
3. Terminate `demo-instance-a` and `demo-instance-b`
4. Placement Groups → delete `demo-spread-group`

> [!IMPORTANT]
> Skipping step 1 is the easiest way to end up with a surprise Elastic IP bill — an unassociated EIP still accrues hourly charges.

---

## Final Architecture Diagram

![Final Architecture](images/architecture-diagram.svg)

The diagram shows the Phase 1–7 end state: two instances in a Spread placement group on separate racks, an Elastic IP statically associated with instance A, and the `demo-eni` failover path moved from instance A to instance B.

---

## Exam Style Scenario Reference

Quick-recall table of the scenario traps covered in this session's quizzes:

| Scenario Cue | Answer |
|---|---|
| Stop/start without EIP | Public IP changes, private IP doesn't |
| SSH to private IP from outside the VPC | Fails without VPN/Direct Connect |
| Two VPCs with the same private IP range | Not a problem — private IPs are only unique per network |
| Need a fixed public IP across restarts | Elastic IP |
| Unassociated Elastic IP | Still billed hourly |
| Fleet-wide fixed endpoint, AWS's recommendation | Route 53 + Load Balancer, not per-instance EIPs |
| Lowest latency, single AZ, correlated failure OK | Cluster placement group |
| Few critical instances, isolate hardware failure | Spread placement group (7/AZ max) |
| Hundreds of partition-aware nodes (Cassandra, HDFS, Kafka) | Partition placement group |
| Fastest, cheapest way to move a static private IP to a new instance | Move the ENI |
| Two ENIs, two public IPs on one instance | Not reliable without custom routing |
| `uptime` unchanged across a stop/start cycle | Hibernate, not a plain stop |
| Root volume requirement for hibernation | EBS-backed, encrypted, large enough for full RAM |
| Max hibernation duration | 60 days |

---

## Cleanup Checklist

- [ ] Elastic IPs disassociated and released
- [ ] Manually created ENIs deleted
- [ ] All lab instances terminated
- [ ] Placement groups deleted (only possible once empty)
- [ ] Confirm no lingering EBS volumes left orphaned (check if Delete on Termination was set)