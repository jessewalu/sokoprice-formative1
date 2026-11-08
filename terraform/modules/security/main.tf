# -----------------------------------------------------------------------------
# Security module: the firewall (security group) of the application server.
#
#   Inbound  : SSH from the administrator addresses only, the API port.
#   Outbound : HTTPS and HTTP (package and image downloads) and DNS to the VPC
#              resolver. Everything else is denied (default deny).
#
# Rules are separate resources so each one carries its own description and can
# be reviewed (and changed) on its own.
# -----------------------------------------------------------------------------

resource "aws_security_group" "app" {
  #checkov:skip=CKV2_AWS_5:False positive. The group is attached to the instance in the compute module through module.security.security_group_id, and Checkov cannot follow a reference across a module boundary.
  name_prefix = "${var.name_prefix}-app-"
  description = "SokoPrice application server: SSH from admin IPs, API port, restricted outbound"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------ Inbound --------------------------------------

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.app.id
  description       = "SSH from administrator address ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  #checkov:skip=CKV_AWS_260:The API serves farmers and the USSD gateway from anywhere, so the web port is public by design. Compensating controls are documented in SECURITY.md (host firewall, no secrets served, TLS planned).
  for_each = toset(var.app_allowed_cidrs)

  security_group_id = aws_security_group.app.id
  description       = "SokoPrice API from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
}

# ------------------------------ Outbound -------------------------------------

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS to the internet: container registries, GitHub, AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP to the internet: operating system package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS (UDP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS (TCP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
}
