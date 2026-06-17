# Notes — Anaconda Navigator Install & Troubleshooting (macOS / Apple Silicon)

A reference guide for diagnosing and fixing common Anaconda Navigator installation and launch issues on macOS.

---

## 1. Background Concepts

**Anaconda** is a Python/R distribution that bundles `conda` (package & environment manager) with a GUI called **Navigator**.

**Anaconda Navigator** is a desktop GUI front-end for conda — lets you manage environments, launch Jupyter, Spyder, etc. without using the terminal.

**Key locations to know:**
| Item | Typical Path |
|---|---|
| Anaconda install root | `/opt/anaconda3` (Intel default) or `~/anaconda3` (user-level) |
| conda binaries | `/opt/anaconda3/bin` |
| Shell config file (zsh) | `~/.zshrc` |
| Conda's own config | `~/.condarc` |

> 📸 *Screenshot placeholder: Anaconda installer "Destination Select" step*

---

## 2. Problem #1 — "Path already exists" during install

**Symptom:**
```
'/opt/anaconda3' already exists. Please, relaunch the installer and choose another location in the Destination Select step.
```

**Root cause:** A previous (possibly broken) Anaconda install left files behind at `/opt/anaconda3`, and the installer refuses to overwrite an existing directory.

**Fix — full cleanup before reinstalling:**

1. Try the official uninstaller first (only works if conda still runs):
   ```bash
   conda install anaconda-clean
   anaconda-clean --yes
   ```
2. Force-delete the install directory:
   ```bash
   sudo rm -rf /opt/anaconda3
   ```
3. Remove leftover conda config/cache files:
   ```bash
   rm -rf ~/.conda
   rm -rf ~/.condarc
   rm -rf ~/.anaconda
   ```
4. Clean the conda init block out of `~/.zshrc`:
   ```bash
   nano ~/.zshrc
   ```
   Delete everything between (and including):
   ```
   # >>> conda initialize >>>
   ...
   # <<< conda initialize <<<
   ```
   Save: `Ctrl+O` → Enter → `Ctrl+X`
5. Reload the shell:
   ```bash
   source ~/.zshrc
   ```
6. Relaunch the `.pkg` installer — destination should now be clear.

> ⚠️ **Apple Silicon gotcha:** Make sure you download the **arm64** build from anaconda.com, not the Intel (x86_64) build. Installing the wrong architecture is a common cause of Navigator failing to launch later.

> 📸 *Screenshot placeholder: Terminal showing successful `rm -rf` and re-run installer*

---

## 3. Problem #2 — `(base)` always showing in terminal prompt

**Symptom:** Every new terminal session shows:
```
(base) kennethmenniboe@Kenneths-MacBook-Pro Desktop %
```

**Root cause:** Conda auto-activates the `base` environment on every new shell by default.

**Fix — disable auto-activation (recommended, keeps conda usable):**
```bash
conda config --set auto_activate_base false
```
Restart the terminal — `(base)` will no longer appear automatically. You can still manually activate it anytime with `conda activate base`.

**Alternative — deactivate just for current session:**
```bash
conda deactivate
```

---

## 4. Problem #3 — `anaconda-navigator: command not found`

**Symptom:**
```
zsh: command not found: anaconda-navigator
```

**Root cause:** Anaconda is installed, but its `bin` folder isn't on your shell's `PATH`, so zsh doesn't know where to find the executable.

**Diagnosis — confirm the binary actually exists:**
```bash
ls /opt/anaconda3/bin/anaconda-navigator
```
- File path returned → it exists, just not on PATH (continue below).
- "No such file or directory" → install didn't complete correctly; reinstall.

**Fix — add Anaconda to PATH permanently:**
```bash
echo 'export PATH="/opt/anaconda3/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Also initialize conda properly for zsh:**
```bash
/opt/anaconda3/bin/conda init zsh
source ~/.zshrc
```

**Then launch:**
```bash
anaconda-navigator
```

> 💡 **Concept check:** `PATH` is just a list of folders your shell searches through (left to right) whenever you type a command name. If a tool's folder isn't in that list, the shell has no way to find it — even though the file physically exists on disk.

> 📸 *Screenshot placeholder: `echo $PATH` output showing `/opt/anaconda3/bin` included*

---

## 5. Launching & Closing Navigator from the CLI

**Launch (blocks the terminal until closed):**
```bash
anaconda-navigator
```

**Launch in the background (frees up the terminal immediately):**
```bash
anaconda-navigator &
```

**Closing it:**
- Click the window's red close button, **or**
- In the terminal running it, press `Ctrl + C`
- If frozen: open **Activity Monitor** (`Cmd+Space` → "Activity Monitor") → find `anaconda-navigator` → Force Quit

---

## 6. Making Navigator Launchable Like a Normal Mac App

By default, Navigator only opens via CLI — there's no Applications icon. Two ways to fix this:

### Option A — Automator wrapper app (most reliable on Apple Silicon)
1. `Cmd + Space` → search **Automator** → **New Document** → **Application**
2. Add a **"Run Shell Script"** action
3. Paste:
   ```bash
   /opt/anaconda3/bin/anaconda-navigator
   ```
4. **File → Save** → name it `Anaconda Navigator` → save to **Applications**
5. Now it appears in Launchpad/Applications/Dock like any other app

> 📸 *Screenshot placeholder: Automator "Run Shell Script" action with the command pasted in*

### Option B — Check for a bundled .app first
Sometimes the installer drops an actual `.app` bundle you can just move:
```bash
ls /opt/anaconda3/
# look for "Anaconda Navigator.app"
mv /opt/anaconda3/Anaconda\ Navigator.app /Applications/
```

### Pin it to the Dock (after either option)
Finder → Applications → find **Anaconda Navigator** → right-click → **Options** → **Keep in Dock**

---

## 7. Quick Reference Table

| Problem | Root Cause | Fix |
|---|---|---|
| "Path already exists" on install | Leftover install at `/opt/anaconda3` | `sudo rm -rf /opt/anaconda3` + clean `.zshrc` |
| `(base)` always in prompt | Auto-activation enabled by default | `conda config --set auto_activate_base false` |
| `command not found: anaconda-navigator` | Binary not on PATH | Add `/opt/anaconda3/bin` to PATH + `conda init zsh` |
| Navigator only opens via CLI | No GUI app bundle in Applications | Build Automator wrapper app |
| Navigator window won't close | Process stuck | `Ctrl+C` in terminal, or Force Quit via Activity Monitor |

---

## 8. Lab / Follow-Up Ideas

- [ ] Confirm the Automator app launches Navigator without needing Terminal open
- [ ] Try creating a conda environment (`conda create -n test python=3.11`) to confirm the install is fully functional
- [ ] Document architecture check: `uname -m` should return `arm64` on Apple Silicon — useful to verify *before* downloading any future CLI tool installer (AWS CLI, Terraform, etc.) to avoid the same wrong-architecture issue