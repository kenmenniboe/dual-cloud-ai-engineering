# Commands — Azure VPN Gateway P2S Lab

All commands run in **PowerShell (Admin)** on a Windows 11 ARM64 VM unless noted otherwise. Grouped by workflow stage, in the order used.

## Certificate Generation

```powershell
# Root certificate
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=P2SRootCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
```

```powershell
# Client certificate, signed by the root
New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject "CN=P2SChildCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
```

> [!NOTE]
> These commands only work on Windows — `New-SelfSignedCertificate` depends on the Windows PKI Certificate Store APIs, unavailable in PowerShell Core on macOS.

## Certificate Lookup

```powershell
# Find the client cert's thumbprint
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {$_.Subject -eq "CN=P2SChildCert"}
```

## Certificate Export

```powershell
# Initial export (leaf cert only)
$pwd = ConvertTo-SecureString -String "P2SClient!23" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\<thumbprint>" `
  -FilePath "C:\Users\Kenneth M\Desktop\P2SChildCert.pfx" -Password $pwd
```

```powershell
# Re-export with full chain (fix for "client certificate must include an issuer" error)
# Run AFTER importing the root cert into Trusted Root Certification Authorities
$pwd = ConvertTo-SecureString -String "P2SClient!23" -Force -AsPlainText
Export-PfxCertificate -Cert "Cert:\CurrentUser\My\<thumbprint>" `
  -FilePath "C:\Users\Kenneth M\Desktop\P2SChildCert2.pfx" -Password $pwd -ChainOption BuildChain
```

## Client Package Diagnostics

```powershell
# Navigate to extracted VPN client package
cd $env:USERPROFILE\Desktop
dir
cd .\vpnclientconfiguration
```

```powershell
# List full contents/extensions of the extracted package (avoids misreading file icons)
Get-ChildItem -Recurse | Select-Object FullName
```

```powershell
# Pull the gateway's VPN server FQDN for manual client configuration
Get-Content "C:\Users\Kenneth M\Desktop\vpnclientconfiguration\Generic\VpnSettings.xml" | Select-String "VpnServer"
```

## Windows Registry Fix — IKEv2 "remote server not responding"

```powershell
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\IKEv2" -Force
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\RasMan\IKEv2" -Name "DisableCertReqPayload" -Value 1 -PropertyType DWORD -Force
```
Reboot the VM after running this for it to take effect.

## Network Verification

```cmd
:: Command Prompt — check for VPN adapter + assigned pool IP after connecting
ipconfig /all
```

```cmd
:: Reachability test once a workload VM exists (private IP)
ping 10.0.0.4
```