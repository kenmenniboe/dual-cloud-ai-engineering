# Initialize repo
git init

# Check status
git status

# Create initial files/folders
touch README.md
mkdir -p docs diagrams scripts/python scripts/bash

# Create docs files
touch docs/linux-notes.md docs/networking-notes.md docs/tls-explained.md docs/nginx-notes.md docs/python-basics.md docs/azure-notes.md docs/aws-notes.md

# Create diagrams files
touch diagrams/week1-network-flow.png diagrams/nginx-architecture.png diagrams/azure-architecture.png diagrams/aws-architecture.png diagrams/final-architecture.png

# Create scripts files
touch scripts/python/api_call.py scripts/python/system_info.py scripts/python/file_writer.py
touch scripts/bash/nginx_setup.sh scripts/bash/system_update.sh

# Stage and commit
git add .
git commit -m "Initial project structure"

# Create branches
git branch -M main
git branch test
git branch prod

# Switch branches
git switch main
git switch test
git switch prod

# Add GitHub remote
git remote add origin <your-repo-url>
git remote -v

# Push branches
git push -u origin main
git push -u origin test
git push -u origin prod

# Merge main into other branches
git switch test
git merge main
git push

git switch prod
git merge main
git push
