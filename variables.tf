variable "aws_region" {
  type        = string
  description = "Region for VPC, EC2, Client VPN, and ACM."
}

variable "project_name" {
  type        = string
  description = "Prefix for resource Name tags."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC IPv4 CIDR. Must not overlap client_vpn_cidr."
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet (NAT + Client VPN association)."
}

variable "private_subnet_cidr" {
  type        = string
  description = "Private subnet for EC2."
}

variable "client_vpn_cidr" {
  type        = string
  description = "CIDR from which connected VPN clients receive addresses. Must not overlap vpc_cidr."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for Nginx host."
}
