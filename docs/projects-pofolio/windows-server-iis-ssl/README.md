# 📘 Windows Server / IIS + SSL Certificate

> Three-part reference: Technician Guide · Beginner Walkthrough · Printable Checklist

---

## 📁 GitHub Folder Scaffolding

```bash
mkdir -p windows-server-iis-ssl && touch windows-server-iis-ssl/README.md
```

---

## Part 1 — Technician Reference

### 1. Create the Windows Server VM

- Deploy Windows Server 2019 or 2022
- Assign a static public IP
- Allow inbound ports:
  - `80` (HTTP)
  - `443` (HTTPS)
  - `3389` (RDP)

---

### 2. Install IIS (PowerShell)

**Install IIS:**

```powershell
Install-WindowsFeature -name Web-Server -IncludeManagementTools
```

**Verify IIS installed:**

```powershell
Get-WindowsFeature Web-Server
```

Expected output:

```
[X] Web Server (IIS)
```

**Navigate to IIS web root:**

```powershell
cd C:\inetpub\wwwroot
```

**Create a test webpage:**

```powershell
echo "<h1>Hello from my Windows VM!</h1>" > index.html
```

---

### 3. Configure DNS for the Domain

- Log into your domain registrar
- Create an **A record:**
  - Host: `@`
  - Points to: your VM's public IP
- (Optional) Create a **CNAME:**
  - Host: `www`
  - Points to: `menniboefarm.com`

---

### 4. Add IIS Host Binding ⚠️ Critical Step

1. Open IIS Manager
2. Select **Default Web Site**
3. Click **Bindings… → Add…**
4. Enter exactly:
   - Type: `http`
   - IP address: `All Unassigned`
   - Port: `80`
   - Host name: `menniboefarm.com`
5. Click **OK**

---

### 5. Install win-acme (Let's Encrypt Client)

**Create directory:**

```powershell
New-Item -ItemType Directory -Path C:\win-acme
```

**Download win-acme:**

```powershell
Invoke-WebRequest -Uri https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip -OutFile C:\win-acme\win-acme.zip
```

**Extract the ZIP:**

```powershell
Expand-Archive C:\win-acme\win-acme.zip C:\win-acme -Force
```

**Navigate into the folder:**

```powershell
cd C:\win-acme
```

---

### 6. Request the SSL Certificate

**Run win-acme:**

```powershell
.\wacs.exe
```

- Choose: `N` (Create new certificate)
- Select site: `Default Web Site (http, menniboefarm.com)`
- Accept all defaults for:
  - HTTP validation
  - Installation
  - HTTPS binding
  - Auto-renewal task

---

### 7. Verify HTTPS Binding

- IIS → your site → **Bindings…**
- Confirm:
  - Type: `https`
  - Port: `443`
  - Host name: `menniboefarm.com`
  - SSL certificate: `Let's Encrypt`

---

### 8. Verify Certificate Installation

- IIS Manager → server name → **Server Certificates**
- Confirm cert name: `menniboefarm.com`
- Expiration: ~90 days from today

---

### 9. Auto-Renewal

- win-acme creates a scheduled task automatically
- Certificate renews every ~60 days
- No manual action required

---

## Part 2 — Beginner-Friendly Guide

### What You're Trying to Do

You want to host a website on a Windows Server VM and secure it with HTTPS. Here's the full journey:

1. Create the VM
2. Install IIS (the web server)
3. Connect your domain via DNS
4. Tell IIS which domain belongs to which site
5. Install win-acme to get a free SSL certificate
6. Verify everything is secure

---

### 1. Create Your Windows Server VM

This is the machine that will host your website.

- Deploy Windows Server 2019 or 2022
- Assign a **static public IP** so your domain always points to the same address
- Open firewall / NSG ports: `80`, `443`, `3389`

> ℹ️ Let's Encrypt must reach your server over port 80 to validate your domain. If port 80 is blocked, SSL will fail.

---

### 2. Install IIS (Your Web Server)

IIS is the software that serves your website files to visitors.

```powershell
Install-WindowsFeature -name Web-Server -IncludeManagementTools
```

Verify it worked:

```powershell
Get-WindowsFeature Web-Server
```

Create a test page:

```powershell
cd C:\inetpub\wwwroot
echo "<h1>Hello from my Windows VM!</h1>" > index.html
```

> ℹ️ This confirms IIS is working and serving content before you move on.

---

### 3. Configure DNS for Your Domain

This connects your domain name to your VM's IP address.

- Log into your registrar
- A record: `@` → your VM's public IP
- (Optional) CNAME: `www` → `menniboefarm.com`

> ℹ️ Let's Encrypt checks that your domain resolves to your server. If DNS is wrong, validation fails.

---

### 4. Add the IIS Host Binding

This tells IIS which domain belongs to which website.

- IIS Manager → Default Web Site → Bindings → Add
- Type: `http` | Port: `80` | Host name: `menniboefarm.com`

> ℹ️ Without this binding, win-acme cannot match your domain to your IIS site.

---

### 5. Install win-acme

This tool automatically gets and installs your SSL certificate.

```powershell
New-Item -ItemType Directory -Path C:\win-acme

Invoke-WebRequest -Uri https://github.com/win-acme/win-acme/releases/download/v2.2.9.1701/win-acme.v2.2.9.1701.x64.pluggable.zip -OutFile C:\win-acme\win-acme.zip

Expand-Archive C:\win-acme\win-acme.zip C:\win-acme -Force

cd C:\win-acme
```

---

### 6. Request Your SSL Certificate

```powershell
.\wacs.exe
```

- Choose `N` → Create new certificate
- Select: `Default Web Site (http, menniboefarm.com)`
- Accept all defaults

> ℹ️ win-acme validates your domain, generates the cert, installs it, binds HTTPS, and creates the auto-renew task — all automatically.

---

### 7–9. Verify & Auto-Renewal

- IIS → Bindings → confirm `https:443` with Let's Encrypt cert
- Server Certificates → `menniboefarm.com` → ~90 days expiry
- Auto-renew scheduled task created — renews every ~60 days, no action needed

---

## Part 3 — Printable Checklist

### ☐ 1. VM Setup
- [ ] Deploy Windows Server 2019/2022
- [ ] Assign static public IP
- [ ] Allow port 80 (HTTP)
- [ ] Allow port 443 (HTTPS)
- [ ] Allow port 3389 (RDP)

### ☐ 2. Install IIS
- [ ] `Install-WindowsFeature -name Web-Server -IncludeManagementTools`
- [ ] Verify: `Get-WindowsFeature Web-Server` → shows `[X]`
- [ ] Create test page in `C:\inetpub\wwwroot`

### ☐ 3. Configure DNS
- [ ] A record: `@` → VM public IP
- [ ] (Optional) CNAME: `www` → `menniboefarm.com`

### ☐ 4. IIS Host Binding
- [ ] IIS Manager → Default Web Site → Bindings → Add
- [ ] Type: `http` | Port: `80` | Host: `menniboefarm.com`

### ☐ 5. Install win-acme
- [ ] Create `C:\win-acme` folder
- [ ] Download win-acme ZIP via `Invoke-WebRequest`
- [ ] Extract with `Expand-Archive`
- [ ] `cd C:\win-acme`

### ☐ 6. Request SSL Certificate
- [ ] Run `.\wacs.exe`
- [ ] Choose `N` (new cert)
- [ ] Select `Default Web Site (http, menniboefarm.com)`
- [ ] Accept all defaults

### ☐ 7. Verify HTTPS Binding
- [ ] IIS → Bindings → `https:443` `menniboefarm.com` with Let's Encrypt

### ☐ 8. Verify Certificate
- [ ] Server Certificates → `menniboefarm.com` → ~90 days expiry

### ☐ 9. Auto-Renewal
- [ ] Scheduled task created — renews every ~60 days — no action needed