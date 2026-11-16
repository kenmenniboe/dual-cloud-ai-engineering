# Week 1 — Commands Reference

All resource provisioning this session was done through the AWS Management Console. The commands below are the terminal commands actually run *after* connecting to an instance, grouped by the stage they belong to.

## Module 1 — IP Behavior Verification

```bash
# SSH in using the instance's public IPv4 — works
ssh -i /path/to/your-key.pem ec2-user@<public-ipv4>

# SSH in using the instance's private IPv4 from an outside network — fails / times out
ssh -i /path/to/your-key.pem ec2-user@<private-ipv4>
```

```bash
# After stopping and starting the instance, reconnect with the NEW public IPv4
ssh -i /path/to/your-key.pem ec2-user@<new-public-ipv4>
```

## Module 2 — Elastic IP Verification

```bash
# SSH in using the associated Elastic IP
ssh -i /path/to/your-key.pem ec2-user@<elastic-ip>

# After stop/start, reconnect with the SAME Elastic IP — no change expected
ssh -i /path/to/your-key.pem ec2-user@<elastic-ip>
```

## Module 5 — Hibernate Verification

```bash
# Check uptime before hibernating
uptime

# ... hibernate the instance via the console (Instance state > Stop instance > Hibernate), then start it again ...

# Check uptime again after start — should CONTINUE counting, not reset to 0
uptime
```

## Combined Demo — Phase 3 (Baseline Networking)

```bash
ssh -i /path/to/your-key.pem ec2-user@<demo-instance-a-public-ip>
```

## Combined Demo — Phase 6 (Hibernate Test on Instance A)

```bash
uptime
# disconnect, hibernate + restart instance A via console, then reconnect
uptime
```