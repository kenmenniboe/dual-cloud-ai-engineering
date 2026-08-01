# Commands — Azure Private DNS Zone Lab

## DNS Resolution Testing (Bastion Session)

```bash
nslookup app1.internal.corp
```

```bash
nslookup app2.internal.corp
```

## GitHub — Save Today's Lab Notes

Create the folder and empty files:
```bash
mkdir -p azure-private-dns/images && touch azure-private-dns/{README.md,notes.md,commands.md}
```

Add, commit, and push:
```bash
git add azure-private-dns && git commit -m "Add Azure Private DNS Zone lab notes" && git push
```