# Commands — Azure Load Balancer Lab

> Note: Load Balancer, VNet, VM, NSG, and NAT rule provisioning were all done via the **Azure Portal** in this session — no Azure CLI/PowerShell commands were used for resource creation. Commands below are the CLI/terminal commands actually run, grouped by workflow stage.

## SSH Access (via NAT Rules)

```bash
# Identify the private key file to use
ls -la ~/.ssh

# SSH to vm-web-1 (NAT rule: frontend port 50001 -> vm-web-1 port 22)
ssh -i ~/.ssh/<key-filename> -p 50001 azureuser@<LB_PUBLIC_IP>

# SSH to vm-web-2 (NAT rule: frontend port 50002 -> vm-web-2 port 22)
ssh -i ~/.ssh/<key-filename> -p 50002 azureuser@<LB_PUBLIC_IP>
```

## Web Server Setup (run on each VM, over SSH)

```bash
sudo apt update
sudo apt install -y nginx

# Serve the VM's hostname so responses can be visually distinguished
echo "<h1>Hello from $(hostname)</h1>" | sudo tee /var/www/html/index.html

# Local sanity check on the VM itself
curl localhost
```

## Load Balancer Distribution Testing (run from local machine)

```bash
# Single request to the LB's public IP
curl http://<LB_PUBLIC_IP>

# Repeated requests to observe traffic distribution across the backend pool
for i in {1..10}; do curl -s http://<LB_PUBLIC_IP>; echo; done
```

## Health Probe Failover Test

```bash
# On vm-web-1 (via SSH, port 50001) — simulate a failure
sudo systemctl stop nginx

# From the local machine, re-run the distribution test —
# traffic should shift 100% to vm-web-2

# Restore the service once the test is confirmed
sudo systemctl start nginx
```