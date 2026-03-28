resource "aws_security_group" "client_vpn" {
  name_prefix = "${var.project_name}-cvpn-"
  description = "Inbound to Client VPN endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Client VPN (UDP)"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Client VPN (TCP)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-client-vpn-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  description            = "${var.project_name} mutual TLS"
  server_certificate_arn = aws_acm_certificate.vpn_server.arn
  client_cidr_block      = var.client_vpn_cidr
  vpc_id                 = aws_vpc.main.id
  security_group_ids     = [aws_security_group.client_vpn.id]
  split_tunnel           = true
  transport_protocol     = "udp"
  vpn_port               = 443

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = aws_acm_certificate.vpn_ca.arn
  }

  connection_log_options {
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-endpoint"
  }
}

resource "aws_ec2_client_vpn_network_association" "main" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = aws_subnet.public.id
}

resource "aws_ec2_client_vpn_authorization_rule" "vpc" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  target_network_cidr    = aws_vpc.main.cidr_block
  authorize_all_groups   = true

  depends_on = [aws_ec2_client_vpn_network_association.main]
}

# No aws_ec2_client_vpn_route for the VPC CIDR: associating the subnet creates that route automatically (an explicit route duplicates it).

locals {
  ovpn = <<-EOT
client
dev tun
proto udp
remote ${aws_ec2_client_vpn_endpoint.main.dns_name} 443
remote-random-hostname
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
verb 3
auth-nocache
reneg-sec 0
# Avoid hangs / endless loading when large TLS packets fragment over the tunnel
tun-mtu 1400
mssfix 1360

<ca>
${trimspace(tls_self_signed_cert.ca.cert_pem)}
</ca>

<cert>
${trimspace(tls_locally_signed_cert.client.cert_pem)}
</cert>

<key>
${trimspace(tls_private_key.client.private_key_pem)}
</key>
EOT
}

resource "local_file" "ovpn" {
  filename        = "${path.module}/client.ovpn"
  content         = local.ovpn
  file_permission = "0600"
}
