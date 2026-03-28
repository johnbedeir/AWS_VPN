data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }
}

resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "HTTP from Client VPN pool and VPC (covers how CVPN forwards into the VPC)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from VPN clients and from inside the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.client_vpn_cidr, var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    dnf install -y nginx
    systemctl enable --now nginx
    echo '<h1>Private EC2 (VPN only)</h1><p>Reachable only from Client VPN.</p>' > /usr/share/nginx/html/index.html
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-web"
  }
}
