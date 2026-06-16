### **Group 1: Authentication & Remote Configuration**

git remote \-v

View the current remote URLs (fetch and push) to confirm where your repo points. Use this at the start of any session to verify your remote configuration.

git remote set-url origin \<URL\>

Code

git remote set-url origin https://github.com/USERNAME/REPO.git

Update the remote URL to a new endpoint. Use this when switching between HTTPS and SSH, or when the repository URL has changed.

git config \--global credential.helper store

Code

git config \--global credential.helper store

Save your credentials permanently in plaintext to a file on disk (\~/.git-credentials) so you are not prompted for a username and token on every push. Security note: credentials stored this way are unencrypted and readable by anyone with access to your home directory. If you prefer time-limited storage that does not write to disk, use git config \--global credential.helper cache instead, which keeps credentials in memory for 15 minutes by default. Use the store helper after setting up a new PAT only if you understand and accept the plaintext storage trade-off.

git push \-u origin main

Code

git push \-u origin main

Push the local main branch to the remote and set it as the upstream tracking branch. Use this after initial setup or after renaming your default branch.

### **Group 2: Folder Restructuring**

git mv source destination

Code

git mv source destination

Move or rename a file or directory while preserving Git history. Use this instead of manual file moves whenever reorganizing a repo's folder structure.

git add .

Code

git add .

Stage all changes in the current directory and below. Use this after completing a batch of file moves or edits to prepare them for commit.

git commit \-m "message"

Code

git commit \-m "Restructure repository layout"

Commit all staged changes with a descriptive message. Use this after staging to lock in your changes as a permanent snapshot in history.

git status

Code

git status

Check the working tree for staged, unstaged, and untracked changes. Use this before and after moves or commits to confirm the repo is in the expected state.

### **Group 3: Branch Management**

git branch

Code

git branch

List all local branches and highlight the currently checked-out branch. Use this to see what branches exist on your machine.

git branch \-a

Code

git branch \-a

List all branches — local and remote-tracking. Use this to get a complete picture of every branch, including those on the remote.

git branch \-m old-name new-name

Code

git branch \-m old-name new-name

Rename a local branch. Use this when a branch name does not follow conventions or needs to be updated to match a new naming standard.

git branch \-d branch-name

Code

git branch \-d branch-name

Delete a local branch safely — Git will refuse if the branch has unmerged changes. Use this for routine cleanup of branches you have already merged.

git branch \-D branch-name

Code

git branch \-D branch-name

Force-delete a local branch regardless of merge status. Use this when you are certain the branch is no longer needed, even if it was never merged.

git push origin \-u new-name

Code

git push origin \-u new-name

Push a renamed branch to the remote and set upstream tracking. Use this immediately after renaming a branch locally.

git push origin \--delete old-name

Code

git push origin \--delete old-name

Delete a branch from the remote. Use this after pushing the renamed branch to clean up the old name on GitHub.

### **Group 4: Overwriting and Force-Pushing**

git checkout branch-name

Code

git checkout branch-name

Switch to an existing branch. Use this to move your working directory to the branch you want to work on or promote.

git checkout \-b new-branch

Code

git checkout \-b new-branch

Create a new branch from the current HEAD and switch to it immediately. Use this to create main from a clean branch.

git push \--force origin main

Code

git push \--force origin main

Force-push the local main branch to the remote, overwriting whatever was there before. DANGEROUS — use this deliberately and only when you intend to replace remote history entirely.

git log \--oneline

Code

git log \--oneline

Display a compact, one-line-per-commit view of the branch history. Use this to quickly verify that your commit history looks clean after a restructure.

git log \--oneline \--graph \--all

Code

git log \--oneline \--graph \--all

Display a visual graph of all branches and their commit history. Use this for a bird's-eye view of how branches relate to each other.

## **4\. Step-by-Step Procedures**

### **Procedure A: How to Rename a Branch**

1. Check which branch you are currently on:  
   git branch  
2. Rename the branch locally:  
   git branch \-m old-name new-name  
3. Push the renamed branch to the remote and set upstream tracking:  
   git push origin \-u new-name  
4. Delete the old branch name from the remote:  
   git push origin \--delete old-name  
5. On GitHub, go to Settings → Branches → Default branch and update the default to the new branch name.  
6. Verify the rename is complete:  
   git branch \-a  
7. Confirm that only the new name appears locally and on the remote.

### **Procedure B: How to Overwrite Main with Another Branch**

⚠ WARNING — Force-Push Consequences: This procedure permanently rewrites remote history. Any collaborator who has cloned or forked the repository will have a divergent history and may lose work. Only perform this on repositories where you are the sole contributor, or after coordinating with all collaborators. There is no undo for a force-push — the old remote history is gone.

1. Ensure your working tree is clean — no uncommitted changes:  
   git status  
2. Switch to the clean, well-organized branch you want to promote:  
   git checkout clean-branch  
3. Delete the old local main branch:  
   git branch \-D main  
4. Create a new main branch from your current (clean) branch:  
   git checkout \-b main  
5. Force-push the new main to the remote, replacing the old history:  
   git push \--force origin main  
6. On GitHub, verify that Settings → Branches → Default branch is set to main. Update if needed.  
7. Verify the result:  
   git log \--oneline  
   git branch \-a  
8. Confirm clean commit history and correct branch listing.

### **Procedure C: How to Clean Up Stale Branches**

1. List all local and remote-tracking branches:  
   git branch \-a  
2. Identify branches that have been merged or are no longer needed. Merged branches can be found with:  
   git branch \--merged  
3. Delete stale branches locally:  
   git branch \-d branch-name  
4. Use \-D (uppercase) if the branch was never merged and you are certain it should be removed.  
5. Delete stale branches from the remote:  
   git push origin \--delete branch-name  
6. Prune remote-tracking references that no longer exist on the remote:  
   git fetch \--prune  
7. This removes local references to remote branches that have already been deleted on GitHub.

## **5\. Command Summary — Quick Reference**

| Command | What It Does |
| :---- | :---- |
| git remote \-v | View current remote URLs |
| git remote set-url origin | Update the remote URL |
| git config \--global credential.helper store | Save credentials permanently in plaintext on disk |
| git mv source destination | Move/rename files preserving Git history |
| git add . | Stage all changes in the working tree |
| git commit \-m "message" | Commit staged changes with a message |
| git status | Check working tree for pending changes |
| git branch | List local branches |
| git branch \-a | List all branches (local \+ remote) |
| git branch \-m old-name new-name | Rename a local branch |
| git branch \-d branch-name | Delete a local branch (safe) |
| git branch \-D branch-name | Force-delete a local branch |
| git branch \--merged | List branches already merged into current branch |
| git push origin \-u new-name | Push renamed branch and set upstream |
| git push origin \--delete old-name | Delete a branch from the remote |
| git push \-u origin main | Push main and set upstream tracking |
| git checkout branch-name | Switch to an existing branch |
| git checkout \-b new-branch | Create and switch to a new branch |
| git push \--force origin main | Force-push, overwriting remote history |
| git log \--oneline | Compact one-line commit history |
| git log \--oneline \--graph \--all | Visual branch graph of all commits |
| git fetch \--prune | Remove stale remote-tracking references |

## **6\. Beginner-Friendly Concepts**

### **What Is Branch Cleanup?**

Think of branches as parallel workspaces. Every time you create a branch, you are making a copy of your project where you can experiment, build a feature, or try a new idea — without affecting the main version. This is powerful, but over time, old branches pile up like unused drafts in a filing cabinet. Some were experiments that went nowhere. Others were merged months ago but never deleted. A few might have confusing names that no longer mean anything.

Branch cleanup is the practice of reviewing all your branches, deleting the ones you no longer need, and ensuring the ones that remain are clearly named and purposeful. It signals professionalism — a recruiter or collaborator visiting your repo sees a clean list of branches, not a graveyard of abandoned experiments. It also prevents confusion: when there are twenty branches and only one matters, it is easy to accidentally work on the wrong one.

Keep in mind that branches exist in two places: locally (on your machine) and remotely (on GitHub). Deleting a branch locally does not remove it from the remote, and vice versa. A thorough cleanup addresses both. Use git branch \-a to see everything, then delete from both locations to keep your repo truly tidy.

### **What Is a Force-Push?**

When you run a normal git push, Git compares your local history with the remote history and only adds new commits on top of what already exists. It is additive — nothing is lost. But git push \--force works differently. It tells the remote: "Forget what you have — take this instead." It replaces the remote branch's entire history with whatever you have locally, whether that means fewer commits, different commits, or a completely rewritten timeline.

This is powerful and, in the right situation, necessary. Repository cleanups, history rewrites with git rebase, and branch promotions all require force-push because the local history has intentionally diverged from the remote. However, force-push is dangerous on shared repositories. Here is a helpful analogy: it is like replacing a document on a shared drive rather than appending to it. If someone else was editing the old version, their work is now based on a history that no longer exists on the remote — they will encounter merge conflicts or, worse, lose changes entirely.

The rule is simple: use git push \--force only when you are certain no one else depends on the old remote history. For a personal portfolio repo, that is almost always the case. For a team project, coordinate with your collaborators first, or consider git push \--force-with-lease, which adds a safety check by refusing to overwrite if someone else has pushed since your last fetch.

### **Overwriting Main with Another Branch**

Here is the scenario: you started working on main, added files quickly, made commits with vague messages, and ended up with a disorganized repository. Later, you created a new branch — maybe called clean-start or restructured — and carefully rebuilt everything: organized folders, clear commit messages, a polished README. Now the clean branch is exactly what you want main to be, but the actual main branch is still the old mess.

The solution is to promote the clean branch. You delete the old main locally, create a new main pointing at the clean branch's commits, and force-push so GitHub reflects the change. After this, the clean branch effectively becomes main — same commits, same history, new name. It is like tearing out the first draft of a report and replacing it with the final version.

This is a one-time reset, not a regular workflow. Once you have a clean main, you should protect it: work on feature branches, open pull requests, and merge into main through normal Git workflows. The promotion technique is a corrective action — it fixes a repo that started messy. Going forward, the discipline of branching and merging will keep things clean without needing another force-push.

