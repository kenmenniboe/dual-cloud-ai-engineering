# Notes: TCP/UDP, Ports, DNS, HTTP/HTTPS + TLS

## Module 1 — Ports & the Transport Layer

- IP address = gets a packet to the right **computer** (the building).
- Port number = gets it to the right **application** on that computer (the apartment).
- Without ports, a server running multiple services (web server + database, etc.)
  on one IP would have no way to route incoming traffic internally.
- Port ranges:
  - **0–1023**: Well-known ports (SSH=22, HTTPS=443) — standardized so software
    doesn't need to guess or ask.
  - **1024–49151**: Registered ports (specific applications).
  - **49152–65535**: Dynamic/ephemeral ports — used so a machine can track
    multiple simultaneous connections to the same destination (e.g. 3 browser
    tabs all hitting google.com:443, each gets a different local port).
- The unique combo of (your IP, your port, their IP, their port) = a **socket**.

## Module 2 — TCP vs UDP

- **TCP** (connection-oriented): 3-way handshake (SYN, SYN-ACK, ACK) before
  data flows. Guarantees delivery + order. Higher overhead.
  - Use cases: downloads, SSH, APIs, databases — anywhere correctness > speed.
- **UDP** (connectionless): no handshake, no guarantee of delivery/order.
  Lightweight and fast.
  - Use cases: video/voice calls, live streaming, DNS — anywhere
    speed/continuity > perfection.
- DNS mostly uses UDP because queries/responses are tiny (often <512 bytes) —
  paying for a TCP handshake would be pure overhead relative to the actual
  data being exchanged. (DNS falls back to TCP for large responses like zone
  transfers.)
- SSH always uses TCP — a remote terminal session can't tolerate
  out-of-order or silently dropped commands.

## Module 3 — DNS Deep Dive

- DNS resolution is a **hierarchical recursive chain**:
  resolver → root server → TLD server (.com) → **authoritative name server**
- The authoritative name server is the one true source of truth for a
  domain's actual records (A, CNAME, MX, etc.). Root/TLD servers are just
  signposts pointing toward it.
- In AWS, standing up a Route 53 hosted zone = standing up the authoritative
  name server for that domain.
- **Caching + TTL**: resolvers cache answers for a set time (TTL) so root/
  authoritative servers aren't hit on every single request — this is what
  lets DNS scale to billions of daily lookups.
  - Lower TTL before a planned migration so caches refresh faster during
    cutover; raise it back afterward for efficiency.
- **A record**: domain → fixed IP address.
- **CNAME record**: domain → another domain name (not a fixed IP).
  - Use CNAME (or Route 53 ALIAS) for pointing to an ALB's DNS name, since
    the ALB's underlying IP can change — CNAME always resolves to whatever
    IP AWS currently has behind that name. Never hardcode an ALB's IP in an
    A record.

## Module 4 — HTTP/HTTPS + TLS Handshake

- HTTP = plain text (readable by anyone intercepting traffic — MITM risk).
- HTTPS = HTTP + **TLS** encryption layer.
- TLS handshake (happens after the TCP handshake, before any HTTP request):
  1. Browser + server agree on supported encryption methods.
  2. Server presents its **certificate** to prove identity.
  3. Browser checks the cert is signed by a trusted **Certificate Authority
     (CA)** and matches the domain.
  4. Both sides derive a shared encryption key.
  5. Only now does the actual HTTP request/response flow, fully encrypted.
- Certificates matter because they come from a trusted third-party CA —
  a self-issued certificate proves nothing (anyone could claim to be anyone).
- **DNS validation** (used by ACM) proves domain ownership because only the
  actual owner has access to add records in that domain's DNS zone (e.g.
  Route 53) — an attacker has no way to do this.
- Order of operations: **IP → TCP handshake → TLS handshake → HTTP request/
  response**. TLS relies on TCP's reliable, ordered delivery to exchange its
  (fairly large) handshake messages and certificate data — this is why TLS
  is built to run on top of TCP rather than UDP.

## Real-World Tie-In (menniboefarm.com)

- Route 53 hosted zone = authoritative name server for the domain.
- ALB gets a CNAME (not a hardcoded A record) because its IP can change.
- ACM certificate is verified via DNS validation (a CNAME record added to
  Route 53), proving ownership before AWS issues the cert.
- That ACM cert is what the ALB presents during the TLS handshake step 2
  above — the "ID card" that lets browsers trust the connection.