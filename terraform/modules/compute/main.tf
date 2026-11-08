# -----------------------------------------------------------------------------
# Compute module: the application server.
#
#   * Latest official Ubuntu 24.04 LTS image from the pinned publisher.
#   * Encrypted gp3 root volume, IMDSv2 required (blocks SSRF credential theft).
#   * IAM role with only AWS Systems Manager access, so the server can also be
#     reached with Session Manager without opening any extra port.
#   * Elastic IP, so the address does not change when the server restarts.
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

resource "aws_iam_role" "instance" {
  name_prefix        = "${var.name_prefix}-ec2-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name_prefix}-"
  role        = aws_iam_role.instance.name
}

# ------------------------------ Instance -------------------------------------

resource "aws_instance" "this" {
  #checkov:skip=CKV_AWS_126:Detailed (1-minute) monitoring costs extra, so it is a variable that is off for dev and on for prod (see environments/prod.tfvars.example).
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = aws_key_pair.this.key_name
  iam_instance_profile        = aws_iam_instance_profile.this.name
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
  }

  # A newer machine image must not force the server to be rebuilt. Patches are
  # applied in place by Ansible (unattended upgrades).
  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "this" {
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-eip"
  }
}

resource "aws_eip_association" "this" {
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this.id
}
