# AWS VPN + Private EC2 (Terraform)

## Goal

Private EC2 web app accessible **only via VPN**.

## What this stack creates

- VPC with DNS support, one public and one private subnet (single AZ)
- Internet gateway, NAT gateway (private subnet can install packages)
- EC2 in the **private subnet** (no public IP), Amazon Linux 2023 + Nginx
- Security group on EC2: TCP **80** from the Client VPN client CIDR and from the VPC CIDR (so forwarded traffic is allowed)
- **AWS Client VPN** (mutual TLS): endpoint, subnet association (adds VPC CIDR route automatically), authorization to the VPC CIDR
- Demo CA + server + client certificates in Terraform (`tls` + imported into **ACM**); writes **`client.ovpn`** locally (gitignored)

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.3`
- AWS credentials with permission to create VPC, EC2, ACM, Client VPN, etc.
- Client: [AWS VPN Client](https://aws.amazon.com/vpn/client-vpn-download/) or OpenVPN-compatible client

## Deploy

```bash
cd /path/to/AWS_VPN
terraform init
terraform apply
```

After apply, Terraform prints outputs. You can show them anytime from the project directory:

```bash
# All outputs (private IP, VPN URL, profile path, endpoint DNS name)
terraform output

# Path to the generated OpenVPN profile (absolute path on disk)
terraform output client_vpn_config_path

# Same path, no quotes — useful for copy/paste or scripts
terraform output -raw client_vpn_config_path

# EC2 private IP and ready-to-open URL (after you are connected to VPN)
terraform output ec2_private_ip
terraform output vpn_test_url

# Client VPN endpoint hostname (also inside client.ovpn)
terraform output client_vpn_dns_name
```

The profile file is **`client.ovpn`** in this directory (see `client_vpn_config_path`). It is created when `local_file.ovpn` runs during apply and is listed in `.gitignore` because it contains a private key.

## Connect

1. Run `terraform output -raw client_vpn_config_path` (or open `client.ovpn` in this repo folder after apply).
2. Import that **`client.ovpn`** file into [AWS VPN Client](https://aws.amazon.com/vpn/client-vpn-download/) or another OpenVPN-compatible app (e.g. **File → Manage Profiles → Add Profile** in AWS VPN Client).
3. Connect to the profile.
4. In a browser, open the URL from `terraform output vpn_test_url` (or `http://$(terraform output -raw ec2_private_ip)`). Use **`http://`**, not `https://` (Nginx is only on port 80).

5. After changing Terraform, run **`terraform apply`** again, then **re-import** or replace the profile in AWS VPN Client so it picks up an updated **`client.ovpn`** (for example when MTU lines are added).

## Test

- **Without VPN** — no route to the private IP from the public internet; the instance has no public IP.
- **With VPN** — `http://<private-ip>` should show the Nginx page.

<img src=imgs/not-connected-cli.png>

---

<img src=imgs/connected-cli.png>

---

<img src=imgs/connected-browser.png>

## Destroy

```bash
terraform destroy
```
