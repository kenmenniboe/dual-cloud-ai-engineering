# Day: TCP vs UDP, Ports, DNS Deep Dive, HTTP/HTTPS + TLS Handshake

## Summary
Socratic tutoring session covering the transport layer and application layer
fundamentals that sit on top of the IP/CIDR work from previous sessions.

## Topics Covered
1. Ports & the Transport Layer (why ports exist, well-known vs dynamic ports)
2. TCP vs UDP (connection-oriented vs connectionless, reliability tradeoffs)
3. DNS Deep Dive (recursive resolution chain, caching/TTL, A vs CNAME records)
4. HTTP/HTTPS + TLS Handshake (certificates, CAs, DNS validation, handshake order)

## Why This Matters
Ties directly into the `menniboefarm.com` ACM + ALB + Route 53 setup from the
SonarQube-on-Fargate build — this session connects the theory (why CNAME over
A record for an ALB, why DNS validation proves domain ownership, why TLS rides
on top of TCP) to that actual deployed stack.


See `notes.md` for the full concept breakdown.