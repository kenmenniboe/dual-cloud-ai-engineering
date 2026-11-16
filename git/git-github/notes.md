# Git — Cloning, Redirecting Origin & Pushing to Your Own Repo

**Date:** 2026-05-28  
**Topic:** Git clone workflow, remote management, PAT permissions, push troubleshooting  
**Environment:** macOS (darwin_amd64), Terminal, GitHub

---

## What I Learned Today

### 1. `git clone` Does More Than Copy Files

When you run `git clone <url>`, Git automatically:
- Creates a new folder named after the repo
- Initialises a `.git` folder inside it (making it a valid local git repo)
- Sets up a remote called `origin` pointing back to the cloned URL

**Common mistake:** Running `git status` in the *parent* folder instead of the cloned folder.

```bash
# Wrong — parent folder has no .git
cd ~/Desktop/My_Cloud_AI_Engineer_Journey/azure_networking
git status
# fatal: not a git repository

# Correct — cd into the cloned folder first
cd azure-network-course
git status
# On branch main — nothing to commit, working tree clean
```

**Tip:** Use Tab completion to avoid typos when changing directories.

---

### 2. Checking Your Current Remote

```bash
git remote -v
```

This shows the fetch and push URLs for all configured remotes. After cloning someone else's repo, `origin` points to *their* GitHub — not yours.

---

### 3. Redirecting `origin` to Your Own Repo

You cannot `git remote add origin <url>` when `origin` already exists — that throws an error. Use `set-url` instead:

```bash
# Step 1 — Create a new empty repo on GitHub first
# Step 2 — Update origin to point to your new repo
git remote set-url origin https://github.com/<your-username>/<your-repo>.git

# Step 3 — Verify
git remote -v
```

---

### 4. GitHub Personal Access Token (PAT) — `workflow` Scope

When pushing a repo that contains a `.github/workflows/` folder, GitHub requires your PAT to have the **`workflow`** scope, otherwise the push is rejected:

```
! [remote rejected] main -> main (refusing to allow a Personal Access Token to
create or update workflow `.github/workflows/github-actions.yml` without `workflow` scope)
```

**Fix:**
1. GitHub → Profile → Settings → Developer Settings
2. Personal Access Tokens (classic) → click your token
3. Check the **`workflow`** checkbox → Update token

---

### 5. Fixing SSL / Large Push Buffer Errors

For large repos, Git can hit an SSL buffer limit mid-transfer. Fix by increasing the HTTP post buffer:

```bash
git config http.postBuffer 157286400
git push origin main
```

---

## Key Commands Reference

| Command | Purpose |
|---|---|
| `git clone <url>` | Clone a remote repo locally |
| `git status` | Check working tree status |
| `git remote -v` | List all remotes with URLs |
| `git remote set-url origin <url>` | Update an existing remote URL |
| `git remote add origin <url>` | Add a new remote (only if none exists) |
| `git push origin main` | Push local main branch to origin |
| `git config http.postBuffer 157286400` | Increase buffer for large pushes |

---

## Today's Troubleshooting Flow

```
git status → fatal: not a git repository
    ↓ ran pwd + ls -la
    ↓ realised I was in the parent folder
cd azure-network-course
git status → clean ✓

git remote -v → origin pointed to HoussemDellai's repo
    ↓ created new repo on GitHub
git remote set-url origin https://github.com/kenmenniboe/azure-networking-fundamentals.git
git remote -v → origin updated ✓

git push origin main → rejected (missing workflow PAT scope)
    ↓ added workflow scope to PAT on GitHub
git push origin main → SSL buffer error
    ↓ increased http.postBuffer
git push origin main → Everything up-to-date ✓
```

---

## Also Covered

- Updated Terraform from v1.10.2 → v1.15.5 via Homebrew
  - `brew link --overwrite hashicorp/tap/terraform` resolved a conflicting symlink