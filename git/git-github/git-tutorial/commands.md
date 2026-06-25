# Git & GitHub — Copy-Paste Command Reference

---

## Module 1: Git Foundations

```bash
# Check Git version
git --version

# Configure identity (run once globally)
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Initialize a new repo
mkdir myproject && cd myproject
git init

# Check working directory status
git status

# Stage a file
git add README.md

# Stage all changes
git add .

# Commit staged changes
git commit -m "Initial commit"

# View compact commit history
git log --oneline

# Show unstaged changes
git diff

# Show staged changes (not yet committed)
git diff --staged
```

---

## Module 2: Branching & Workflow

```bash
# List local branches
git branch

# Create and switch to a new branch
git checkout -b feature/login

# Switch to an existing branch
git checkout main

# Merge a branch into the current branch
git merge feature/login

# Rebase current branch onto main
git rebase main

# Interactive rebase — edit last 3 commits
git rebase -i HEAD~3

# Stash uncommitted changes
git stash

# Stash with a message
git stash push -m "WIP login feature"

# List stashes
git stash list

# Apply most recent stash (keeps it in list)
git stash apply

# Apply and remove most recent stash
git stash pop

# Create an annotated tag
git tag -a v1.0 -m "Release version 1.0"

# View tag details
git show v1.0

# List all tags
git tag
```

---

## Module 3: Remote Collaboration

```bash
# Clone a remote repository
git clone https://github.com/USERNAME/REPO.git

# View remote URLs
git remote -v

# Add a remote
git remote add origin https://github.com/USERNAME/REPO.git

# Update remote URL
git remote set-url origin https://github.com/USERNAME/REPO.git

# Push local branch and set upstream tracking
git push -u origin main

# Push a feature branch
git push origin feature/login

# Fetch remote commits (no merge)
git fetch origin

# Pull remote commits (fetch + merge)
git pull origin main

# Save credentials permanently to disk (plaintext)
git config --global credential.helper store

# Save credentials in memory for 15 minutes
git config --global credential.helper cache
```

---

## Module 4: Advanced Git

```bash
# View reflog (all recent HEAD positions)
git reflog

# Jump to a previous HEAD position
git checkout HEAD@{2}

# Undo last commit — keep changes staged
git reset --soft HEAD~1

# Undo last commit — discard all changes (DESTRUCTIVE)
git reset --hard HEAD~1

# Reverse last commit via a new commit (safe for shared branches)
git revert HEAD

# Create useful aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"

# Use an alias
git co main
git lg
```

---

## Module 5: Enterprise & CI/CD

```bash
# Visualize all branches and commit history
git log --oneline --graph --all

# GitHub Actions CI workflow — save as .github/workflows/ci.yml
# ---
# name: CI
# on: [push, pull_request]
# jobs:
#   build:
#     runs-on: ubuntu-latest
#     steps:
#       - uses: actions/checkout@v3
#       - name: Run tests
#         run: echo "Run your build/test scripts"
```

---

## Module 6: Branch Management & Cleanup

### Rename a Branch

```bash
# Step 1: Rename locally
git branch -m old-name new-name

# Step 2: Push new name and set upstream
git push origin -u new-name

# Step 3: Delete old name from remote
git push origin --delete old-name

# Step 4: Verify
git branch -a
```

### Overwrite Main with Another Branch (Force-Push)

> ⚠️ DESTRUCTIVE — rewrites remote history. Use only on solo repos or after coordinating with your team.

```bash
# Step 1: Confirm clean working tree
git status

# Step 2: Switch to your clean branch
git checkout clean-branch

# Step 3: Delete old local main
git branch -D main

# Step 4: Create new main from clean branch
git checkout -b main

# Step 5: Force-push to remote
git push --force origin main

# Step 6: Verify
git log --oneline
git branch -a
```

### Safer Force-Push Alternative

```bash
# Refuses to push if someone else pushed since your last fetch
git push --force-with-lease origin main
```

### Prune Stale Branches

```bash
# List all local and remote branches
git branch -a

# List merged branches
git branch --merged

# Safe delete merged local branch
git branch -d branch-name

# Force delete unmerged local branch
git branch -D branch-name

# Delete branch from remote
git push origin --delete branch-name

# Remove stale remote-tracking refs
git fetch --prune
```

---

## Scaffold This Folder (One-Liner)

Run this from your repo root to create the folder and all three files:

```bash
mkdir -p day-thu-jun26-git-tutorial && touch day-thu-jun26-git-tutorial/{README.md,notes.md,commands.md}
```

---

## Quick Reference Table

| Command | What It Does |
|---------|-------------|
| `git init` | Initialize a new local repo |
| `git status` | Show working tree state |
| `git add .` | Stage all changes |
| `git commit -m "msg"` | Commit staged changes locally |
| `git push origin main` | Send commits to remote |
| `git pull origin main` | Fetch + merge from remote |
| `git fetch origin` | Download without merging |
| `git clone <url>` | Initial copy of remote repo |
| `git branch` | List local branches |
| `git checkout -b <branch>` | Create and switch branch |
| `git merge <branch>` | Merge into current branch |
| `git rebase <branch>` | Rebase onto another branch |
| `git stash` | Shelve uncommitted changes |
| `git stash pop` | Restore and remove stash |
| `git reflog` | View all HEAD movements |
| `git reset --soft HEAD~1` | Undo commit, keep staged |
| `git reset --hard HEAD~1` | Undo commit, discard changes |
| `git revert HEAD` | Reverse commit safely |
| `git log --oneline` | Compact commit history |
| `git log --oneline --graph --all` | Visual branch graph |
| `git tag -a v1.0 -m "msg"` | Create annotated tag |
| `git branch -d <name>` | Safe delete local branch |
| `git branch -D <name>` | Force delete local branch |
| `git push origin --delete <name>` | Delete remote branch |
| `git fetch --prune` | Remove stale remote refs |
| `git push --force origin main` | Overwrite remote history |
| `git push --force-with-lease` | Force-push with safety check |
| `git remote -v` | View remote URLs |
| `git remote set-url origin <url>` | Update remote URL |