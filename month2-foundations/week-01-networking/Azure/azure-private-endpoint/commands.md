# Commands — Azure Private Endpoint Lab

## Network Diagnostics (local machine, troubleshooting public connectivity)

```bash
# Check public IP (may return IPv6 depending on ISP)
curl ifconfig.me

# Force IPv4 specifically — needed to match Azure SQL's IPv4-based firewall whitelist
curl -4 ifconfig.me

# Test raw TCP reachability to Azure SQL's port before troubleshooting the SQL layer
nc -zv <sql-server-name>.database.windows.net 1433
```

## DNS Verification (from the jumpbox, inside the VNet)

```powershell
# Confirms the CNAME redirect to the privatelink zone and the resulting private IP
nslookup <sql-server-name>.database.windows.net
```

## SQL Connectivity Test — VS Code MSSQL Extension (public test, local machine)

```sql
-- Run inside the MSSQL extension's query editor after connecting
SELECT name FROM sys.tables;
```

## SQL Connectivity Test — Jumpbox (private path, PowerShell, no extra installs)

```powershell
$connString = "Server=tcp:<sql-server-name>.database.windows.net,1433;Database=productdb;User ID=sqladminuser;Password=<your-password>;Encrypt=True;Connection Timeout=60;"
$conn = New-Object System.Data.SqlClient.SqlConnection($connString)
$conn.Open()
Write-Host "Connected! Server:" $conn.DataSource
$cmd = $conn.CreateCommand()
$cmd.CommandText = "SELECT name FROM sys.tables"
$reader = $cmd.ExecuteReader()
while ($reader.Read()) { Write-Host $reader[0] }
$conn.Close()
```

## Attempted / Not Used

```powershell
# Attempted on the jumpbox — failed (winget source registration issue,
# and jumpbox has no outbound internet access by design anyway)
winget install sqlcmd
```