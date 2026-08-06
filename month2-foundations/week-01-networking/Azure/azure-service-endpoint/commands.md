# Commands — Azure Service Endpoint Lab

## Blob Access Test — Jumpbox (Ubuntu, via Bastion)

```bash
# Correct — full SAS URL wrapped in quotes
curl "https://<storage-account-name>.blob.core.windows.net/content/test.txt?sp=r&st=<start>&se=<expiry>&spr=https&sv=<version>&sr=b&sig=<signature>"
```

## Blob Access Test — Local Machine

```bash
# Same command, run from your own terminal/browser to compare against the jumpbox result
curl "https://<storage-account-name>.blob.core.windows.net/content/test.txt?sp=r&st=<start>&se=<expiry>&spr=https&sv=<version>&sr=b&sig=<signature>"
```

## Attempted / Common Mistake (kept for reference)

```bash
# WRONG — unquoted URL. Bash treats each & as a background-job separator,
# silently splitting the command and dropping the SAS signature entirely.
# Produces a misleading "ResourceNotFound" error.
curl https://<storage-account-name>.blob.core.windows.net/content/test.txt?sp=r&st=<start>&se=<expiry>&spr=https&sv=<version>&sr=b&sig=<signature>
```