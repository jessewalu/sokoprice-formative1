# -----------------------------------------------------------------------------
# SokoPrice infrastructure (root module)
#
#   network  -> VPC, public subnets, internet gateway, routes, flow logs
#   security -> security group (the firewall) for the application server
#   compute  -> EC2 instance, key pair, IAM role, Elastic IP
#
# Nothing environment-specific is hard-coded here: region, CIDR ranges,
# instance size, admin IP addresses and the SSH key all come from variables.
# -----------------------------------------------------------------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.extra_tags,
  )
}

module "network" {
  source = "./modules/network"

  name_prefix             = local.name_prefix
  aws_region              = var.aws_region
  vpc_cidr                = var.vpc_cidr
  public_subnet_cidrs     = var.public_subnet_cidrs
  enable_flow_logs        = var.enable_flow_logs
  flow_log_retention_days = var.flow_log_retention_days
}

module "security" {
  source = "./modules/security"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  vpc_cidr          = var.vpc_cidr
  ssh_port          = var.ssh_port
  admin_cidrs       = var.admin_cidrs
  app_port          = var.app_port
  app_allowed_cidrs = var.app_allowed_cidrs
}

module "compute" {
  source = "./modules/compute"

  name_prefix                = local.name_prefix
  subnet_id                  = module.network.public_subnet_ids[0]
  security_group_ids         = [module.security.security_group_id]
  instance_type              = var.instance_type
  root_volume_size           = var.root_volume_size
  ssh_public_key             = var.ssh_public_key
  ami_owner_id               = var.ami_owner_id
  ami_name_pattern           = var.ami_name_pattern
  enable_detailed_monitoring = var.enable_detailed_monitoring

  # The Elastic IP needs the internet gateway to exist first.
  depends_on = [module.network]
}
