output "ec2_private_ip" {
  description = "Open http://<this> in a browser while connected to VPN."
  value       = aws_instance.web.private_ip
}

output "client_vpn_dns_name" {
  description = "Client VPN endpoint DNS name (also embedded in client.ovpn)."
  value       = aws_ec2_client_vpn_endpoint.main.dns_name
}

output "client_vpn_config_path" {
  description = "OpenVPN profile path (mutual TLS). Import into AWS VPN Client or OpenVPN."
  value       = local_file.ovpn.filename
}

output "vpn_test_url" {
  description = "URL to hit after connecting with AWS-provided or OpenVPN client."
  value       = "http://${aws_instance.web.private_ip}"
}
