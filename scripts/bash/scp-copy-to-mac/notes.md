# scp — Copy a File from Remote Ubuntu to Mac

## The Issue

Running `scp` **on the Ubuntu server** (inside an SSH session) breaks the destination path. `~` expands to the *server's* home directory (`/root`), not your Mac's, so the local destination path becomes invalid.

```
root@localhost:~# scp root@97.107.130.14:/var/www/example.com/html/index.html ~/Example/example-user/Desktop
scp: open local "/root/Example/example-user/Desktop": No such file or directory
```

## The Fix

Run `scp` **from your Mac's terminal**, not from inside the SSH session on the server.

```bash
scp root@97.107.130.14:/var/www/example.com/html/index.html /Example/example-user/Desktop/
```

Or using `~` (safe now, since it's expanded by your Mac shell):

```bash
scp root@97.107.130.14:/var/www/example.com/html/index.html ~/Desktop/
```

## General Syntax

```bash
scp username@remote_ip:/path/to/remote/file /path/to/local/destination
```

| Scenario | Command |
|---|---|
| Custom SSH port/key | `scp -P 2222 -i ~/.ssh/example-key.pem ubuntu@172.0.113.10:/home/ubuntu/file ~/Desktop/` |
| Copy a folder | `scp -r ubuntu@172.0.113.10:/home/ubuntu/myfolder ~/Desktop/` |

## Key Takeaway

> `scp` direction matters: run it on the machine you want the file to **land on**, using a remote source path and a local destination path. Running it on the remote machine instead flips the assumptions and breaks `~`.