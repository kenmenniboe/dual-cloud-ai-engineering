# TCP/IP Model + CIDR Math — Fundamentals to Advanced

## Summary

Full tutoring session covering the TCP/IP networking model and CIDR/subnetting math, from first principles through applied AWS/Azure subnet design. Built up binary fluency, subnet mask logic, and VLSM subnet range calculations entirely by hand before mapping each concept to real cloud networking scenarios.

## Topics Covered

- **TCP/IP 4-Layer Model** — Application, Transport, Internet, Network Access
- **MAC vs. IP addressing** — hardware identity vs. network location, DHCP, default gateway routing
- **Binary fundamentals** — bit values, powers of 2, binary-to-decimal conversion
- **Subnet masks** — network bits vs. host bits, octet-boundary and mid-octet splits
- **CIDR notation** — converting between `/prefix` and dotted-decimal subnet masks
- **Host count math** — `2^(host bits) − 2` formula, sizing subnets to device requirements
- **Subnet ranges & VLSM** — network address, first/last usable IP, broadcast address; splitting one CIDR block into multiple equal subnets

## Key Outputs

- Correctly derived subnet masks and CIDR prefixes for `/8`, `/16`, `/24`, `/26`, `/27`, `/28` from binary first principles
- Calculated usable host counts for multiple subnet sizes (`/24` = 254, `/26` = 62, `/27` = 30, `/28` = 14)
- Designed a full 4-tier VPC subnet layout by hand: split `10.0.0.0/24` into 4× `/26` subnets (public web, private app, database, management/bastion), each with 62 usable hosts
- Manually calculated complete subnet ranges (network / first usable / last usable / broadcast) for both clean `/24` boundaries and mid-octet `/26` splits

## Real-World Cloud Connections

- Mapped MAC/IP/DHCP behavior to AWS ENIs and default gateway routing within a VPC subnet
- Connected CIDR math directly to VPC/VNet CIDR block sizing (`10.0.0.0/16`, subnet carving)
- Noted the AWS-specific reservation of 5 IPs per subnet (vs. the standard 2) for DNS, routing, and future use

## Next Steps

- Build the 4-tier `10.0.0.0/24` design hands-on in an AWS VPC and verify calculated ranges against the console
- Continue toward AZ-104 / AWS SAA subnetting objectives with more VLSM practice (unequal-sized subnet splits)