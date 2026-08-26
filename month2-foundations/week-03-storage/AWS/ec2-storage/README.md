# EC2 Storage

AWS SAA track — EC2 storage options: EBS, EBS Snapshots, AMIs, EC2 Instance Store, EBS Multi-Attach, EBS Encryption, and EFS.

## Summary

Structured tutoring session covering every EC2 storage option tested on the SAA exam. Each concept was paired with a real-world analogy and an **Azure anchor** (Managed Disks, Azure Files, Temporary Storage, Shared Disks, Disk Encryption via Key Vault) to reinforce the AZ-104 track at the same time. Modules covered, in order:

1. EBS Volume Fundamentals (network drive, AZ-locked)
2. EBS Behavior — Delete on Termination
3. EBS Volume Types (gp2/gp3, io1/io2, st1, sc1)
4. EBS Snapshots (Archive Tier, Recycle Bin, Fast Snapshot Restore)
5. AMI (Amazon Machine Image)
6. EC2 Instance Store (ephemeral, hardware-attached)
7. EBS Multi-Attach (io1/io2 only, same-AZ, 16-instance cap)
8. EBS Encryption (KMS/AES-256, copy-snapshot-to-encrypt workflow)
9. EFS (Elastic File System)
10. EBS vs EFS vs Instance Store — decision framework

Full detail, acronyms, and the copy-paste redo guide live in [`notes.md`](notes.md).

## Key Outputs

- **10/10** modules completed with exam-style scenario quiz questions answered correctly on the first attempt (see Quiz Recap in `notes.md`)
- Full **7-stage hands-on lab guide** produced and ready to execute: EBS create/attach → Delete on Termination verification → snapshot + cross-AZ volume migration → encrypting an existing unencrypted volume → custom AMI build/launch → EFS deployed across two AZs → full resource cleanup
- Architecture diagram: [`images/architecture-diagram.svg`](images/architecture-diagram.svg)
- Every CLI/user-data command from the session collected in [`commands.md`](commands.md)

## Next Steps

- Run the hands-on redo guide in the lab and confirm each stage's expected behavior live
- Fill in the screenshot placeholders in `notes.md` as each stage is completed