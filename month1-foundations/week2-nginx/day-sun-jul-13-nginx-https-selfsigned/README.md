# Nginx + HTTPS with a Self-Signed Certificate

**Date:** Sun, Jul 13
**Topic:** Networking — TLS / Self-Signed Certificates / Nginx
**Environment:** Ubuntu 25.10 (Questing) in UTM · nginx/1.28.0

---

## Goal
Understand how HTTPS/TLS works, then build a working HTTPS web server from
scratch on Nginx using a self-signed certificate, including an HTTP→HTTPS redirect.

## What I Did (end to end)

- Learned the **fundamentals**: the 3 properties of HTTPS, the TLS handshake,
  certificate anatomy, and self-signed vs CA-signed tradeoffs.
- Installed **Nginx** and confirmed the plaintext HTTP baseline.
- Generated a **self-signed cert + private key** with OpenSSL.
- Inspected the cert and confirmed **Subject == Issuer** (the self-signed giveaway).
- Wrote an **HTTPS server block** (port 443 + ssl) and wired in the cert/key.
- Verified HTTPS via **curl** and a **browser**, and correctly diagnosed the
  browser warning as an **authentication/trust** issue — not broken encryption.
- Added an **HTTP→HTTPS 301 redirect** and verified it with `curl -I`.

## Key Results

**Self-signed cert confirmed (Subject == Issuer):**
```
Issuer:  C=US, ST=Arkansas, L=Centerton, O=menniboefarm, CN=localhost
Subject: C=US, ST=Arkansas, L=Centerton, O=menniboefarm, CN=localhost
Validity: Jul 12 2026 → Jul 12 2027   (from -days 365)
Public-Key: (2048 bit)                (from rsa:2048)
Signature Algorithm: sha256WithRSAEncryption
```

**HTTPS serving works:**
```
curl -k https://localhost   →  returns the site HTML over TLS
```

**Redirect works:**
```
curl -I http://localhost
HTTP/1.1 301 Moved Permanently
Location: https://localhost/
```

## Key Takeaways

- Self-signed and CA-signed certs use **identical encryption**; the only
  difference is **who vouches for identity** (and therefore who trusts it automatically).
- The browser warning on a self-signed cert is an **authentication** failure
  (untrusted issuer), NOT a confidentiality/encryption failure.
- Private key permissions (`-rw-------`, root only) reflect that it's the secret;
  the cert (`-rw-r--r--`) is public and shareable.
- Always run `sudo nginx -t` **before** reloading — validate, then apply.

## Errors / Fixes (see notes.md for detail)
- `systemctl` "unit file changed on disk" warning → fixed with `daemon-reload`.
- nano config edit nested a `server {}` inside another and left old lines →
  fixed cleanly by rewriting the whole file with `tee << EOF`.

