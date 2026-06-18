# AWS IAM, SSH Key Pairs & Route 53 DNS — Session Notes

---

## 1. Creating an IAM User

### Why IAM Users Over Root?
- Root account has **unlimited, unrestricted access** — cannot be limited
- IAM users can be assigned **least privilege** permissions
- If an IAM user is compromised, the blast radius is contained
- This follows the **Zero Trust / Least Privilege** security model

### Steps
1. AWS Console → search **IAM** → open IAM Dashboard
2. Left sidebar → **Users** → **Create user**
3. Enter username: `demo-user`
4. Check **"Provide user access to the AWS Management Console"**
5. Select **Custom password** → enter a password
6. Uncheck **"Users must create a new password at next sign-in"** (for lab)
7. Click **Next**

### Set Permissions
1. Select **Attach policies directly**
2. Search for `AdministratorAccess`
3. Check the box → **Next**
4. Review summary → **Create user**

> 📸 _Screenshot placeholder: IAM user creation success page_

---

## 2. Enabling MFA on IAM User

### Why MFA?
- Adds a second layer of security beyond username/password
- Even if password is stolen, attacker still can't sign in
- Principle: **something you know** (password) + **something you have** (phone)

### Steps
1. IAM → **Users** → click **demo-user**
2. Click **Security credentials** tab
3. Under **Multi-factor authentication (MFA)** → **Assign MFA device**
4. Name the device: `demo-user-mfa`
5. Select **Authenticator app** → **Next**
6. Open authenticator app on phone → tap **+** → **Scan QR code**
7. Scan the QR code shown in the console
8. Enter **MFA code 1** from the app
9. Wait ~30 seconds → enter **MFA code 2**
10. Click **Add MFA**

> 📸 _Screenshot placeholder: MFA successfully assigned_

---

## 3. Cost Budget Alert

### Why Set a Budget Alert?
- Lab resources left running = unexpected AWS charges
- Budget alerts act as a **safety net** for forgotten resources
- Best practice for all learners and personal AWS accounts

### Steps
1. AWS Console → search **Billing** → **Billing and Cost Management**
2. Left sidebar → **Budgets** → **Create budget**
3. Select **Use a template (simplified)**
4. Choose **Monthly cost budget**
5. Fill in:
   - **Budget name:** `monthly-budget`
   - **Budgeted amount:** `$10`
   - **Email recipients:** your email address
6. Click **Create budget**

> 📸 _Screenshot placeholder: Budget created confirmation_

---

## 4. SSH Key Pair

### What Is a Key Pair?
- Used to securely SSH into EC2 instances
- AWS gives you a **private key** (`.pem` file) — store it safely
- AWS keeps the **public key** on the EC2 instance
- If you lose the `.pem` file, you **cannot recover it** — must create a new key pair

### File Formats
| Format | Use Case |
|--------|----------|
| `.pem` | Mac/Linux or Windows with OpenSSH |
| `.ppk` | Windows with PuTTY (older style) |

### Steps
1. AWS Console → search **EC2** → EC2 Dashboard
2. Left sidebar → **Network & Security** → **Key Pairs**
3. Click **Create key pair**
4. Fill in:
   - **Name:** `demo-keypair`
   - **Key pair type:** RSA
   - **Format:** `.pem`
5. Click **Create key pair** — browser auto-downloads the `.pem` file

### Store Key Safely on macOS
```bash
# Move key to ~/.ssh/
mv ~/Downloads/demo-keypair.pem ~/.ssh/

# Set correct permissions (required by SSH)
chmod 400 ~/.ssh/demo-keypair.pem
```

> ⚠️ SSH will **reject** your key if permissions are too open — `chmod 400` is required.

### Connecting to EC2 with SSH
```bash
ssh -i ~/.ssh/demo-keypair.pem ec2-user@<public-ip>
```
- `-i` = identity file (your key)
- `ec2-user` = default username for Amazon Linux
- `<public-ip>` = found in EC2 Console → Instances → Public IPv4 address

> 📸 _Screenshot placeholder: EC2 instance public IP in console_

### Note on Other Cloud Keys
- **AWS SSH keys** → `~/.ssh/` ✅
- **Azure SSH keys** → `~/.ssh/` ✅
- **RDP (Windows)** → uses username/password + `.rdp` file (not `.pem`)

---

## 5. Route 53 DNS Configuration

### Key Concepts

| Record Type | Purpose |
|-------------|---------|
| **A record** | Maps domain name → IPv4 address |
| **NS record** | Points to authoritative name servers for the domain |
| **SOA record** | Start of Authority — metadata about the zone |

### What Is a Hosted Zone?
- A container for DNS records for a specific domain
- **Public** = resolves DNS for the internet (anyone can access)
- **Private** = resolves DNS only within a VPC (internal traffic)

### What Is an NS Record?
- Tells the internet **which name servers are authoritative** for your domain
- When you register a domain, you point it to these NS records so Route 53 manages DNS

### Steps — Create Hosted Zone
1. AWS Console → search **Route 53** → Route 53 Dashboard
2. Left sidebar → **Hosted zones** → **Create hosted zone**
3. Fill in:
   - **Domain name:** `demo.com`
   - **Type:** Public hosted zone
4. Click **Create hosted zone**
5. Default **NS** and **SOA** records are auto-created

> 📸 _Screenshot placeholder: Hosted zone created with NS and SOA records_

### Steps — Create A Record
1. Inside the hosted zone → **Create record**
2. Fill in:
   - **Record name:** `www` (or leave blank for root domain)
   - **Record type:** A
   - **Value:** EC2 public IP address (e.g. `54.0.0.1` for demo)
3. Click **Create records**

> 📸 _Screenshot placeholder: A record created successfully_

### Real-World Use
In a real deployment:
- Get your **EC2 public IP** from EC2 Console → Instances → Public IPv4 address
- Enter that IP as the **A record value**
- Traffic to `demo.com` routes directly to your EC2 instance

---

## Summary of Key Security Concepts

| Concept | Description |
|---------|-------------|
| Least Privilege | Only grant the access a user actually needs |
| MFA | Two-factor: password + authenticator app |
| Root Account | Avoid using — unlimited access, cannot be restricted |
| chmod 400 | Locks `.pem` file so only owner can read it |
| Budget Alert | Safety net against forgotten lab resources |