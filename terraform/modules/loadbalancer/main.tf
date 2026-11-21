# -----------------------------------------------------------------------------
# Load balancer module: the public entry point of the application.
#
#   Internet -> Application Load Balancer (public subnets)
#            -> target group, health check on /health
#            -> application server (private subnet)
#
# Without certificate_arn the listener serves HTTP on port 80. With a
# certificate (issued by AWS Certificate Manager for your own domain name) it
# serves HTTPS on port 443 and redirects HTTP to HTTPS.
# -----------------------------------------------------------------------------

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91:Access logs need an S3 bucket with a regional load-balancer log-delivery policy. Request metrics, health checks and alarms are in CloudWatch instead; access logging is listed as future work in SECURITY.md.
  #checkov:skip=CKV_AWS_150:Deletion protection is a variable that is off for dev so that terraform destroy can remove the lab environment, and on for prod (see environments/prod.tfvars.example).
  #checkov:skip=CKV2_AWS_20:A redirect to HTTPS exists (the http_redirect listener) and is used as soon as certificate_arn is set. Without a domain name there is no certificate, so the HTTP listener forwards instead. Accepted risk in SECURITY.md.
  #checkov:skip=CKV2_AWS_28:A web application firewall costs extra and is out of scope for this project. It is listed as future work in SECURITY.md.
  name                       = "${var.name_prefix}-alb"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [var.security_group_id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
  idle_timeout               = 60

  tags = {
    Name = "${var.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378:Traffic between the load balancer and the server stays inside the private VPC subnets and is limited by security groups. TLS ends at the load balancer; end-to-end encryption to the server is listed as future work in SECURITY.md.
  name_prefix = "app-"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.name_prefix}-app-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "app" {
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = var.target_instance_id
  port             = var.app_port
}

# --------------------------------- Listeners ---------------------------------

# HTTP only (no certificate configured).
resource "aws_lb_listener" "http_forward" {
  #checkov:skip=CKV_AWS_2:No certificate is configured, which needs a domain name that this project does not have. Set certificate_arn to serve HTTPS and redirect HTTP (see the https listener below). Documented as an accepted risk in SECURITY.md.
  #checkov:skip=CKV_AWS_103:Same reason as CKV_AWS_2: the TLS policy applies to the HTTPS listener, which exists once certificate_arn is set.
  count = var.certificate_arn == "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# With a certificate: HTTP redirects to HTTPS.
resource "aws_lb_listener" "http_redirect" {
  count = var.certificate_arn == "" ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn == "" ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
