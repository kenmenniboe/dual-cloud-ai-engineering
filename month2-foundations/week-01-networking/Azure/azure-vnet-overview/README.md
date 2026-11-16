# Sun-May-31 — AZ-104: Virtual Networks (VNet) Fundamentals

## 🎯 What I Learned Today

Worked through **4 modules** of Azure Virtual Networking with a structured tutor:

- ✅ **Module 1:** Virtual Networks (VNets)
- ✅ **Module 2:** Subnets
- ✅ **Module 3:** Network Security Groups (NSGs)
- ✅ **Module 4:** Route Tables

## 🔑 Key Takeaways

- A **VNet** is a private, isolated network inside Azure — locked to one region
- **Subnets** divide a VNet into smaller controlled sections; Azure reserves **5 IPs per subnet**
- **NSGs** are rule lists that allow/deny traffic — lower priority number wins, both subnet & NIC NSGs must allow traffic
- **Route Tables** override Azure's default routing — custom routes always win over system routes
- `0.0.0.0/0` = all internet traffic (used in both NSG rules and routes)

## 🛠️ Hands-On Done

- Created a VNet (`10.0.0.0/16`) in the Azure Portal
- Added two subnets: `web-subnet` (10.0.1.0/24) and `db-subnet` (10.0.2.0/24)
- Attached an NSG with a custom Allow rule
- Explored Azure's 3 default NSG rules (65000, 65001, 65500)
- Reviewed Route Table options including Next Hop Types

## 📁 Files in This Folder

| File | Purpose |
|---|---|
| `README.md` | This summary |
| `notes.md` | Detailed mini-tutorial of every concept |
| `screenshots/` | Portal screenshots (to be added) |

## ⏭️ Next Session

Resume at **Module 5: VNet Peering** — connecting VNets across regions.

## 📚 Source

Udemy AZ-104 course + structured Claude tutor session