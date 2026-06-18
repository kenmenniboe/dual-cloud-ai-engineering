# CLI Commands — AWS IAM, SSH Key Pairs & Route 53

---

## SSH Key Management

### Move key pair to ~/.ssh/
```bash
mv ~/Downloads/demo-keypair.pem ~/.ssh/
```

### Move key from a custom location
```bash
mv ~/Desktop/SSHKeyPair/Networking.pem ~/.ssh/
```

### Set correct permissions on key (required by SSH)
```bash
chmod 400 ~/.ssh/demo-keypair.pem
chmod 400 ~/.ssh/Networking.pem
```

---

## Connecting to EC2 via SSH

### Standard SSH connection to Amazon Linux EC2
```bash
ssh -i ~/.ssh/demo-keypair.pem ec2-user@<public-ip>
```

> Replace `<public-ip>` with the Public IPv4 address from EC2 Console

### Common EC2 default usernames by AMI
| AMI | Default Username |
|-----|-----------------|
| Amazon Linux | `ec2-user` |
| Ubuntu | `ubuntu` |
| RHEL | `ec2-user` |
| Debian | `admin` |

---

## Verify Key Permissions
```bash
ls -la ~/.ssh/
```
> Keys should show `-r--------` (400) permissions

---

## Notes
- All `.pem` keys should live in `~/.ssh/`
- Always run `chmod 400` after moving a key — SSH will reject keys with open permissions
- `.pem` = Mac/Linux/OpenSSH | `.ppk` = PuTTY on Windows