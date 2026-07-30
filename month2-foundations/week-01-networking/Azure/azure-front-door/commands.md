# Azure Front Door — Commands

All CLI commands actually run this session. (Everything else — App Service, Front
Door, origin groups, routes, rule sets — was configured via the Azure Portal; see
`notes.md` for exact field values.)

## Round-robin verification (curl)

Browser hard-refreshes weren't reliable for testing round-robin (persistent HTTP/2
connections can reuse the same backend). Forcing a fresh connection per request with
`curl` gives an accurate read instead.

**First attempt** — grepped for "hostname"/"instance", but this only matched the
HTML table's *field labels*, not the actual values, so it wasn't useful:

```bash
for i in 1 2 3 4 5 6; do curl -s https://<your-endpoint>.z01.azurefd.net/ -H "Connection: close" | grep -i "hostname\|instance" ; done
```

**Working version** — grep for the actual App Service names to see which origin
served each request:

```bash
for i in 1 2 3 4 5 6; do curl -s https://<your-endpoint>.z01.azurefd.net/ -H "Connection: close" | grep -io "<yourprefix>-app0[12]" | head -1; done
```

Replace `<your-endpoint>` with your Front Door endpoint hostname (e.g.
`menniboe-endpoint-xxxxxxxx.z01.azurefd.net`) and `<yourprefix>` with your app name
prefix (e.g. `menniboe`).

Result this session: 6 requests → `app01, app02, app01, app01, app01, app02` — a
4:2 split, confirming both origins are receiving traffic under equal weight.