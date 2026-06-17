# Anaconda Navigator Setup & Troubleshooting (macOS, Apple Silicon)

## Summary

Today's session was an unplanned but valuable troubleshooting exercise: installing Anaconda Navigator on macOS, fixing a broken/partial install, getting the GUI app launching properly, and cleaning up shell configuration (`(base)` prompt prefix).

This wasn't a planned curriculum topic, but it's a useful real-world example of macOS environment management — the same skills (PATH, shell config, symlinks, Automator) apply directly to setting up local dev environments for Python/AI engineering work.

## What I Did

1. Diagnosed and fixed a failed Anaconda install caused by a leftover `/opt/anaconda3` directory blocking reinstallation.
2. Cleaned up shell config (`~/.zshrc`) and removed stale conda initialization blocks.
3. Disabled `(base)` auto-activation in the terminal prompt.
4. Reinstalled Anaconda cleanly (Apple Silicon / arm64 build).
5. Discovered `anaconda-navigator` wasn't recognized as a command — fixed by adding `/opt/anaconda3/bin` to PATH and running `conda init zsh`.
6. Successfully launched Anaconda Navigator from the CLI.
7. Learned how to close it cleanly (`Ctrl+C` or the app's close button) and run it non-blocking with `&`.
8. Built a proper double-clickable macOS app (via Automator) so Navigator can launch like a normal GUI app instead of only from the terminal.

## Key Outputs / Results

- ✅ Anaconda Navigator installed and working on Apple Silicon Mac
- ✅ `(base)` prompt prefix removed via `conda config --set auto_activate_base false`
- ✅ `anaconda-navigator` command now resolves correctly from any terminal session
- ✅ Created an Automator `.app` wrapper so Navigator can be launched from Applications/Launchpad/Dock like any other Mac app

## Key Takeaway

Most "broken install" issues on macOS come down to two things: **leftover files from a previous install**, and **PATH not pointing to the new binaries**. Knowing how to check, clean, and re-link both is a transferable skill for any future CLI tool installs (this will come up again with AWS CLI, Azure CLI, Terraform, kubectl, etc.).

## Next Steps

- Confirm Navigator opens correctly from the new Applications icon (not just CLI)
- Resume primary AZ-104 / AWS track next session