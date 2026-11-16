# Commands Reference — UTM VM Setup (Ubuntu & Windows 11)

All commands from today's session, grouped by tool/workflow stage. Copy-paste ready.

---

## Ubuntu — Post-Install System Update

Run after first boot into the new Ubuntu VM (alternative to using the GUI Software Updater):

```bash
sudo apt update && sudo apt upgrade -y
```

---

## Windows 11 — Bypass No-Internet/Account Setup Requirement

During Windows Setup, at the network connection screen:

1. Open a command prompt inside the installer:
   - Keyboard shortcut: `Shift + F10`
2. Run:

```cmd
OOBE\BYPASSNRO
```

This restarts the VM and re-presents setup with a local/offline account path available.

---

## Notes
- If you proceed to actually provision either VM, capture any additional commands here (e.g. `spice-vdagent` install commands if you set up shared folders on Ubuntu, or PowerShell commands during Windows config).