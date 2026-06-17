# Commands — Anaconda Navigator Setup (macOS / Apple Silicon)

All commands from today's session, grouped by workflow stage. Copy-paste ready.

---

## 1. Cleanup — Remove Broken/Existing Install

```bash
# Try official uninstaller first (only works if conda still runs)
conda install anaconda-clean
anaconda-clean --yes

# Force-remove the install directory (will prompt for Mac password)
sudo rm -rf /opt/anaconda3

# Remove leftover conda config/cache files
rm -rf ~/.conda
rm -rf ~/.condarc
rm -rf ~/.anaconda
```

---

## 2. Shell Config Cleanup

```bash
# Edit .zshrc to remove old conda initialize block
nano ~/.zshrc
# (manually delete lines between "# >>> conda initialize >>>" and "# <<< conda initialize <<<")

# Reload shell config after editing
source ~/.zshrc
```

---

## 3. Disable `(base)` Auto-Activation

```bash
# Stop conda from auto-activating base on every new terminal session
conda config --set auto_activate_base false

# Deactivate base for current session only (one-time, doesn't persist)
conda deactivate
```

---

## 4. Fix PATH / "command not found"

```bash
# Confirm the binary exists before troubleshooting PATH
ls /opt/anaconda3/bin/anaconda-navigator

# Add Anaconda's bin folder to PATH permanently
echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Properly initialize conda for zsh
/opt/anaconda3/bin/conda init zsh
source ~/.zshrc
```

**Alternate install path checks (if `/opt/anaconda3` isn't where it landed):**
```bash
ls ~/anaconda3/bin/anaconda-navigator
ls ~/opt/anaconda3/bin/anaconda-navigator

# Search the whole system for it if still not found
find / -name "anaconda-navigator" 2>/dev/null
```

---

## 5. Launching & Closing Navigator

```bash
# Launch (blocks terminal)
anaconda-navigator

# Launch in background (terminal stays free)
anaconda-navigator &
```

To close: `Ctrl + C` in the terminal running it, or click the app's close button.

---

## 6. Making Navigator a Proper GUI App

```bash
# Option A handled via Automator GUI (Run Shell Script action contains):
/opt/anaconda3/bin/anaconda-navigator

# Option B — check for and move a bundled .app if present
ls /opt/anaconda3/
mv /opt/anaconda3/Anaconda\ Navigator.app /Applications/

# Option C — simple symlink alternative (puts a clickable shortcut in Applications)
ln -s /opt/anaconda3/bin/anaconda-navigator /Applications/Anaconda\ Navigator

# Or a Desktop shortcut instead
ln -sf /opt/anaconda3/bin/anaconda-navigator ~/Desktop/anaconda-navigator
```

---

## 7. Updating Navigator (if it opens but crashes)

```bash
conda update -n base -c defaults conda
conda update anaconda-navigator
```

---

## 8. Useful Follow-Up Diagnostic Commands

```bash
# Verify you're on Apple Silicon (should return "arm64")
uname -m

# View current PATH to confirm Anaconda is included
echo $PATH
```