# Git & GitHub — Concept Notes

---

## Module 1: Git Foundations

### What is Git?
Git is a **distributed version control system (DVCS)**.  
It records snapshots of your project over time so you can track changes, collaborate, and roll back safely.

**Distributed** means every developer has a full copy of the repository and its complete history — no single point of failure, and you can work offline.

### Three-Area Model

```
Working Directory  →  Staging Area (Index)  →  Local Repository (.git)
   (edit files)         (git add)                  (git commit)
```

- **Working Directory** — where you edit files
- **Staging Area** — where you prepare a snapshot
- **Local Repository** — permanent history, stored in `.git`

### Key Distinction: commit vs push

| Command | What it does | Where it lives |
|---------|-------------|----------------|
| `git commit` | Creates a permanent snapshot | Local repo only |
| `git push` | Sends local commits to remote | Remote (GitHub) |

> A commit is invisible to other developers until you push.

### Why Git matters in DevOps
- Versions your Terraform, CloudFormation, and Bicep IaC files
- Triggers CI/CD pipelines (GitHub Actions fires on `push` or `pull_request`)
- Enables reproducibility and auditability in production

---

## Module 2: Branching & Workflow

### Branching
A branch is an isolated workspace. Changes on a branch don't affect other branches until you merge or rebase.

**Default branch:** `main` (or `master` in older repos)

### Merge vs Rebase

| | Merge | Rebase |
|---|-------|--------|
| History | Preserves branch history, adds merge commit | Rewrites history onto target branch — linear |
| Use case | Feature → main in team workflows | Cleaning up local commits before pushing |
| Safety | Safe on shared branches | Avoid rebasing commits already pushed to shared branches |

### Stashing
Temporarily saves uncommitted work so you can switch contexts without committing half-done changes.

```
git stash       →  saves current changes
git stash apply →  restores saved changes (keeps stash)
git stash pop   →  restores and deletes the stash entry
```

### Tags
Tags mark specific commits — typically used for releases.

```
git tag -a v1.0 -m "Release 1.0"   # annotated tag
git show v1.0                       # inspect tag
```

---

## Module 3: Remote Collaboration

### Git vs GitHub

| Git | GitHub |
|-----|--------|
| Command-line tool, runs locally | Cloud platform for hosting Git repos |
| Works fully offline | Requires internet |
| Version control engine | Collaboration + automation layer |

**Analogy:** Git = Docker engine. GitHub = Docker Hub.

### Fetch vs Pull

| Command | Downloads commits | Merges into branch |
|---------|------------------|--------------------|
| `git fetch` | Yes | No — review before merging |
| `git pull` | Yes | Yes — fetch + merge in one step |

> `git pull` = `git fetch` + `git merge`

Use `git fetch` when you want to review remote changes before integrating them.

### Remote URL Management

```bash
git remote -v                          # view current remote URLs
git remote set-url origin <URL>        # update remote URL
git push -u origin main                # push and set upstream tracking
```

### Credential Helper

```bash
git config --global credential.helper store   # saves PAT to disk (plaintext)
git config --global credential.helper cache   # saves in memory for 15 min
```

> Security note: `store` writes credentials unencrypted to `~/.git-credentials`. Use `cache` if you prefer time-limited storage.

---

## Module 4: Advanced Git

### Reflog
The reflog is a local safety net — it records every position HEAD has pointed to, even after resets or deleted branches.

```
git reflog              # see all recent HEAD positions
git checkout HEAD@{2}   # jump back to a previous state
```

> Use this to recover "lost" commits after an accidental reset.

### Undoing Changes

| Command | What it does | Destructive? |
|---------|-------------|-------------|
| `git reset --soft HEAD~1` | Undo last commit, keep changes staged | No |
| `git reset --hard HEAD~1` | Undo last commit, discard all changes | Yes |
| `git revert HEAD` | Create a new commit that reverses last commit | No (safe for shared branches) |

**Rule of thumb:**  
- Use `reset` on local-only commits  
- Use `revert` on commits already pushed to a shared branch

### Git Aliases
Shortcuts for frequently used commands:

```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --all"
```

---

## Module 5: Enterprise & CI/CD Workflows

### GitHub Flow (recommended for most teams)

```
main → feature/branch → Pull Request → Review → Merge → Deploy
```

Simple, linear, works well with CI/CD.

### Git Flow (for versioned releases)

```
main → develop → feature/* → release/* → hotfix/*
```

More structure — suits teams shipping versioned software.

### GitHub Actions CI/CD Trigger
Pipelines trigger on **push** and **pull_request** events — not on local commits.

```yaml
on: [push, pull_request]
```

> This is why pushing is operationally significant in cloud-native workflows.

---

## Module 6: Branch Management & Cleanup

### Renaming a Branch (safe procedure)
1. Rename locally: `git branch -m old-name new-name`
2. Push new name and set upstream: `git push origin -u new-name`
3. Delete old name from remote: `git push origin --delete old-name`
4. Update default branch in GitHub Settings if needed

### Force-Push Warning
`git push --force origin main` replaces remote history entirely.

- Safe on personal/solo repos
- Dangerous on shared repos — collaborators will have divergent history
- Consider `--force-with-lease` as a safer alternative: refuses to push if someone else pushed since your last fetch

### Pruning Stale Branches

```bash
git branch --merged          # list branches already merged
git branch -d branch-name    # safe delete (won't delete unmerged)
git branch -D branch-name    # force delete
git push origin --delete branch-name   # delete from remote
git fetch --prune            # clean up stale remote-tracking refs
```

---

## Key Concepts Summary

| Concept | One-Line Definition |
|---------|---------------------|
| Commit | Local snapshot of staged changes |
| Push | Send local commits to remote |
| Pull | Fetch + merge remote commits into local |
| Fetch | Download remote commits without merging |
| Clone | Initial full copy of a remote repo |
| Branch | Isolated workspace for changes |
| Merge | Combine branch history |
| Rebase | Rewrite commits onto another branch |
| Stash | Temporarily shelve uncommitted changes |
| Reflog | Local log of all HEAD movements |
| Tag | Named pointer to a specific commit |
| Force-push | Overwrite remote history with local history |
