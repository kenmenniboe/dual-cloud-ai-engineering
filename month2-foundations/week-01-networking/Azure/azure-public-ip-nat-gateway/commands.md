# Commands — Azure Public IP + NAT Gateway Lab

All resource creation in this session was done via the **Azure Portal** (see `notes.md` §10 for full field-by-field steps). The only CLI-level commands were run **inside the jumpbox VM** (via Bastion) to verify outbound connectivity.

## Jumpbox — Outbound Connectivity Verification

```bash
# Confirm the public-facing IP the internet sees (should match the NAT Gateway's Public IP)
curl -s ifconfig.me

# Backup, if ifconfig.me is slow/unreachable
curl -s https://api.ipify.org
```

```bash
# Sanity check general outbound reachability (package repo access)
sudo apt update
```

## Jumpbox — Negative Test (after detaching NAT Gateway from the subnet in the Portal)

```bash
# Expect this to time out / return nothing — confirms no outbound path exists without the NAT Gateway
curl -s --max-time 10 ifconfig.me
```

## Jumpbox — Post-Reattach Confirmation

```bash
# After reattaching natgw-lab to snet-workload in the Portal, re-confirm connectivity is restored
curl -s ifconfig.me
```

---

**Observed results this session:**
| Command | Result |
|---|---|
| `curl -s ifconfig.me` (NAT Gateway attached) | `20.15.150.94` |
| `sudo apt update` | Succeeded — 36.4 MB fetched |
| `curl -s --max-time 10 ifconfig.me` (NAT Gateway detached) | Empty / timed out |
| `curl -s ifconfig.me` (reattached) | `20.15.150.94` — restored |