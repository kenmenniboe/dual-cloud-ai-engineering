# UTM Virtual Machines on Apple Silicon — Ubuntu & Windows 11

## Summary
Today's session covered how to set up virtual machines on an Apple Silicon Mac using **UTM**, a free, open-source virtualization tool. Walked through the full process for two guest OSes: **Ubuntu Desktop (ARM64)** and **Windows 11 (ARM64)** — covering ISO sourcing, VM configuration, OS installation, and post-install setup for performance and usability.

## Key Topics Covered
- UTM installation (GitHub vs Mac App Store — functionally identical, App Store adds auto-updates)
- Ubuntu ARM64 ISO download and VM setup using **Virtualize** mode
- Windows 11 ARM64 ISO download via **CrystalFetch**
- VM resource allocation (RAM, CPU, storage) for both OSes
- Apple Virtualization vs QEMU backend
- SPICE Guest Tools installation for Windows (drivers, networking, clipboard)
- GPU acceleration / Retina mode tuning for both OSes
- Common troubleshooting: black screen on boot, mouse capture, no-internet setup block

## Key Outputs / Results
- Documented a complete Ubuntu Desktop ARM64 install workflow: UTM → ISO → VM config → install → post-install updates
- Documented a complete Windows 11 ARM64 install workflow: UTM → CrystalFetch → VM config → install → SPICE tools → GPU/Retina tuning
- Captured minimum resource requirements for each OS:
  - **Ubuntu:** 4–8 GB RAM, 30 GB disk
  - **Windows 11:** 4–8 GB RAM, 2+ CPU cores (required), 64 GB disk
- Identified the one CLI workaround Windows setup needs (`OOBE\BYPASSNRO`) and the one CLI command used for Ubuntu post-install updates

## Next Steps
- [ ] Actually provision the Ubuntu VM and document real install results/screenshots
- [ ] Actually provision the Windows 11 VM and document real install results/screenshots
- [ ] Test shared folder / clipboard integration between macOS and each guest OS
- [ ] Benchmark performance: QEMU vs Apple Virtualization backend

---
*Full step-by-step walkthrough: see `notes.md`. CLI commands: see `commands.md`.*