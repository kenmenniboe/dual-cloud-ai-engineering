# Day 01 — Linux + Git (Detailed Notes)

## Overview
This document is a complete walkthrough of everything I practiced today:
- Understanding Git behavior in an empty repo
- Creating initial files and folder structures
- Building docs/, diagrams/, and scripts/ directories
- Creating and pushing Git branches (main, test, prod)
- Connecting a local repo to GitHub
- Merging branches and keeping environments in sync

This serves as a mini‑tutorial and proof of work for Day 01.

---

## 1. Understanding Git in an Empty Repository

### What Happens When a Repo Has No Files
When I first ran:
git status

Git showed: nothing to commit, working tree clean


I learned:
- Git only tracks files **after they exist**
- An empty folder = nothing to track
- You must create files before Git can stage or commit anything

### Screenshot Placeholder
![screenshot](images/git-empty-status.png)

---

## 2. Creating Initial Files and Folders

To make Git start tracking changes, I created the first project structure.

### Commands Used

mkdir -p docs diagrams scripts/python scripts/bash

touch README.md

Then I added the docs files: 

touch docs/linux-notes.md docs/networking-notes.md docs/tls-explained.md docs/nginx-notes.md docs/python-basics.md docs/azure-notes.md docs/aws-notes.md

And the diagrams:

touch diagrams/week1-network-flow.png diagrams/nginx-architecture.png diagrams/azure-architecture.png diagrams/aws-architecture.png diagrams/final-architecture.png

And the scripts:

touch scripts/python/api_call.py scripts/python/system_info.py scripts/python/file_writer.py
touch scripts/bash/nginx_setup.sh scripts/bash/system_update.sh

### Screenshot Placeholder
![screenshot](images/folder-structure-created.png)

---

## 3. Creating and Managing Git Branches

I set up a clean multi‑branch workflow.

### Why Multiple Branches?
- **main** → stable working branch  
- **test** → for experimenting and validating changes  
- **prod** → final deployment branch  

### Commands Used

#### Create branches

git branch -M main

git branch test

git branch prod

#### Switch between branches

git switch main

git switch test

git switch prod

### Screenshot Placeholder
![screenshot](images/git-branches.png)

---

## 4. Connecting Local Repo to GitHub

To push my work, I connected my local repo to GitHub.

### Steps I Followed

1. Opened GitHub → clicked **Code** → copied HTTPS URL  

2. Added the remote:

git remote add origin <your-repo-url>

3. Verified the connection:

git remote -v

### Expected Output

origin  https://github.com/<username>/<repo>.git (fetch)

origin  https://github.com/<username>/<repo>.git (push)

### Screenshot Placeholder
![screenshot](images/git-remote-added.png)

---

## 5. Pushing All Branches to GitHub

Once the remote was set, I pushed each branch.

### Commands Used

#### Push main
git push -u origin main

#### Push test
git push -u origin test

#### Push prod
git push -u origin prod

### Screenshot Placeholder
![screenshot](images/github-branches.png)

---

## 6. Merging main Into test and prod

To keep all branches synced, I merged `main` into the others.

### Commands Used

#### Merge into test

git switch test

git merge main

git push

#### Merge into prod

git switch prod

git merge main

git push

### Screenshot Placeholder
![screenshot](images/git-merge.png)

---

## 7. Final Project Structure Created Today

I built a clean, professional folder structure using one‑liners.

### docs/
touch docs/linux-notes.md docs/networking-notes.md docs/tls-explained.md docs/nginx-notes.md docs/python-basics.md docs/azure-notes.md docs/aws-notes.md

### diagrams/
touch diagrams/week1-network-flow.png diagrams/nginx-architecture.png diagrams/azure-architecture.png diagrams/aws-architecture.png diagrams/final-architecture.png

### scripts/
mkdir -p scripts/python scripts/bash
touch scripts/python/api_call.py scripts/python/system_info.py scripts/python/file_writer.py
touch scripts/bash/nginx_setup.sh scripts/bash/system_update.sh

### Screenshot Placeholder
![screenshot](images/folder-structure-final.png)

---

## 8. Summary / Key Takeaways

- Git needs **actual files** before it can track changes  
- Creating a clean folder structure makes the repo professional  
- Multi‑branch workflows (`main`, `test`, `prod`) mirror real DevOps pipelines  
- `git remote add origin` connects local work to GitHub  
- `git push -u origin <branch>` sets upstream tracking  
- Merging keeps all branches aligned  
- One‑liner commands (`mkdir -p`, `touch`) save time and reduce errors  

This completes Day 01 of Linux + Git.