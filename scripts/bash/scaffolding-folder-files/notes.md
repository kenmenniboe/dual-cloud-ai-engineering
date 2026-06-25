# Scaffolding a Folder + Files in One Shot

## The Command

```bash
mkdir -p anaconda-navigator-setup && touch anaconda-navigator-setup/{README.md,notes.md,commands.md}
```

## How It Works

**`mkdir -p anaconda-navigator-setup`**
Creates the folder. The `-p` flag means "don't error if it already exists" (and it would also create any missing parent folders if your path had nested directories).

**`&&`**
Runs the next command only if the first one succeeded. This protects you from `touch` trying to create files inside a folder that failed to be made.

**`touch anaconda-navigator-setup/{README.md,notes.md,commands.md}`**
`touch` creates empty files (or updates the timestamp if they already exist). The `{a,b,c}` part is **brace expansion** — the shell expands it into three separate paths before running the command:

```
anaconda-navigator-setup/README.md
anaconda-navigator-setup/notes.md
anaconda-navigator-setup/commands.md
```

So one `touch` call creates all three files at once, no loop needed.

## General Template

```bash
mkdir -p folder-name && touch folder-name/{file1,file2,file3}
```

## Ready-to-Run for This Session

```bash
mkdir -p anaconda-navigator-setup && touch anaconda-navigator-setup/{README.md,notes.md,commands.md}
```

## Key Takeaway

> Brace expansion `{a,b,c}` lets you template a repeated path prefix once instead of typing it three times — same trick works for any number of files, any extension mix (as seen in your `password_generator.py` example).