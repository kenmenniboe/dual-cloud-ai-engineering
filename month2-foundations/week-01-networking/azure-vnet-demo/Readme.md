# 🌐 Azure Virtual Network (VNet) — Hands-On Demo
**Date:** Sunday, May 31, 2026
**Topic:** AZ-104 | Creating a VNet in Azure Portal
**Course:** Udemy AZ-104 (Side-by-side study session)

---

## ✅ What I Did Today

- Created a Virtual Network (`First-Demo-VNet`) in Azure Portal
- Configured an address space of `10.0.0.0/16`
- Created **4 subnets** with distinct public/private naming
- Reviewed the Security tab features (Bastion, Firewall, DDoS, Encryption)
- Reviewed Tags and successfully deployed the VNet

---

## 🔲 Subnets Created

| Subnet Name       | Address Range               | Size |
|-------------------|-----------------------------|------|
| Public-Subnet-01  | 10.0.0.0 – 10.0.0.255       | /24 (256 addresses) |
| Private-Subnet-02 | 10.0.1.0 – 10.0.1.255       | /24 (256 addresses) |
| Public-Subnet-03  | 10.0.2.0 – 10.0.2.255       | /24 (256 addresses) |
| Private-Subnet-04 | 10.0.3.0 – 10.0.3.255       | /24 (256 addresses) |

---

## 💡 Key Takeaway

A VNet is your **private, isolated network in Azure** — like owning a floor in an Azure data center.
Subnets let you segment that network into logical zones (public-facing vs private/internal), giving you control over traffic flow between resources.

---

## 📁 Files in This Folder

| File | Description |
|------|-------------|
| `README.md` | This file — session summary |
| `notes.md` | Detailed concepts, analogies, and mini-tutorial |