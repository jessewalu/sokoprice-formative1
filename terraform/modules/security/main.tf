# -----------------------------------------------------------------------------
# Security module: one security group (virtual firewall) per tier.
#
#   alb      Internet            -> load balancer (HTTP, and HTTPS when enabled)
#   bastion  Admin addresses     -> SSH jump host
#   app      load balancer       -> application port
#            bastion             -> SSH
#   db       application server  -> PostgreSQL
#
# Traffic is allowed between tiers by referencing the other security group, not
# by IP address, so the rules keep working when addresses change. Every rule is
# its own resource with a description so each one can be reviewed on its own.
# Anything not listed is denied (default deny).
# -----------------------------------------------------------------------------

# ------------------------------ Load balancer --------------------------------

resource "aws_security_group" "alb" {
  #checkov:skip=CKV2_AWS_5:False positive. The group is attached to the load balancer in the loadbalancer module through module.security.alb_security_group_id, and Checkov cannot follow a reference across a module boundary.
  name_prefix = "${var.name_prefix}-alb-"
  description = "SokoPrice load balancer: web traffic from the internet, forwarded to the application tier"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:The API serves farmers and the USSD gateway from anywhere, so the web port is public by design. Compensating controls are in SECURITY.md (only the load balancer is public, the servers are private, TLS is supported through certificate_arn).
  for_each = toset(var.alb_allowed_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = var.enable_https ? toset(var.alb_allowed_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests to the application servers"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# ------------------------------ Bastion host ---------------------------------

resource "aws_security_group" "bastion" {
  #checkov:skip=CKV2_AWS_5:False positive. The group is attached to the bastion instance in the compute module through module.security.bastion_security_group_id, and Checkov cannot follow a reference across a module boundary.
  name_prefix = "${var.name_prefix}-bastion-"
  description = "SokoPrice bastion host: SSH from administrator addresses only"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = toset(var.admin_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "SSH from administrator address ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = var.ssh_port
  to_port           = var.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_app_ssh" {
  security_group_id            = aws_security_group.bastion.id
  description                  = "SSH onwards to the application server"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.ssh_port
  to_port                      = var.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "bastion_https" {
  security_group_id = aws_security_group.bastion.id
  description       = "HTTPS to the internet: operating system updates and AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "bastion_http" {
  security_group_id = aws_security_group.bastion.id
  description       = "HTTP to the internet: operating system package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "bastion_dns_udp" {
  security_group_id = aws_security_group.bastion.id
  description       = "DNS (UDP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "bastion_dns_tcp" {
  security_group_id = aws_security_group.bastion.id
  description       = "DNS (TCP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
}

# ---------------------------- Application server -----------------------------

resource "aws_security_group" "app" {
  #checkov:skip=CKV2_AWS_5:False positive. The group is attached to the application instance in the compute module through module.security.app_security_group_id, and Checkov cannot follow a reference across a module boundary.
  name_prefix = "${var.name_prefix}-app-"
  description = "SokoPrice application server: web traffic from the load balancer, SSH from the bastion, outbound to the database"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-app-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  #checkov:skip=CKV_AWS_260:False positive. The source is the load balancer's security group (referenced_security_group_id), not 0.0.0.0/0. The rule has no CIDR at all.
  security_group_id            = aws_security_group.app.id
  description                  = "Application port from the load balancer only"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
  #checkov:skip=CKV_AWS_24:False positive. The source is the bastion host's security group (referenced_security_group_id), not 0.0.0.0/0. The rule has no CIDR at all.
  security_group_id            = aws_security_group.app.id
  description                  = "SSH from the bastion host only"
  referenced_security_group_id = aws_security_group.bastion.id
  ip_protocol                  = "tcp"
  from_port                    = var.ssh_port
  to_port                      = var.ssh_port
}

resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app.id
  description                  = "PostgreSQL to the database"
  referenced_security_group_id = aws_security_group.db.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}

resource "aws_vpc_security_group_egress_rule" "app_https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS to the internet through the NAT gateway: container registry, GitHub, AWS APIs"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "app_http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP to the internet through the NAT gateway: operating system package repositories"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "app_dns_udp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS (UDP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
}

resource "aws_vpc_security_group_egress_rule" "app_dns_tcp" {
  security_group_id = aws_security_group.app.id
  description       = "DNS (TCP) to the VPC resolver only"
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
}

# -------------------------------- Database -----------------------------------

resource "aws_security_group" "db" {
  #checkov:skip=CKV2_AWS_5:False positive. The group is attached to the database in the database module through module.security.db_security_group_id, and Checkov cannot follow a reference across a module boundary.
  name_prefix = "${var.name_prefix}-db-"
  description = "SokoPrice database: PostgreSQL from the application server only, no outbound traffic"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name_prefix}-db-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  description                  = "PostgreSQL from the application server only"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.db_port
  to_port                      = var.db_port
}
