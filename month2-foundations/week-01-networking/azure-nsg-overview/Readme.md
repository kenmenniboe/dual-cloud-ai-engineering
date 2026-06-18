# Azure Network Security Groups (NSG) — Fundamentals

**Date:** Tue Jun 10, 2026
**Topic:** AZ-104 — Network Security Groups (NSG)
**Track:** Azure (AZ-104)

---

## What I Learned

- What an NSG is and how it filters network traffic at Layer 4
- Where NSGs can be attached — subnet level and NIC level
- How Azure evaluates NSGs when both are applied to the same VM
- The 5 components of every NSG security rule
- How priority numbers determine rule evaluation order
- The 3 default inbound and 3 default outbound rules built into every NSG

## Key Outcomes

- Can explain the difference between subnet-level and NIC-level NSG attachment
- Understand inbound vs outbound evaluation order (Subnet → NIC inbound, NIC → Subnet outbound)
- Know that both NSGs must allow traffic — one deny anywhere in the chain blocks it
- Understand default rules and how the DenyAll at priority 65500 acts as the safety net
- Can design a minimal ruleset (e.g. allow 80 + 443, let default deny handle the rest)

## Modules Covered

- Module 1: What is an NSG
- Module 2: NSG Security Rules and Priority

## Up Next

- Module 3: Service Tags and Application Security Groups (ASGs)
- Advanced: NSG Flow Logs, diagnostics, exam edge cases