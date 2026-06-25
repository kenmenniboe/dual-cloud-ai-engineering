# 📘 Nginx Web Server — CentOS Stream & Ubuntu Server

> Three-part reference: Technician Guide · Beginner Walkthrough · Printable Checklist
>
> Covers:
> - **CentOS Stream** — Nginx install and full configuration
> - **Ubuntu Server on a Mac VM** (UTM or VirtualBox) — from ISO to Nginx running
> - **Ubuntu Server on a Cloud VM** (Azure & AWS) — from VM creation to Nginx running

---

## 📁 GitHub Folder Scaffolding

```bash
mkdir -p nginx-centos-ubuntu && touch nginx-centos-ubuntu/{README.md,notes.md,commands.md}
```

---

# SECTION A — CentOS Stream

---

## Part 1 — Technician Reference (CentOS Stream)

> ⚠️ Run all commands as root or prefix with `sudo`. Replace `example.com` with your domain.

### 1. Install Nginx

```bash
dnf -y update
dnf -y install nginx
systemctl start nginx
systemctl enable nginx
```

---

### 2. Open Firewall Ports

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

---

### 3. Create the Web Root Directory

```bash
mkdir -p /var/www/example.com/html
chown $USER:$USER /var/www/example.com/html
chmod -R 755 /var/www/example.com
```

---

### 4. Create a Test Page

```bash
nano /var/www/example.com/html/index.html
```

Add this content:

```html
<!DOCTYPE html>
<html>
  <head><title>My Site</title></head>
  <body><p>Hello from CentOS + Nginx!</p></body>
</html>
```

Save: `Ctrl+X → Y → Enter`

---

### 5. Create the Nginx Server Block

```bash
nano /etc/nginx/conf.d/example.com.conf
```

Paste:

```nginx
server {
    listen 80;
    listen [::]:80;

    root /var/www/example.com/html;
    index index.php index.html index.htm;

    server_name example.com www.example.com;
}
```

Save: `Ctrl+X → Y → Enter`

Test in browser: `http://example.com`

> ℹ️ If issues occur, check SELinux — set to permissive mode or explicitly allow Nginx.

---

### 6. Install PHP — CentOS Stream 9

```bash
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.2.rpm
dnf module reset php
dnf module install php:remi-8.3
dnf -y update
dnf -y install php
```

### 6a. Install PHP — CentOS Stream 8

```bash
dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module reset php
dnf module install php:remi-8.3
dnf -y update
dnf -y install php
```

---

### 7. Configure PHP (php.ini)

```bash
nano /etc/php.ini
```

Find and change:

```
# Before:
cgi.fix_pathinfo=1

# After:
cgi.fix_pathinfo=0
```

Save: `Ctrl+X → Y → Enter`

---

### 8. Configure PHP-FPM

```bash
nano /etc/php-fpm.d/www.conf
```

Set:

```
user = nginx
group = nginx
listen = /run/php-fpm/www.sock
```

Enable PHP-FPM:

```bash
systemctl enable php-fpm
```

---

### 9. Update Server Block for PHP

```bash
nano /etc/nginx/conf.d/example.com.conf
```

Update to:

```nginx
server {
    listen 80;
    listen [::]:80;

    root /var/www/example.com/html;
    index index.php index.html index.htm;

    server_name example.com www.example.com;

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

---

### 10. Restart Nginx & Test PHP

```bash
systemctl restart nginx
nano /var/www/example.com/html/info.php
```

Add:

```php
<?php
phpinfo();
?>
```

Test: `http://example.com/info.php` → PHP info page should appear ✅

---

## Part 2 — Beginner Guide (CentOS Stream)

### What Is Nginx?

Nginx (pronounced "engine-x") is a high-performance web server. Think of it as a librarian — when someone requests a web page, Nginx hands it over instantly. It's known for being lightweight, fast, and able to handle many visitors at once.

---

### 1. Install Nginx

Update your system first, then install and start Nginx.

```bash
dnf -y update
dnf -y install nginx
systemctl start nginx
systemctl enable nginx
```

> ℹ️ `enable` makes Nginx start automatically every time your server reboots — no manual action needed.

---

### 2. Open Firewall Ports

CentOS Stream uses `firewalld` as its firewall. By default it blocks web traffic — you have to explicitly allow it.

```bash
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
```

> ℹ️ `--permanent` makes the rule survive reboots. `--reload` applies it right now without restarting the firewall service.

---

### 3. Set Up Your Web Root

This is the folder where your website files live.

```bash
mkdir -p /var/www/example.com/html
chown $USER:$USER /var/www/example.com/html
chmod -R 755 /var/www/example.com
```

> ℹ️ `chown` gives you ownership. `chmod 755` lets the web server read and serve your files.

---

### 4. Create a Test Page

Create a simple HTML file to confirm Nginx is working before moving on.

```bash
nano /var/www/example.com/html/index.html
```

Add your HTML, save, then visit `http://example.com` in a browser.

---

### 5. Create a Server Block

A server block tells Nginx: *"When someone visits example.com, serve files from this specific folder."* Without it, Nginx doesn't know which site to load.

```bash
nano /etc/nginx/conf.d/example.com.conf
```

Paste the server config, save, and test in your browser.

---

### 6. Install PHP (if needed)

Nginx doesn't include PHP — you install it separately via the REMI repository for the latest stable version.

> ℹ️ REMI is a trusted third-party repo that provides newer PHP versions than what CentOS Stream includes by default.

---

### 7. Harden PHP

The `cgi.fix_pathinfo` setting is a known security risk. Turning it off prevents attackers from tricking PHP into running the wrong file.

```bash
nano /etc/php.ini
# Change: cgi.fix_pathinfo=1  →  cgi.fix_pathinfo=0
```

---

### 8. Configure PHP-FPM

PHP-FPM manages PHP processes. Nginx passes `.php` requests to PHP-FPM through a socket file — they work together as a team.

```bash
nano /etc/php-fpm.d/www.conf
# Set: user = nginx | group = nginx | listen = /run/php-fpm/www.sock
systemctl enable php-fpm
```

---

### 9–10. Update Config & Verify

- Add the `location ~ \.php$` block to your server block config
- Restart Nginx: `systemctl restart nginx`
- Create `info.php`, visit `http://example.com/info.php` → PHP info page confirms success ✅

---

## Part 3 — Checklist (CentOS Stream)

### ☐ Install Nginx
- [ ] `dnf -y update`
- [ ] `dnf -y install nginx`
- [ ] `systemctl start nginx && systemctl enable nginx`

### ☐ Firewall
- [ ] `firewall-cmd --permanent --add-service=http`
- [ ] `firewall-cmd --permanent --add-service=https`
- [ ] `firewall-cmd --reload`

### ☐ Web Root
- [ ] `mkdir -p /var/www/example.com/html`
- [ ] `chown $USER:$USER /var/www/example.com/html`
- [ ] `chmod -R 755 /var/www/example.com`

### ☐ Test Page
- [ ] `nano /var/www/example.com/html/index.html` → add HTML → save
- [ ] Visit `http://example.com` → page loads ✅

### ☐ Server Block
- [ ] `nano /etc/nginx/conf.d/example.com.conf`
- [ ] Paste basic `server { }` config → save → test in browser

### ☐ PHP (CentOS Stream 9)
- [ ] Install EPEL + REMI repos (latest-9 / remi-9.2)
- [ ] `dnf module reset php && dnf module install php:remi-8.3`
- [ ] `dnf -y update && dnf -y install php`

### ☐ PHP Configuration
- [ ] `php.ini` → `cgi.fix_pathinfo=0`
- [ ] `www.conf` → `user=nginx`, `group=nginx`, `listen=/run/php-fpm/www.sock`
- [ ] `systemctl enable php-fpm`

### ☐ Server Block for PHP
- [ ] Add `location ~ \.php$ { }` block to conf file
- [ ] `systemctl restart nginx`

### ☐ Verify PHP
- [ ] Create `info.php` → `<?php phpinfo(); ?>`
- [ ] Visit `http://example.com/info.php` → PHP info page ✅

---

---

# SECTION B — Ubuntu Server on a Mac VM

> Covers both **UTM** (recommended for Apple Silicon M1/M2/M3/M4) and **VirtualBox** (works on Intel Macs)

---

## Part 1 — Technician Reference (Ubuntu on Mac VM)

### 1. Download Ubuntu Server ISO

- Go to: `https://ubuntu.com/download/server`
- **Apple Silicon Mac (M1/M2/M3/M4):** Download the **ARM64** version
  - Direct ARM link: `https://cdimage.ubuntu.com/releases/24.04.3/release/ubuntu-24.04.3-live-server-arm64.iso`
- **Intel Mac:** Download the standard **AMD64** version

---

### 2a. Install & Set Up VM — UTM (Apple Silicon)

1. Download UTM: `https://mac.getutm.app` → drag to Applications
2. Open UTM → **Create a New Virtual Machine**
3. Choose: **Virtualize** (not Emulate)
4. Select: **Linux**
5. Browse and select your downloaded Ubuntu Server ARM64 ISO
6. Configure hardware:
   - Memory: `4096 MB` (4 GB recommended)
   - CPU Cores: `2` or more
   - Storage: `20 GB` minimum
7. Name the VM (e.g. `Ubuntu 24.04 Server`) → **Save**
8. Click **▶ Play** to start

---

### 2b. Install & Set Up VM — VirtualBox (Intel Mac)

1. Download VirtualBox: `https://virtualbox.org/wiki/Downloads` → Mac hosts
2. Install VirtualBox — follow the prompts, accept all defaults
3. Open VirtualBox Manager → click **New**
4. Name: `Ubuntu 24.04 Server`
5. ISO Image: select your downloaded Ubuntu AMD64 ISO
6. ✅ Tick **Skip Unattended Installation**
7. Configure hardware:
   - Memory: `2048 MB` minimum (`4096 MB` recommended)
   - CPU: `2` cores
   - Storage: `20 GB`
8. Click **Finish** → then **Start**

---

### 3. Install Ubuntu Server (Installer Walkthrough)

The Ubuntu installer will guide you through these screens:

| Screen | What to do |
|---|---|
| Language | Select **English** (or your language) |
| Keyboard | Select your layout → **Done** |
| Network | Leave default (DHCP) → **Done** |
| Proxy | Leave blank → **Done** |
| Mirror | Leave default → **Done** |
| Storage | Select **Use entire disk** → **Done** → **Continue** |
| Profile | Set your name, server name, username, and password |
| SSH | ✅ Check **Install OpenSSH server** → **Done** |
| Snaps | Skip (leave unchecked) → **Done** |
| Install | Wait for install to complete |
| Reboot | Select **Reboot Now** → press Enter when prompted to remove media |

---

### 4. First Login & Initial Setup

Log in with your username and password, then run:

```bash
sudo apt update && sudo apt upgrade -y
```

---

### 5. Install Nginx

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

Verify:

```bash
sudo systemctl status nginx
```

Expected: `Active: active (running)`

---

### 6. Configure UFW Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

Verify:

```bash
sudo ufw status
```

---

### 7. Create the Web Root Directory

```bash
sudo mkdir -p /var/www/example.com/html
sudo chown -R $USER:$USER /var/www/example.com/html
sudo chmod -R 755 /var/www/example.com
```

---

### 8. Create a Test Page

```bash
nano /var/www/example.com/html/index.html
```

Add:

```html
<!DOCTYPE html>
<html>
  <head><title>My Site</title></head>
  <body><p>Hello from Ubuntu + Nginx!</p></body>
</html>
```

Save: `Ctrl+X → Y → Enter`

---

### 9. Create the Nginx Server Block

```bash
sudo nano /etc/nginx/sites-available/example.com
```

Paste:

```nginx
server {
    listen 80;
    listen [::]:80;

    root /var/www/example.com/html;
    index index.html index.htm index.nginx-debian.html;

    server_name example.com www.example.com;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Save, then enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

> ℹ️ Ubuntu uses `sites-available` + `sites-enabled` with symbolic links — different from CentOS which uses `conf.d/`.

---

### 10. Get Your VM's IP Address

```bash
ip addr show
```

Look for the `inet` address on your network interface (e.g. `192.168.x.x`)

Test in your Mac browser: `http://192.168.x.x` → Nginx page should appear ✅

---

## Part 2 — Beginner Guide (Ubuntu on Mac VM)

### What You're Building

You're creating a virtual Linux server that runs inside your Mac. This is exactly how cloud engineers practice — a real Linux environment, no cloud account needed. UTM is best for M1/M2/M3/M4 Macs. VirtualBox works on Intel Macs.

---

### 1. Download the Right ISO

An ISO is a disk image — like a virtual DVD containing the Ubuntu installer.

- **Apple Silicon Mac** → download the **ARM64** version (matches your chip)
- **Intel Mac** → download the standard **AMD64** version

> ℹ️ Using the wrong architecture will cause the VM to fail or run very slowly.

---

### 2. Create Your VM (UTM — Apple Silicon)

UTM is a free, fast virtualization app built for Apple Silicon.

- Download from `https://mac.getutm.app`
- Create VM → **Virtualize** → **Linux** → select your ISO
- Set RAM to 4 GB, storage to 20 GB minimum
- Click Play to start

---

### 2. Create Your VM (VirtualBox — Intel Mac)

VirtualBox is a free, cross-platform virtualization app.

- Download from `https://virtualbox.org`
- New VM → name it → select ISO → **tick Skip Unattended Installation**
- Set RAM to 2–4 GB, storage to 20 GB

> ℹ️ Ticking "Skip Unattended Installation" gives you full control over the setup process — important for learning.

---

### 3. Install Ubuntu Server

The Ubuntu installer is text-based but straightforward — just follow the prompts screen by screen. The key things to set:
- Your username and password
- ✅ **Install OpenSSH server** (lets you SSH in from your Mac terminal)
- Use the entire disk for storage

---

### 4. Update & Install Nginx

Once you're logged in, always update first, then install Nginx.

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

> ℹ️ `apt` is Ubuntu's package manager — like `dnf` on CentOS but for Debian-based systems.

---

### 5. Configure the Firewall (UFW)

Ubuntu uses UFW (Uncomplicated Firewall). Allow SSH so you don't lock yourself out, then allow web traffic.

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

> ⚠️ Always allow OpenSSH before enabling UFW — otherwise you can lock yourself out of the VM.

---

### 6. Set Up Your Site

- Create a web root folder
- Add your HTML file
- Create a server block in `sites-available`
- Enable it with a symbolic link to `sites-enabled`
- Test config: `sudo nginx -t`
- Reload: `sudo systemctl reload nginx`

---

### 7. Find Your IP & Test

```bash
ip addr show
```

Open your Mac browser and go to `http://<your-vm-ip>` — you should see your page ✅

---

## Part 3 — Checklist (Ubuntu on Mac VM)

### ☐ Download ISO
- [ ] Apple Silicon → Ubuntu Server ARM64 ISO
- [ ] Intel Mac → Ubuntu Server AMD64 ISO

### ☐ Create VM
- [ ] UTM (Apple Silicon): Virtualize → Linux → select ISO → 4 GB RAM → 20 GB storage
- [ ] VirtualBox (Intel): New → select ISO → skip unattended → 2–4 GB RAM → 20 GB storage

### ☐ Install Ubuntu Server
- [ ] Language, keyboard, network → defaults
- [ ] Storage → Use entire disk
- [ ] Set username & password
- [ ] ✅ Install OpenSSH server
- [ ] Reboot when complete

### ☐ Initial Setup
- [ ] `sudo apt update && sudo apt upgrade -y`

### ☐ Install Nginx
- [ ] `sudo apt install -y nginx`
- [ ] `sudo systemctl enable nginx && sudo systemctl start nginx`
- [ ] Verify: `sudo systemctl status nginx` → `active (running)`

### ☐ Firewall (UFW)
- [ ] `sudo ufw allow OpenSSH`
- [ ] `sudo ufw allow 'Nginx Full'`
- [ ] `sudo ufw enable`

### ☐ Web Root
- [ ] `sudo mkdir -p /var/www/example.com/html`
- [ ] `sudo chown -R $USER:$USER /var/www/example.com/html`
- [ ] `sudo chmod -R 755 /var/www/example.com`

### ☐ Test Page
- [ ] `nano /var/www/example.com/html/index.html` → add HTML → save

### ☐ Server Block
- [ ] `sudo nano /etc/nginx/sites-available/example.com` → paste config
- [ ] `sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/`
- [ ] `sudo nginx -t` → no errors
- [ ] `sudo systemctl reload nginx`

### ☐ Test
- [ ] `ip addr show` → get VM IP
- [ ] Visit `http://<vm-ip>` in Mac browser → page loads ✅

---

---

# SECTION C — Ubuntu Server on a Cloud VM (Azure & AWS)

---

## Part 1 — Technician Reference (Cloud VM)

### AZURE — Create an Ubuntu Server VM

1. Azure Portal → **Create a resource** → **Virtual Machine** → **Create**
2. Fill in:
   - Resource Group: create new or use existing
   - VM Name: e.g. `nginx-ubuntu-vm`
   - Region: closest to you
   - Image: **Ubuntu Server 24.04 LTS**
   - Size: `B1s` (free tier eligible) or larger
   - Authentication: **SSH public key** (recommended) or password
3. **Inbound port rules** → Allow: `SSH (22)`, `HTTP (80)`, `HTTPS (443)`
4. **Review + Create** → **Create**
5. Download the `.pem` key file when prompted (SSH key method)

**Connect via SSH (Azure):**

```bash
chmod 400 your-key.pem
ssh -i your-key.pem azureuser@<your-vm-public-ip>
```

---

### AWS — Create an Ubuntu Server VM (EC2)

1. AWS Console → **EC2** → **Launch Instance**
2. Fill in:
   - Name: e.g. `nginx-ubuntu-vm`
   - AMI: **Ubuntu Server 24.04 LTS (HVM), SSD Volume Type**
   - Instance type: `t2.micro` (free tier eligible)
   - Key pair: create new → download `.pem` file
3. **Network settings** → Edit → Add inbound rules:
   - Allow `SSH` from My IP
   - Allow `HTTP` from Anywhere
   - Allow `HTTPS` from Anywhere
4. **Launch instance**

**Connect via SSH (AWS):**

```bash
chmod 400 your-key.pem
ssh -i your-key.pem ubuntu@<your-ec2-public-ip>
```

---

### Install Nginx (Same for Both Azure & AWS)

Once connected via SSH, run:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

Verify:

```bash
sudo systemctl status nginx
```

---

### Configure UFW Firewall

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

> ℹ️ Azure and AWS both have their own network-level firewalls (NSG / Security Group). UFW is an additional OS-level firewall — both layers need to allow the traffic.

---

### Create Web Root & Test Page

```bash
sudo mkdir -p /var/www/example.com/html
sudo chown -R $USER:$USER /var/www/example.com/html
sudo chmod -R 755 /var/www/example.com
nano /var/www/example.com/html/index.html
```

Add your HTML content, save with `Ctrl+X → Y → Enter`

---

### Create Nginx Server Block

```bash
sudo nano /etc/nginx/sites-available/example.com
```

Paste:

```nginx
server {
    listen 80;
    listen [::]:80;

    root /var/www/example.com/html;
    index index.html index.htm;

    server_name example.com www.example.com;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Enable and reload:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

### Test Your Site

- Visit `http://<your-public-ip>` in a browser → your page should appear ✅
- If using a domain: point your A record to the public IP, then visit `http://example.com`

---

## Part 2 — Beginner Guide (Cloud VM)

### Azure vs AWS — What's the Difference?

Both Azure and AWS let you spin up a Linux server in the cloud in minutes. The steps are slightly different but the end result is the same: a real Ubuntu Server accessible over the internet.

| | Azure | AWS |
|---|---|---|
| VM name | Virtual Machine | EC2 Instance |
| Ubuntu image | Ubuntu Server 24.04 LTS | Ubuntu Server 24.04 LTS AMI |
| Default user | `azureuser` | `ubuntu` |
| Firewall | Network Security Group (NSG) | Security Group |
| Free tier | B1s (12 months) | t2.micro (12 months) |

---

### 1. Create Your Cloud VM

**Azure:** Portal → Virtual Machine → Create → pick Ubuntu 24.04 → allow ports 22, 80, 443 → Create

**AWS:** EC2 → Launch Instance → pick Ubuntu 24.04 AMI → t2.micro → add inbound rules for SSH, HTTP, HTTPS → Launch

> ℹ️ Download and save your `.pem` key file when prompted — you can't get it again. This is how you SSH into your server.

---

### 2. Connect via SSH

On your Mac terminal:

```bash
chmod 400 your-key.pem
ssh -i your-key.pem azureuser@<ip>   # Azure
ssh -i your-key.pem ubuntu@<ip>      # AWS
```

> ℹ️ `chmod 400` restricts the key file to read-only by you — SSH will refuse to connect if the permissions are too open.

---

### 3. Update & Install Nginx

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

### 4. Two Firewalls to Know About

Cloud VMs have **two** firewall layers:

1. **Cloud firewall** (Azure NSG / AWS Security Group) — configured in the portal when creating the VM
2. **OS firewall** (UFW) — configured on the server itself

Both need to allow HTTP (80) and HTTPS (443) for your site to be reachable.

```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```

---

### 5. Set Up Your Site

Same steps as the Mac VM section:
- Create web root → add HTML → create server block in `sites-available`
- Enable with symlink → test config → reload Nginx

---

### 6. Test

Visit `http://<your-public-ip>` in a browser. If you have a domain, point its A record to the IP and visit `http://example.com` ✅

---

## Part 3 — Checklist (Cloud VM — Azure & AWS)

### ☐ Create Cloud VM

**Azure:**
- [ ] Portal → Virtual Machine → Create
- [ ] Image: Ubuntu Server 24.04 LTS
- [ ] Size: B1s or larger
- [ ] Allow inbound: SSH (22), HTTP (80), HTTPS (443)
- [ ] Download `.pem` key file
- [ ] Create

**AWS:**
- [ ] EC2 → Launch Instance
- [ ] AMI: Ubuntu Server 24.04 LTS
- [ ] Type: t2.micro
- [ ] Create + download key pair `.pem`
- [ ] Security Group: allow SSH, HTTP, HTTPS
- [ ] Launch

### ☐ Connect via SSH
- [ ] `chmod 400 your-key.pem`
- [ ] Azure: `ssh -i your-key.pem azureuser@<ip>`
- [ ] AWS: `ssh -i your-key.pem ubuntu@<ip>`

### ☐ Update & Install Nginx
- [ ] `sudo apt update && sudo apt upgrade -y`
- [ ] `sudo apt install -y nginx`
- [ ] `sudo systemctl enable nginx && sudo systemctl start nginx`
- [ ] `sudo systemctl status nginx` → `active (running)` ✅

### ☐ Firewall (UFW)
- [ ] `sudo ufw allow OpenSSH`
- [ ] `sudo ufw allow 'Nginx Full'`
- [ ] `sudo ufw enable`

### ☐ Web Root
- [ ] `sudo mkdir -p /var/www/example.com/html`
- [ ] `sudo chown -R $USER:$USER /var/www/example.com/html`
- [ ] `sudo chmod -R 755 /var/www/example.com`

### ☐ Test Page
- [ ] `nano /var/www/example.com/html/index.html` → add HTML → save

### ☐ Server Block
- [ ] `sudo nano /etc/nginx/sites-available/example.com` → paste config
- [ ] `sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/`
- [ ] `sudo nginx -t` → no errors
- [ ] `sudo systemctl reload nginx`

### ☐ Test
- [ ] Visit `http://<public-ip>` → page loads ✅
- [ ] (Optional) Point domain A record to IP → test `http://example.com`

---

---

## 🔑 Key Differences — CentOS vs Ubuntu Quick Reference

| | CentOS Stream | Ubuntu Server |
|---|---|---|
| Package manager | `dnf` | `apt` |
| Firewall tool | `firewalld` / `firewall-cmd` | `ufw` |
| Nginx config location | `/etc/nginx/conf.d/` | `/etc/nginx/sites-available/` |
| Enable site | Drop `.conf` in `conf.d/` | Symlink to `sites-enabled/` |
| PHP repo | EPEL + REMI | Default `apt` repos |
| PHP-FPM user | `nginx` | `www-data` |
| Default SSH user (cloud) | `ec2-user` / varies | `azureuser` (Azure) / `ubuntu` (AWS) |