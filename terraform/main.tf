# -----------------------------------------------------------------------------
# SokoPrice infrastructure (root module)
#
#   network       VPC, public + private subnets, internet and NAT gateways, flow logs
#   security      one security group per tier (load balancer, bastion, app, database)
#   monitoring    encrypted log group, alarms, alert topic, dashboard
#   registry      private container registry (ECR)
#   compute       bastion host (public subnet) + application server (private subnet)
#   database      managed PostgreSQL (RDS) in the private subnets
#   loadbalancer  public Application Load Balancer in front of the server
#   cicd          IAM role that lets GitHub Actions deploy through OIDC (no keys)
#
# Nothing environment-specific is hard-coded here: region, CIDR ranges,
# instance sizes, admin IP addresses and the SSH key all come from variables.
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
  private_subnet_cidrs    = var.private_subnet_cidrs
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
  alb_allowed_cidrs = var.alb_allowed_cidrs
  enable_https      = var.certificate_arn != ""
}

module "registry" {
  source = "./modules/registry"

  repository_name = "${var.project_name}/app"
  force_delete    = var.ecr_force_delete
}

module "compute" {
  source = "./modules/compute"

  name_prefix                = local.name_prefix
  bastion_subnet_id          = module.network.public_subnet_ids[0]
  app_subnet_id              = module.network.private_subnet_ids[0]
  bastion_security_group_id  = module.security.bastion_security_group_id
  app_security_group_id      = module.security.app_security_group_id
  app_log_group_arn          = module.monitoring.app_log_group_arn
  bastion_instance_type      = var.bastion_instance_type
  instance_type              = var.instance_type
  root_volume_size           = var.root_volume_size
  ssh_public_key             = var.ssh_public_key
  ami_owner_id               = var.ami_owner_id
  ami_name_pattern           = var.ami_name_pattern
  enable_detailed_monitoring = var.enable_detailed_monitoring

  # The bastion's Elastic IP and the private server's package downloads need the
  # internet and NAT gateways to exist first.
  depends_on = [module.network]
}

module "database" {
  source = "./modules/database"

  name_prefix                 = local.name_prefix
  private_subnet_ids          = module.network.private_subnet_ids
  security_group_id           = module.security.db_security_group_id
  db_name                     = var.db_name
  db_username                 = var.db_username
  engine_version              = var.db_engine_version
  parameter_group_family      = var.db_parameter_group_family
  instance_class              = var.db_instance_class
  allocated_storage           = var.db_allocated_storage
  multi_az                    = var.db_multi_az
  backup_retention_days       = var.db_backup_retention_days
  deletion_protection         = var.db_deletion_protection
  skip_final_snapshot         = var.db_skip_final_snapshot
  secret_recovery_window_days = var.db_secret_recovery_window_days
}

module "loadbalancer" {
  source = "./modules/loadbalancer"

  name_prefix         = local.name_prefix
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  security_group_id   = module.security.alb_security_group_id
  target_instance_id  = module.compute.app_instance_id
  app_port            = var.app_port
  health_check_path   = var.health_check_path
  certificate_arn     = var.certificate_arn
  deletion_protection = var.alb_deletion_protection
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix             = local.name_prefix
  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  alert_email             = var.alert_email
  log_retention_days      = var.log_retention_days
  app_instance_id         = module.compute.app_instance_id
  alb_arn_suffix          = module.loadbalancer.arn_suffix
  target_group_arn_suffix = module.loadbalancer.target_group_arn_suffix
  db_identifier           = module.database.identifier
}

module "cicd" {
  source = "./modules/cicd"

  name_prefix               = local.name_prefix
  aws_region                = var.aws_region
  github_repository         = var.github_repository
  github_branch             = var.github_branch
  create_oidc_provider      = var.create_github_oidc_provider
  ecr_repository_arn        = module.registry.repository_arn
  db_secret_arn             = module.database.secret_arn
  db_secret_kms_key_arn     = module.database.secret_kms_key_arn
  bastion_security_group_id = module.security.bastion_security_group_id
}
