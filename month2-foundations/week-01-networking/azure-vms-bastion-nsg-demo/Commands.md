# Commands: Azure VMs, Bastion & NSG Lab

**Date:** Thu Jun 11, 2026
**Tools Used:** Azure Portal, Windows PowerShell (inside VM via Bastion)

---

## Windows PowerShell (Run inside VM via Bastion RDP)

### Enable ICMP Inbound (Windows Firewall)
```powershell
netsh advfirewall firewall add rule name="Allow ICMPv4" protocol=icmpv4:8,any dir=in action=allow
```

### Enable ICMP Outbound (Windows Firewall)
```powershell
netsh advfirewall firewall add rule name="Allow ICMPv4 Outbound" protocol=icmpv4:8,any dir=out action=allow
```

### Ping VM-2 from VM-1
```powershell
ping 10.0.0.5
```

### Ping VM-1 from VM-2
```powershell
ping 10.0.0.4
```

---

## Azure Portal Actions (No CLI Used This Session)

All resources were created via the Azure Portal UI:

| Action | Location in Portal |
|--------|-------------------|
| Create Resource Group | Home → Resource Groups → + Create |
| Create VNet | Home → Virtual Networks → + Create |
| Create VM | Home → Virtual Machines → + Create |
| Add Subnet | VNet → Subnets → + Subnet |
| Deploy Bastion | Home → Bastions → + Create |
| Enable Native Client | Bastion → Configuration |
| Add NSG Rule | NSG → Inbound Security Rules → + Add |

---

> 💡 No Azure CLI commands were used this session.
> CLI-based VNet and VM creation was covered in earlier sessions.