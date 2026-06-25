# 📘 Azure App Service — Deploy, Custom Domain & HTTPS

> Three-part reference: Technician Guide · Beginner Walkthrough · Printable Checklist


---

## Part 1 — Technician Reference

### 1. Create the App Service

- Azure Portal → **Create a Resource** → **App Service** → **Create**
- Fill in:
  - Subscription & Resource Group
  - Name: e.g. `menniboe-demo`
  - Publish: `Code`
  - Runtime stack: your choice
  - Region: closest to you
- App Service Plan: **Basic (B1) or higher**

> ⚠️ Free tier does NOT support custom domains.

- **Review + Create → Create** (~30–60 seconds)

---

### 2. Verify the App Service Works

- App Service → **Overview** → click the URL

```
https://menniboe-demo.azurewebsites.net
```

- Expected: Azure default welcome page

---

### 3. Deploy Website Files (Optional)

- App Service → **Advanced Tools** → **Go** → **Debug Console** → **CMD**
- Navigate to: `site/wwwroot`
- Drag and drop your HTML/CSS/JS files
- Refresh the Azure URL to confirm deployment

---

### 4. Add the Custom Domain

- App Service → **Custom domains** → **Add custom domain**
- Enter: `www.menniboefarm.com`
- Azure displays the required DNS records

---

### 5. Add DNS Records in Namecheap

- Namecheap → Domain List → Manage → **Advanced DNS**

| Type  | Host        | Value                                  |
|-------|-------------|----------------------------------------|
| CNAME | `www`       | `menniboe-demo.azurewebsites.net`      |
| TXT   | `asuid.www` | *(Azure verification code)*            |

> ℹ️ Propagation usually takes 1–5 minutes.

---

### 6. Validate & Add the Domain in Azure

- Return to: **Custom domains → Add**
- Azure shows: `Validation passed`
- Click **Add**

---

### 7. Create the Free HTTPS Certificate

- App Service → **TLS/SSL settings** → **App Service Managed Certificates** → **Create**
- Select: `www.menniboefarm.com`
- Azure generates the certificate (~10–20 seconds)

---

### 8. Bind the Certificate

- **TLS/SSL settings** → **TLS/SSL Bindings** → **Add TLS/SSL Binding**
- Set:
  - Hostname: `www.menniboefarm.com`
  - Certificate: the managed cert you created
  - TLS/SSL Type: `SNI SSL`
- Click **Add** — Azure restarts and applies HTTPS

---

### 9. Test HTTPS

```
https://www.menniboefarm.com
```

- Expected: padlock icon, no warnings, site loads

> ℹ️ If "Not Secure" appears: clear cache, test in incognito, or test on mobile data.

---

### 10. (Optional) Force HTTPS Redirect

- App Service → **Configuration** → **General settings**
- Set: `HTTPS Only: On`

---

## Part 2 — Beginner-Friendly Guide

### What You're Trying to Do

Azure App Service is the "home" for your website. Your domain (`menniboefarm.com`) is the street address people type to reach that home. This guide walks you through:

1. Creating the home (App Service)
2. Verifying it works
3. Uploading your files
4. Connecting your domain
5. Securing it with HTTPS

---

### What You Need

- An Azure account
- A domain name (`menniboefarm.com`)

---

### 1. Create Your App Service

- Portal → **Create a resource** → **App Service** → **Create**
- Fill in name, runtime stack, region
- Choose **Basic (B1) or higher** — Free tier does NOT support custom domains
- **Review + Create → Create**

> ℹ️ The name you choose becomes your temporary URL: `name.azurewebsites.net`

---

### 2. Launch & Verify

- App Service → **Overview** → click the URL
- You should see the Azure default "Welcome" page

> ℹ️ This confirms your App Service is alive and working before you connect anything else.

---

### 3. Upload Your Website Files (Optional)

- **Advanced Tools → Go → Debug Console → CMD → site/wwwroot**
- Drag and drop your HTML files

---

### 4. Connect Your Custom Domain

- **Custom domains → Add custom domain**
- Enter: `www.menniboefarm.com`
- Azure tells you which DNS records to add

> ℹ️ Azure needs to verify you own the domain before connecting it.

---

### 5. Add DNS Records in Namecheap

- **CNAME:** `www` → `your-app.azurewebsites.net`
- **TXT:** `asuid.www` → Azure verification code

> ℹ️ These two records prove to Azure that you own the domain.

---

### 6. Validate & Add

- Back in Azure → **Add** → `Validation passed` → **Add**
- Domain is now connected ✅

---

### 7. Create Free HTTPS Certificate

- **TLS/SSL settings → App Service Managed Certificates → Create**
- Select `www.menniboefarm.com` → Azure generates a free cert

> ℹ️ Azure manages this cert — you don't pay for it.

---

### 8. Bind the Certificate

- **TLS/SSL Bindings → Add → SNI SSL → Add**
- Azure restarts your site and HTTPS is now active ✅

---

### 9. Test & Done!

```
https://www.menniboefarm.com
```

- You should see: padlock, your site, no warnings 🎉
- (Optional) Force HTTPS: **Configuration → General settings → HTTPS Only: On**

---

## Part 3 — Printable Checklist

### ☐ 1. App Service
- [ ] Create App Service (B1 or higher)
- [ ] Verify default URL loads in browser

### ☐ 2. Deploy Files (Optional)
- [ ] Advanced Tools → CMD → `site/wwwroot` → upload files

### ☐ 3. Custom Domain
- [ ] Custom domains → Add custom domain → `www.menniboefarm.com`

### ☐ 4. DNS Records (Namecheap)
- [ ] CNAME: `www` → `app.azurewebsites.net`
- [ ] TXT: `asuid.www` → Azure verification code

### ☐ 5. Validate & Add
- [ ] Azure: `Validation passed` → **Add**

### ☐ 6. Free Certificate
- [ ] TLS/SSL → App Service Managed Certs → Create → `www.menniboefarm.com`

### ☐ 7. Bind Certificate
- [ ] TLS/SSL Bindings → Add → SNI SSL → Add

### ☐ 8. Test
- [ ] `https://www.menniboefarm.com` → padlock + no warnings

### ☐ 9. (Optional) Force HTTPS
- [ ] Configuration → General settings → HTTPS Only: **On**