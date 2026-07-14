# How to Add Images to README.md

Quick reference for embedding screenshots/images in a GitHub README, via VSCode (local) or the GitHub website.

---

## Method 1: VSCode (Local) — Recommended

### Step 1: Create an images folder (once per lab folder)
```bash
mkdir images
```

### Step 2: Copy the image into that folder
Use `cp` with **source** and **destination**. `cp` alone will error if you forget the destination.

```bash
cp '/Users/exampleuser/Downloads/YOUR-FILE.jpg' ./images/descriptive-name.jpg
```

- Always give the image a clean, descriptive, lowercase name (`nginx-tls-handshake.jpg`, not `IMG_6621.jpg`).
- The trailing filename in the destination both **copies and renames** in one step.
- Run `pwd` first if unsure whether you're in the right lab folder.

### Step 3: Reference the image in README.md
In the README.md file itself (not the terminal), on its own line:

```markdown
![Alt text description](images/descriptive-name.jpg)
```

⚠️ The filename after `images/` must match **exactly** — including case — what you named the file in Step 2.

### Step 4: Preview before committing
In VSCode, open README.md and press `Cmd+Shift+V` to open Markdown preview and confirm the image renders.

### Step 5: Commit and push
```bash
git add .
git commit -m "Add [description] screenshot to README"
git push
```

---

## Method 2: GitHub Website

1. Navigate to the repo folder on github.com.
2. Click **Add file → Upload files**, drag in the image, commit.
3. Open README.md, click the **pencil icon** to edit.
4. Add the same syntax:
   ```markdown
   ![Alt text description](images/descriptive-name.jpg)
   ```
5. Scroll down, **Commit changes**.

**Shortcut:** dragging an image directly into the README's web editor auto-uploads and inserts the link — fast, but stores the image in a hidden GitHub assets location instead of your own `images/` folder (less tidy for a self-contained portfolio repo).

---

## Common Mistake to Avoid

Don't mix the terminal command and the Markdown syntax into one line — they're two separate steps in two separate places:

❌ `cp 'file.jpg' . ![Description](images/screenshot.png)`

✅ Terminal: `cp 'file.jpg' ./images/name.jpg`
✅ README.md: `![Description](images/name.jpg)`

---

## Quick Checklist
- [ ] `images/` folder exists in the lab folder
- [ ] Image copied in with a clean, descriptive filename
- [ ] Markdown reference filename matches exactly (case-sensitive)
- [ ] Previewed in VSCode before pushing
- [ ] Committed with a clear message