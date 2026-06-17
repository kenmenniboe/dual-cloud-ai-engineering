# UTM Virtual Machines on Apple Silicon — Reference Guide

## Overview
This guide covers installing both **Ubuntu Desktop** and **Windows 11** as virtual machines on an Apple Silicon Mac (M1–M5) using **UTM**, a free, open-source virtualization tool built on QEMU with optional Apple Virtualization framework support.

---

## Core Concepts

### What is UTM?
UTM is a virtualization/emulation front-end for QEMU on macOS. On Apple Silicon it can:
- **Virtualize** — run ARM64 guest OSes at near-native speed using Apple's Hypervisor framework
- **Emulate** — run x86/x64 or other architectures, at a significant performance cost

For both Ubuntu and Windows, we use **Virtualize**, not Emulate, since ARM64 builds of both OSes exist.

### QEMU vs Apple Virtualization
- **QEMU** — default backend, flexible, widely compatible
- **Apple Virtualization** — available on macOS 15+, can improve performance/responsiveness for ARM guests. Toggle in VM settings; fall back to QEMU if compatibility issues arise.

---

## Part 1: Installing UTM

1. Download UTM:
   - Free (GitHub): https://github.com/utmapp/UTM/releases/latest
   - Paid (Mac App Store — adds auto-updates, supports dev funding): search "UTM"
2. Drag `UTM.app` into Applications
3. Launch and allow any macOS permission prompts

`[Screenshot placeholder: UTM app icon in Applications folder]`

---

## Part 2: Ubuntu Desktop (ARM64) Installation

### Step 1 — Download the ISO
- Source: https://cdimage.ubuntu.com/releases/
- Get the file ending in `-desktop-arm64.iso` (~5 GB)
- Recommended: latest interim release (25.10) for newest kernel/driver support, or 24.04 LTS for long-term stability

### Step 2 — Create the VM
1. Click **+** in UTM
2. Select **Virtualize**
3. Select **Linux**
4. Browse to the downloaded ISO

`[Screenshot placeholder: UTM "Virtualize" vs "Emulate" selection screen]`

### Step 3 — Configure Resources

| Setting | Minimum | Recommended |
|---|---|---|
| RAM | 4096 MB | 8192 MB (if 16 GB+ host RAM) |
| CPU | default | default (auto-managed) |
| Storage | 30 GB | 30 GB+ |

Optional: check **Use Apple Virtualization** on macOS 15+ for better performance.

### Step 4 — Install Ubuntu
1. Start the VM → boots into live ISO
2. Click **Install Ubuntu**
3. Choose language/keyboard
4. Choose Normal or Minimal install
5. **Erase disk and install Ubuntu** (safe — only affects the virtual disk, not your Mac)
6. Set name/username/password
7. Wait ~10–20 min → **Restart Now**

`[Screenshot placeholder: Ubuntu installer "Installation type" screen]`

### Step 5 — Remove ISO After Install
Eject/clear the ISO from the CD/DVD drive icon in the UTM sidebar so it doesn't reboot back into the installer.

### Step 6 — Update Packages
Open **Software Updater**, or run via terminal (see `commands.md`).

### Troubleshooting

| Issue | Fix |
|---|---|
| Black screen for >2 min on boot | Resize the UTM window slightly — this often "wakes" the graphics driver |
| VM keeps booting back into installer | Power off VM, confirm ISO is ejected from CD/DVD slot, restart |
| Some apps unavailable | ARM64 has gaps — notably no native ARM Linux build of Chrome or Dropbox |

---

## Part 3: Windows 11 (ARM64) Installation

### Step 1 — Get the ARM64 ISO via CrystalFetch
Windows 11 ARM64 isn't as straightforward to download as Ubuntu's ISO — CrystalFetch automates fetching it directly from Microsoft's servers.

1. App Store → search **CrystalFetch** → install (free)
2. Select Windows 11, ARM64 architecture
3. Download ISO (~5.1 GB; can take 1–2 hrs depending on connection)

Alternative direct source: https://www.microsoft.com/software-download/windowsinsiderpreviewARM64

`[Screenshot placeholder: CrystalFetch architecture selection screen]`

### Step 2 — Create the VM
1. Click **+** in UTM
2. Select **Virtualize**
3. Select **Windows**
4. Check **Install Windows 10 or higher**
5. Check **Install drivers and SPICE tools**
6. Browse to the Windows 11 ARM64 ISO

### Step 3 — Configure Resources

| Setting | Minimum | Recommended |
|---|---|---|
| RAM | 4096 MB | 8192 MB |
| CPU Cores | 2 (required) | 4–6 |
| Storage | 64 GB | 64–128 GB |

> Windows requires at least 2 CPU cores to install at all.

`[Screenshot placeholder: UTM Windows VM resource allocation screen]`

### Step 4 — Install Windows
1. Start VM → press any key to boot the installer
2. Language/region/keyboard
3. **I don't have a product key**
4. Select **Windows 11 Pro** → Next
5. Accept license terms
6. **Custom: Install Windows only**
7. Select the unallocated drive → Next
8. Installer reboots several times (~10–20 min) — this is normal

> Mouse capture: if the mouse doesn't behave normally, click the mouse capture icon in the UTM toolbar. Press **Control+Option** together to release capture.

`[Screenshot placeholder: Windows 11 setup "Custom install" partition screen]`

### Step 5 — Bypass No-Internet Setup Block (if needed)
Windows 11 setup normally forces a network connection + Microsoft account. To skip:
1. At the network screen: press **Shift+F10** → opens Command Prompt
2. Run the bypass command (see `commands.md`)
3. VM restarts and offers a "no internet" / local account setup path

### Step 6 — Install SPICE Guest Tools (Critical)
This provides display, network, and clipboard drivers. Skipping it means broken networking and no screen auto-resize.

1. File Explorer → open the virtual CD drive (Guest Tools ISO)
2. Run the SPICE Guest Tools installer
3. Restart the VM

`[Screenshot placeholder: File Explorer showing Guest Tools CD drive]`

### Step 7 — GPU Acceleration & Retina Mode (Optional)
1. Shut down the VM completely
2. UTM → VM Settings → Display
3. Change display card to **virtio-gpu-pci**
4. Enable **Retina Mode**
5. Save → restart VM
6. Inside Windows: Settings → System → Display → set scaling to 200%

### Step 8 — Run Windows Updates
Settings → Windows Update → install all available updates.

### Troubleshooting

| Issue | Fix |
|---|---|
| Setup demands Wi-Fi / Microsoft account | Shift+F10 → run the OOBE bypass command (see `commands.md`) |
| No internet / no clipboard after install | Install SPICE Guest Tools, then restart the VM |
| Blurry display | Switch display card to `virtio-gpu-pci` + enable Retina Mode |
| Sluggish performance | Confirm you installed the **ARM64** build, not x86_64 — x86 on Apple Silicon runs fully emulated and is much slower |

---

## Side-by-Side Comparison

| | Ubuntu Desktop | Windows 11 |
|---|---|---|
| ISO source | Direct from ubuntu.com/cdimage | Via CrystalFetch (or MS Insider Preview) |
| ISO size | ~5 GB | ~5.1 GB |
| Min RAM | 4 GB | 4 GB |
| Min CPU cores | default | 2 (required) |
| Min storage | 30 GB | 64 GB |
| Extra post-install step | `apt update && apt upgrade` | Install SPICE Guest Tools |
| Known gaps | No native ARM build of Chrome/Dropbox | Limited gaming, some peripheral support gaps |

---

## Key Takeaways
- Always choose **Virtualize**, not Emulate, when running ARM64 guests on Apple Silicon — it's the difference between near-native speed and slow emulation.
- UTM is fully free regardless of download source; the App Store version only adds auto-updates.
- Both OS installs follow the same basic shape: get the right ISO → create VM → allocate resources → install → post-install tooling/updates.
- Windows specifically needs SPICE Guest Tools for full functionality — don't skip this step.
- Neither install touches the host macOS filesystem or partitions — both VMs are fully sandboxed.