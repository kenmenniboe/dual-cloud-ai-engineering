# Commands — Nginx + HTTPS with a Self-Signed Certificate

All commands from the session, copy-paste ready, grouped by workflow stage.
Environment: Ubuntu 25.10 (Questing) in UTM.

---

## 0. Folder Scaffolding
```bash
mkdir -p day-sun-jul-13-nginx-https-selfsigned && touch day-sun-jul-13-nginx-https-selfsigned/{README.md,notes.md,commands.md}
```

## 1. Environment Check
```bash
lsb_release -a
```

## 2. Nginx — Install & Baseline
```bash
sudo apt update
sudo apt install nginx -y
systemctl status nginx          # q to exit; look for active (running)
curl http://localhost           # default welcome page over plain HTTP
```

## 3. OpenSSL — Generate Self-Signed Cert + Key
```bash
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/selfsigned.key \
  -out /etc/nginx/selfsigned.crt
# When prompted, set Common Name (CN) = localhost
```

## 4. OpenSSL — Verify the Files & Certificate
```bash
ls -l /etc/nginx/selfsigned.*
sudo openssl x509 -text -noout -in /etc/nginx/selfsigned.crt
# Confirm Subject == Issuer, 2048-bit key, sha256WithRSAEncryption
```

## 5. Nginx — HTTPS Config (final, clean via tee)
```bash
sudo tee /etc/nginx/sites-available/default > /dev/null << 'EOF'
# Default server configuration — HTTP redirects to HTTPS
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name localhost;

    return 301 https://$host$request_uri;
}

# HTTPS server — serves the site with the self-signed cert
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
EOF
```

## 6. Nginx — Validate & Apply
```bash
sudo nginx -t                    # ALWAYS test before reloading
sudo systemctl daemon-reload     # clears "unit file changed on disk" warning
sudo systemctl reload nginx      # graceful apply
```

## 7. Testing
```bash
# HTTPS (self-signed → -k skips verification)
curl -k https://localhost

# Redirect check (headers only)
curl -I http://localhost
# Expect: HTTP/1.1 301 Moved Permanently  +  Location: https://localhost/
```

## 8. Editing the Config Manually (reference)
```bash
sudo nano /etc/nginx/sites-available/default
# Search:            Ctrl+W  →  text  →  Enter
# Jump to file end:  Alt+/
# Line numbers:      Alt+Shift+3   (or: nano -l <file>)
# Save/Exit:         Ctrl+O, Enter  then  Ctrl+X
```

## 9. Trusting the Cert to Remove the Warning (reference — not run this session)
```bash
# Linux system trust store
sudo cp /etc/nginx/selfsigned.crt /usr/local/share/ca-certificates/menniboe-selfsigned.crt
sudo update-ca-certificates
# macOS: import the .crt into Keychain Access → set "Always Trust"
```

## 10. Deploy a Custom index.html (next step — not completed)
```bash
# back up the default page first
sudo cp /var/www/html/index.nginx-debian.html /var/www/html/index.nginx-debian.html.bak
# then place the new page
sudo cp index.html /var/www/html/index.html
# static files serve live — no reload needed, just refresh the browser
```