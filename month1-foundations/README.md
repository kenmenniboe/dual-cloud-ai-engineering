# Networking Fundamentals — Master Study Notes

A consolidated, concept-focused reference covering the full networking
fundamentals curriculum. Built from multiple tutoring sessions and anchored
throughout to real cloud infrastructure (AWS VPC, Route 53, ACM, ALB, and a
self-signed Nginx HTTPS lab). Formatted for study and review.

---

## 1. The TCP/IP Model (4 Layers)

Networking is broken into four stacked layers, each with one job, handing off
to the layer above or below.

| Layer | Job | Examples |
|---|---|---|
| **Application** | What the data *means* | HTTP, DNS, SSH |
| **Transport** | Reliable (TCP) vs. fast (UDP) delivery | TCP, UDP, ports |
| **Internet** | Addressing & routing | IP addresses |
| **Network Access** | Physical/electrical delivery | Ethernet, Wi-Fi |

**Analogy — mailing a package internationally:**
- Application = the letter, written in a language the recipient understands
- Transport = tracked/signed shipping (reliable) vs. dropping it in a mailbox (best-effort)
- Internet = the street address and postal routing that finds the right house
- Network Access = the truck, plane, and roads physically moving the box

**Cloud tie-in:** SSH into EC2 → terminal (Application) uses TCP (Transport) to
guarantee ordered keystrokes, routed via the instance IP (Internet), riding over
a virtual network interface (Network Access).

---

## 2. The OSI Model (Layers 1–4)

OSI is a more granular 7-layer model; layers 1–4 are the foundation.

| Layer | Name | Unit | Job |
|---|---|---|---|
| 1 | **Physical** | bits | Electrical/optical signals on the wire |
| 2 | **Data Link** | frames | Hop-to-hop delivery via MAC addresses |
| 3 | **Network** | packets | End-to-end delivery via IP addresses |
| 4 | **Transport** | segments | Service-to-service delivery via ports |

**Key distinction:** MAC addresses are rewritten at *every hop*; the IP address
stays constant *end-to-end*. ARP is the mechanism that links the two.

---

## 3. Addressing: MAC vs. IP

- **MAC address** = hardware identity, burned into the network card (like a
  person's fingerprint — permanent, tied to the device).
- **IP address** = network location, assigned by the network (like a mailing
  address — changes depending on where you are).
- **DHCP** automatically hands out IP addresses, subnet masks, default gateway,
  and DNS server to devices joining a network.
- **Default gateway** = the router a device sends traffic to when the
  destination is *outside* its own subnet.

**Four requirements for a host to reach the internet:**
1. IP address (its identity on the network)
2. Subnet mask (defines what's local vs. remote)
3. Default gateway (the exit door to other networks)
4. DNS server (translates names to IPs)

Diagnostic pattern: missing gateway → can reach local hosts but not the
internet; missing DNS → can ping IPs but names don't resolve.

---

## 4. ARP (Address Resolution Protocol)

- Resolves a known **IP address** to its **MAC address** on the local network.
- Process: a device broadcasts "who has IP x.x.x.x?"; the owner replies with its
  MAC; the result is **cached** to avoid repeating the lookup.
- This is the glue between OSI Layer 3 (IP) and Layer 2 (MAC).

---

## 5. Network Devices

| Device | Operates at | Role |
|---|---|---|
| **Repeater** | Physical | Boosts a weak signal |
| **Hub** | Physical | Dumb repeater to all ports (obsolete) |
| **Bridge** | Data Link | Connects two network segments |
| **Switch** | Data Link | Smart forwarding *within* a network (switching) |
| **Router** | Network | Forwards *between* networks (routing) |

Rule of thumb: **routers** connect different networks; **switches** connect
devices within the same network.

---

## 6. Binary & IP Address Basics

- An IPv4 address = 4 octets (32 bits total), each octet 0–255.
- Each bit position in an octet has a value: 128, 64, 32, 16, 8, 4, 2, 1.
- Binary → decimal: add the values of the positions that are `1`.
  - e.g. `11000000` = 128 + 64 = **192**
- This binary fluency is the foundation for subnet masks and CIDR.

---

## 7. Subnet Masks & CIDR Notation

- A subnet mask splits an IP into a **network portion** (the `1` bits) and a
  **host portion** (the `0` bits).
- **CIDR notation** (`/prefix`) counts the network bits.
  - `/24` = 255.255.255.0 · `/26` = 255.255.255.192 · `/16` = 255.255.0.0
- More network bits = smaller subnet (fewer hosts); fewer = larger subnet.

**Host count formula:** `usable hosts = 2^(host bits) − 2`
- Subtract 2 for the **network address** (all host bits 0) and the
  **broadcast address** (all host bits 1) — neither is assignable to a device.

| Prefix | Host bits | Usable hosts |
|---|---|---|
| /24 | 8 | 254 |
| /26 | 6 | 62 |
| /27 | 5 | 30 |
| /28 | 4 | 14 |

**AWS caveat:** AWS reserves **5** IPs per subnet, not 2 (network, VPC router,
DNS, future use, broadcast). So in AWS specifically:
`usable = 2^(host bits) − 5`.

---

## 8. Subnet Ranges & VLSM

For any subnet, four addresses define it:
- **Network address** — all host bits 0 (first address, not usable)
- **First usable** — network + 1
- **Last usable** — broadcast − 1
- **Broadcast address** — all host bits 1 (last address, not usable)

**VLSM (Variable Length Subnet Masking)** = splitting one CIDR block into
multiple subnets, sized to need.

**Worked cloud example — a 4-tier VPC:** split `10.0.0.0/24` into four `/26`
subnets (62 usable hosts each):
- `10.0.0.0/26` — public web tier
- `10.0.0.64/26` — private app tier
- `10.0.0.128/26` — database tier
- `10.0.0.192/26` — management / bastion tier

---

## 9. Special-Use IP Ranges

- **Private (RFC 1918):** `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`
- **Loopback:** `127.0.0.1` (the host itself)
- **APIPA:** `169.254.x.x` (self-assigned when DHCP fails)
- **Broadcast / multicast:** reserved ranges for one-to-all / one-to-many.

---

## 10. Ports & the Transport Layer

- IP gets traffic to the right **computer**; the **port** gets it to the right
  **application** on that computer (building address vs. apartment number).
- Without ports, a host running a web server + database on one IP couldn't route
  incoming traffic internally.

**Port ranges:**
- **0–1023** — well-known (SSH=22, HTTP=80, HTTPS=443); standardized so software
  doesn't have to guess.
- **1024–49151** — registered (specific applications).
- **49152–65535** — dynamic/ephemeral; let a machine track many simultaneous
  connections to the same destination (3 browser tabs to google.com:443 each get
  a different local port).

A **socket** = the unique combination of (source IP, source port, dest IP, dest port).

---

## 11. TCP vs. UDP

| | TCP | UDP |
|---|---|---|
| Connection | Connection-oriented (3-way handshake: SYN, SYN-ACK, ACK) | Connectionless |
| Guarantees | Delivery + ordering | None |
| Overhead | Higher | Low / fast |
| Use for | Downloads, SSH, APIs, databases | Video/voice, streaming, DNS |

Choose based on whether **correctness** or **speed/continuity** matters more.

- **DNS mostly uses UDP** — queries are tiny (<512 bytes), so a TCP handshake
  would be pure overhead. Falls back to TCP for large responses (zone transfers).
- **SSH always uses TCP** — a terminal session can't tolerate dropped or
  out-of-order commands.

---

## 12. DNS Deep Dive

- Resolution is a **hierarchical recursive chain:**
  resolver → root server → TLD server (.com) → **authoritative name server**.
- The **authoritative name server** is the single source of truth for a domain's
  records; root/TLD servers are just signposts pointing toward it.
  - In AWS, a **Route 53 hosted zone** = the authoritative name server for the domain.
- **Caching + TTL:** resolvers cache answers for the TTL duration, so root/
  authoritative servers aren't hit on every request — this is what lets DNS scale
  to billions of daily lookups.
  - Lower the TTL *before* a planned migration so caches refresh quickly during
    cutover; raise it back afterward for efficiency.

**Record types:**
- **A record** — domain → a fixed IP address.
- **CNAME record** — domain → another domain name (not a fixed IP).
  - Use CNAME (or Route 53 ALIAS) to point at an **ALB's DNS name**, since the
    ALB's underlying IP can change. Never hardcode an ALB IP in an A record.

---

## 13. Encapsulation / De-encapsulation

As data moves *down* the stack on send, each layer wraps it:
- Data → **segment** (Transport adds ports) → **packet** (Network adds IPs) →
  **frame** (Data Link adds MACs) → **bits** (Physical).

On receive, the process reverses (de-encapsulation), each layer stripping its
header until the application gets the original data.

---

## 14. HTTP, HTTPS & the Three Properties

- **HTTP** = plaintext — readable by anyone on the path (MITM risk).
- **HTTPS** = HTTP wrapped in a **TLS** encryption layer.

HTTPS provides **three** properties:
1. **Confidentiality** — nobody in the middle can read the data (sealed envelope).
2. **Integrity** — tampering is detected (tamper-evident seal), via **hashes**.
3. **Authentication** — you're talking to the real server, not an impostor
   (verified return address); prevents **Man-in-the-Middle (MITM)** attacks.

**Hashes (checksums):** a fixed-length "fingerprint" of data; changing one bit
changes it completely. Sender sends data + hash; receiver recomputes and compares.
This is why software downloads show a SHA-256 checksum.

---

## 15. The TLS Handshake

TLS uses **two kinds of encryption:**
- **Asymmetric** (handshake only): a **key pair** — public key (shared freely) +
  private key (never leaves the server). Locked with public → only private opens.
  (Same idea as an EC2 `.pem` file.)
- **Symmetric** (everything after): one shared secret key, fast.

**Why both?** Asymmetric solves "strangers agreeing on a secret" but is slow;
symmetric is fast but needs a pre-shared secret. TLS uses asymmetric just long
enough to establish a shared **session key**, then switches to symmetric.

**Handshake order (TLS runs *after* the TCP handshake):**
1. Client hello
2. Server sends its **certificate** (contains its public key)
3. Client **verifies the certificate signature** against its trusted CA list ← *identity first*
4. Asymmetric crypto establishes a shared **session key**
5. Switch to fast **symmetric** encryption for all real data

> Verification happens *before* key exchange — this is why MITM attacks fail
> (the impostor is rejected at step 3).

Full request lifecycle: **DNS resolution → TCP handshake → TLS handshake → encrypted HTTP request.**

---

## 16. Certificates & Certificate Authorities

A TLS certificate (X.509) is a structured file with these core fields:

| Field | Meaning |
|---|---|
| **Subject** | Who the cert is *for* (the domain) |
| **Public Key** | The server's public key |
| **Issuer** | Who *signed* it (the CA) |
| **Validity** | Not-before / not-after (expiration) |
| **Signature** | The signer's digital signature over everything above |

- A **CA (Certificate Authority)** is a trusted third party whose public keys ship
  pre-installed in browsers/OSes. The CA signs a server's cert with the CA's
  private key; the browser verifies it with the CA's public key.
- The signature covers the whole cert — change one byte and it no longer validates.
  An attacker can't forge it without the CA's private key.
- **DNS validation** (used by ACM) proves domain ownership because only the real
  owner can add the required DNS record.

---

## 17. Self-Signed vs. CA-Signed Certificates

**The encryption is identical.** The only difference is *who vouches for identity*
and therefore *who trusts the cert automatically*.

| | Self-signed | CA-signed |
|---|---|---|
| Signed by | You (Subject == Issuer) | A trusted CA (Subject ≠ Issuer) |
| Browser trusts automatically | No (warning) | Yes |
| Good for | Labs / internal tools | Public production |

- A **self-signed cert has Subject == Issuer** — the instant giveaway.
- A browser's warning on a self-signed cert is an **authentication** failure
  (untrusted issuer), *not* an encryption failure. The tunnel is fully encrypted.
- **Decision rule — "who needs to trust this server?"** Only me/my machines →
  self-signed (I can update those trust stores). The public → CA-signed.
- **Common misconception:** "self-signed = weak encryption." False — encryption is
  identical; only identity is unverified. (It's also not *more* secure.)

**Cloud tie-in:** the ACM cert on `menniboefarm.com` is the CA-signed path
(Amazon = the CA); a homemade OpenSSL cert on an internal box is the self-signed
equivalent.

---

## 18. Applied Lab — Nginx HTTPS with a Self-Signed Cert

Concept summary of the hands-on build (Ubuntu + Nginx):
- Generated a self-signed cert + 2048-bit RSA key with OpenSSL; verified
  Subject == Issuer.
- Private key auto-locked to root-only permissions; cert world-readable — the
  file-system reflection of "public cert, secret key."
- Configured an Nginx **server block on port 443** with `ssl`, pointing to the
  cert and key.
- Browser showed the expected untrusted-issuer warning; page still loaded over a
  fully encrypted tunnel (proving it's a trust issue, not encryption).
- Added an **HTTP→HTTPS 301 redirect** so plain-HTTP visitors are auto-upgraded
  (`301` = permanent, cached by browsers; preserves the original path/query).
- Habit reinforced: always validate config before applying (`nginx -t`), then reload.

---

## Acronym Glossary

- **IP** — Internet Protocol (network addressing)
- **MAC** — Media Access Control (hardware address)
- **TCP** — Transmission Control Protocol (reliable, ordered)
- **UDP** — User Datagram Protocol (fast, connectionless)
- **OSI** — Open Systems Interconnection (7-layer reference model)
- **ARP** — Address Resolution Protocol (IP → MAC)
- **DHCP** — Dynamic Host Configuration Protocol (auto IP assignment)
- **DNS** — Domain Name System (name → IP)
- **TTL** — Time To Live (cache duration)
- **APIPA** — Automatic Private IP Addressing (169.254.x.x fallback)
- **CIDR** — Classless Inter-Domain Routing (`/prefix` notation)
- **VLSM** — Variable Length Subnet Masking
- **FTP** — File Transfer Protocol
- **SMTP** — Simple Mail Transfer Protocol
- **HTTP / HTTPS** — HyperText Transfer Protocol (Secure)
- **SSL / TLS** — Secure Sockets Layer / Transport Layer Security
- **CA** — Certificate Authority
- **VPC** — Virtual Private Cloud (AWS)
- **VNet** — Virtual Network (Azure)
- **AZ** — Availability Zone
- **ENI** — Elastic Network Interface (AWS)
- **ALB / NLB** — Application / Network Load Balancer
- **ACM** — AWS Certificate Manager
- **AWS SAA** — AWS Solutions Architect Associate

---

## Study Connections (theory → real build)

Every concept maps to the `menniboefarm.com` stack:
- CIDR/VLSM → VPC subnet design
- DNS/TTL/CNAME → Route 53 hosted zone pointing at an ALB
- TLS handshake + certificates → ACM cert on the ALB
- Self-signed certs → the Nginx lab, contrasted against the ACM (CA-signed) path