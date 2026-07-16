# Commands Reference — VNet Peering Lab

## SSH Key Setup
```bash
# Move downloaded key pair into ~/.ssh
mv ~/Downloads/adminuser.pem ~/.ssh/

# Lock down permissions so SSH will accept the key
chmod 400 ~/.ssh/adminuser.pem

# View contents of ~/.ssh (including hidden files)
ls -la ~/.ssh

# Open ~/.ssh in Finder (Mac GUI)
open ~/.ssh
```

## SSH Connection
```bash
# Connect to vm-hub using the key pair
ssh -i ~/.ssh/adminuser.pem <username>@<vm-hub-public-ip>
```

## Connectivity Test (run from inside vm-hub session)
```bash
# Ping vm-spoke's PRIVATE IP to validate peering (4 pings, then stop)
ping -c 4 <vm-spoke-private-ip>

# Example used in this session:
ping -c 4 10.1.0.4
```

---

## Folder Scaffolding (for this lab's documentation)
```bash
mkdir -p thu-jul-16-vnet-peering && touch thu-jul-16-vnet-peering/{README.md,notes.md,commands.md}
```