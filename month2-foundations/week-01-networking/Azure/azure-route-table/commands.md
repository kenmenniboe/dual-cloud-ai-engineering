# Commands — Azure Route Table Demo

## SSH Connection
```bash
ssh -i /path/to/your-key.pem azureuser@<VM_PUBLIC_IP>
```

## Connectivity Testing

**Baseline test (before Route Table applied):**
```bash
ping -c 4 8.8.8.8
```
Expected/actual result: 0% packet loss, replies received.

**Post-Route-Table test (after `0.0.0.0/0 → None` applied and associated):**
```bash
ping -c 4 8.8.8.8
```
Actual result: SSH session itself disconnected —
```
Read from remote host <public-ip>: Operation timed out
Connection to <public-ip> closed.
client_loop: send disconnect: Broken pipe
```