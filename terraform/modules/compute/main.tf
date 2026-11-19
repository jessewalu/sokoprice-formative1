# -----------------------------------------------------------------------------
# Compute module: the bastion host and the application server.
#
#   Bastion host        Small server in a PUBLIC subnet with an Elastic IP. It is
#                       the only way to reach the private network over SSH.
#   Application server  Server in a PRIVATE subnet: no public IP, reachable only
#                       from the load balancer (web) and the bastion (SSH).
#
# Both: latest official Ubuntu 24.04 LTS image from the pinned publisher,
# encrypted gp3 root volume, IMDSv2 required (blocks SSRF credential theft), and
# an IAM role with only what that server needs.
# -----------------------------------------------------------------------------

data "aws_partition" "current" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = [var.ami_owner_id]

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ------------------------------ Access ---------------------------------------

resource "aws_key_pair" "this" {
  key_name_prefix = "${var.name_prefix}-"
  public_key      = var.ssh_public_key
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ------------------------------ Bastion role ---------------------------------

resource "aws_iam_role" "bastion" {
  name_prefix        = "${var.name_prefix}-bastion-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "${var.name_prefix}-bastion-"
  role        = aws_iam_role.bastion.name
}

# --------------------------- Application server role ------------------------

resource "aws_iam_role" "app" {
  name_prefix        = "${var.name_prefix}-app-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "app_ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# The Docker log driver on the server ships container logs to CloudWatch Logs.
# It may write to this one log group and nothing else.
data "aws_iam_policy_document" "app_logs" {
  statement {
    sid       = "WriteContainerLogsToThisLogGroupOnly"
    effect    = "Allow"
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${var.app_log_group_arn}:*"]
  }
}

resource "aws_iam_role_policy" "app_logs" {
  name_prefix = "ship-container-logs-"
  role        = aws_iam_role.app.id
  policy      = data.aws_iam_policy_document.app_logs.json
}

resource "aws_iam_instance_profile" "app" {
  name_prefix = "${var.name_prefix}-app-"
  role        = aws_iam_role.app.name
}

# ------------------------------ Bastion host ---------------------------------

resource "aws_instance" "bastion" {
  #checkov:skip=CKV_AWS_126:Detailed (1-minute) monitoring costs extra, so it is a variable that is off for dev and on for prod (see environments/prod.tfvars.example).
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.bastion_subnet_id
  vpc_security_group_ids      = [var.bastion_security_group_id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = false
  monitoring                  = var.enable_detailed_monitoring
  ebs_optimized               = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 10
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-bastion"
    Role = "bastion"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# The Elastic IP keeps the bastion address stable when the server restarts.
resource "aws_eip" "bastion" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-bastion-eip"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

# --------------------------- Application server ------------------------------

resource "aws_instance" "app" {
  #checkov:skip=CKV_AWS_126:Detailed (1-minute) monitoring costs extra, so it is a variable that is off for dev and on for prod (see environments/prod.tfvars.example).
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.app_subnet_id
  vpc_security_group_ids      = [var.app_security_group_id]
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = false
  monitoring                  = var.enable_detailed_monitoring
  ebs_optimized               = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.name_prefix}-app"
    Role = "app"
  }

  # A newer machine image must not force the server to be rebuilt. Patches are
  # applied in place by Ansible (unattended upgrades).
  lifecycle {
    ignore_changes = [ami]
  }
}
