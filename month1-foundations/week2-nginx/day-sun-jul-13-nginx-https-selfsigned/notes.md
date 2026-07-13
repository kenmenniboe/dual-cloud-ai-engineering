# Notes — Nginx + HTTPS with a Self-Signed Certificate

A reference guide covering both the TLS/HTTPS theory and the hands-on Nginx lab
on Ubuntu 25.10 in UTM.

---

## PART 1 — FUNDAMENTALS

### 1. Why HTTPS? (The Problem It Solves)

Plain **HTTP sends data as plaintext** — readable by anyone on the network path.
- Analogy: HTTP = a postcard; HTTPS = a sealed envelope.
- Over HTTP, logins/passwords travel in the clear (coffee-shop wifi, ISP, etc.).

HTTPS wraps HTTP in a TLS tunnel and provides **three** properties:

| Property | Meaning | Analogy |
|---|---|---|
| **Confidentiality** | Nobody in the middle can read the data | Sealed envelope |
| **Integrity** | Tampering is detected | Tamper-evident seal |
| **Authentication** | You're talking to the real server, not an impostor | Verified return address |

**Integrity → hashes (checksums):** a hash is a fixed-length "fingerprint" of data.
Change one bit → completely different fingerprint. Sender sends data + hash;
receiver recomputes and compares. This is why downloads show a **SHA-256 checksum**.

**Authentication → stops MITM:** even with a perfect encrypted tunnel, you still
need to know *who* is on the other end. Without identity checks, an attacker can
impersonate a site (**Man-in-the-Middle**). The certificate + CA provide this.

### 2. The TLS Handshake

Uses **two kinds of encryption**:

- **Asymmetric** (handshake only): a **key pair** — public key (shared freely) +
  private key (never leaves the server). Locked with public → only private unlocks.
  Analogy: server mails out open padlocks; only its key opens the boxes.
  (Same idea as an EC2 `.pem`: AWS holds the public key, you hold the private key.)
- **Symmetric** (everything after): one shared secret key, encrypts + decrypts, fast.

**Why both?** Asymmetric is slow but solves "strangers agreeing on a secret";
symmetric is fast but needs a pre-shared secret. TLS uses asymmetric just long
enough to establish a shared **session key**, then switches to symmetric.

**Handshake order (important):**
1. Client hello
2. Server sends its **certificate** (contains its public key)
3. Client **verifies the cert signature** against its trusted CA list ← *identity first*
4. Asymmetric crypto establishes a shared **session key**
5. Switch to fast **symmetric** encryption for all real data

> Verification (3) happens BEFORE key exchange (4). That ordering is why MITM
> fails — the attacker is rejected at step 3.

### 3. What's Inside a Certificate (X.509)

| Field | Meaning |
|---|---|
| **Subject** | Who the cert is *for* (e.g. `CN=localhost`) |
| **Public Key** | The server's public key |
| **Issuer** | Who *signed* it (the CA) |
| **Validity** | Not-before / not-after (expiration) |
| **Signature** | The signer's digital signature over everything above |

- **Self-signed → Subject == Issuer** (you signed your own cert).
- The signature covers everything; change one byte → it no longer validates.
- Attacker can't forge it without the signer's **private key**.

**Inspect a cert:**
```bash
openssl x509 -text -noout -in cert.pem
```

**Trusting a self-signed cert (so the warning stops):**
- macOS: import into **Keychain Access** → "Always Trust".
- Linux: copy to `/usr/local/share/ca-certificates/` → `sudo update-ca-certificates`.
- Works only on machines you control — impossible for the public internet
  (can't touch strangers' trust stores → that's why public CAs exist).

### 4. Self-Signed vs CA-Signed

Same encryption. Only difference = who vouches for identity / who trusts it automatically.

| | Self-signed | CA-signed |
|---|---|---|
| Encryption | Identical | Identical |
| Signed by | You | A trusted CA |
| Browser trusts automatically | ❌ (warning) | ✅ |
| Good for | Labs / internal | Public production |

**Decision rule — "who needs to trust this server?"** Only me/my machines →
self-signed. The public/strangers → CA-signed.

**Misconception to correct:** "self-signed = insecure encryption." Wrong — the
encryption is identical; only identity is unverified. (Also not *more* secure.)

---

## PART 2 — HANDS-ON LAB (Ubuntu 25.10 in UTM)

### Step 1 — Install Nginx & confirm baseline
```bash
sudo apt update
sudo apt install nginx -y
systemctl status nginx        # look for active (running)
curl http://localhost         # returns default "Welcome to nginx!" page
```
Testing plain HTTP first gives a known-good baseline before adding TLS.

### Step 2 — Generate the self-signed cert + key
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/selfsigned.key \
  -out /etc/nginx/selfsigned.crt
```
Prompts for identity fields — set **Common Name (CN) = localhost** (must match
what you connect to). Flags:
- `-x509` output a self-signed cert (not a CSR) → makes Subject == Issuer
- `-nodes` no passphrase on the key (so Nginx starts without a prompt)
- `-days 365` 1-year validity
- `-newkey rsa:2048` generate a new 2048-bit RSA key pair
- `-keyout` / `-out` where to write the key / cert

### Step 3 — Verify the files & cert
```bash
ls -l /etc/nginx/selfsigned.*
# selfsigned.crt  -rw-r--r--   (public, everyone can read)
# selfsigned.key  -rw-------   (private, root only)  ← auto-locked by openssl

sudo openssl x509 -text -noout -in /etc/nginx/selfsigned.crt
# Confirm Subject == Issuer, 2048-bit key, sha256WithRSAEncryption, CA:TRUE
```

### Step 4 — Add the HTTPS server block
Edit `/etc/nginx/sites-available/default` and add a 443 block:
```nginx
server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate     /etc/nginx/selfsigned.crt;
    ssl_certificate_key /etc/nginx/selfsigned.key;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```
- `listen 443 ssl;` = accept HTTPS on 443 AND enable TLS (the `ssl` keyword matters).
- `ssl_certificate` = public `.crt`; `ssl_certificate_key` = private `.key`.
- `server_name` should match the cert CN (`localhost`) to avoid a name-mismatch warning.

### Step 5 — Validate, then apply
```bash
sudo nginx -t                    # syntax check — do this BEFORE reload
sudo systemctl reload nginx      # graceful apply (no dropped connections)
```

### Step 6 — Test HTTPS
```bash
curl -k https://localhost        # -k skips cert verification (self-signed)
```
Returns the site HTML over TLS. In a browser (inside the VM) go to
`https://localhost` → expect a warning (`SEC_ERROR_UNKNOWN_ISSUER` in Firefox) →
Advanced → Accept the Risk → page loads with a flagged padlock.

**Why the warning:** authentication only. Encryption works; the issuer just
isn't in the browser's trusted CA list (it's you).

### Step 7 — HTTP → HTTPS redirect
Turn the port-80 block into a pure redirect (no root/index/location needed —
`return` fires before any file is served):
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name localhost;

    return 301 https://$host$request_uri;
}
```
- `301` = permanent (browsers/search engines cache it; a `302` wouldn't).
- `$host` = requested hostname; `$request_uri` = full path + query (preserved).

Verify:
```bash
sudo nginx -t
sudo systemctl reload nginx
curl -I http://localhost
# HTTP/1.1 301 Moved Permanently
# Location: https://localhost/
```

---

## ERRORS / FIXES

**1. systemd "unit file changed on disk" warning on reload**
```
Warning: The unit file ... of nginx.service changed on disk.
Run 'systemctl daemon-reload' to reload units.
```
Harmless (Nginx still reloaded), but clear it with:
```bash
sudo systemctl daemon-reload
sudo systemctl reload nginx
```

**2. nano edit created a nested/duplicated server block**
While hand-editing the port-80 block, a second `server {` got pasted *inside*
the first and old directives were left behind → would fail `nginx -t`.
Fix: exit nano without saving, then rewrite the whole file cleanly in one shot:
```bash
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
...clean config...
EOF
```
Lesson: for big/messy config changes, replacing the file with a known-good
version via `tee << EOF` is far less error-prone than nudging lines in nano.

---

## HANDY NANO TIPS
- Search: `Ctrl+W` → text → Enter
- Jump to end of file: `Alt+/`
- Line numbers (toggle): `Alt+Shift+3` · launch with `nano -l` · permanent: `echo "set linenumbers" >> ~/.nanorc`
- Save: `Ctrl+O` → Enter · Exit: `Ctrl+X`

## QUICK RECAP
HTTPS = confidentiality + integrity + authentication. Handshake: verify identity
→ exchange session key → symmetric encryption. Self-signed = Subject == Issuer,
same encryption, unverified identity. Validate config with `nginx -t` before reload.
Redirect HTTP→HTTPS with `return 301 https://$host$request_uri;`.