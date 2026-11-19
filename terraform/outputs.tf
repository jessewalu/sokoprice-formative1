# -----------------------------------------------------------------------------
# Outputs: the details you, Ansible and the deployment pipeline need after
# `terraform apply`. Nothing here is secret (the database password stays in
# Secrets Manager). Show them with `terraform output`.
# -----------------------------------------------------------------------------

locals {
  app_scheme = var.certificate_arn == "" ? "http" : "https"
  app_url    = "${local.app_scheme}://${module.loadbalancer.dns_name}"

  # Used by SSH and Ansible to reach the private server through the bastion.
  proxy_command = "ssh -i ~/.ssh/sokoprice -o StrictHostKeyChecking=accept-new -W %h:%p -q ${module.compute.ssh_user}@${module.compute.bastion_public_ip}"
}

# ------------------------------- Network -------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (load balancer, bastion host, NAT gateway)."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (application server, database)."
  value       = module.network.private_subnet_ids
}

output "nat_gateway_public_ip" {
  description = "Public IP address that outbound traffic from the private subnets uses."
  value       = module.network.nat_gateway_public_ip
}

# ------------------------------- Application ---------------------------------

output "app_url" {
  description = "Public URL of the live application (through the load balancer)."
  value       = local.app_url
}

output "alb_dns_name" {
  description = "DNS name of the load balancer."
  value       = module.loadbalancer.dns_name
}

output "ecr_repository_url" {
  description = "URL of the private container registry repository that the pipeline pushes images to."
  value       = module.registry.repository_url
}

# -------------------------------- Servers ------------------------------------

output "bastion_public_ip" {
  description = "Public (Elastic) IP address of the bastion host."
  value       = module.compute.bastion_public_ip
}

output "bastion_instance_id" {
  description = "ID of the bastion host."
  value       = module.compute.bastion_instance_id
}

output "app_instance_id" {
  description = "ID of the application server."
  value       = module.compute.app_instance_id
}

output "app_private_ip" {
  description = "Private IP address of the application server (reachable only through the bastion)."
  value       = module.compute.app_private_ip
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group (the deployment pipeline opens SSH on it for the duration of a deployment)."
  value       = module.security.bastion_security_group_id
}

output "ssh_bastion_command" {
  description = "Command to open an SSH session on the bastion host."
  value       = "ssh -i ~/.ssh/sokoprice -p ${var.ssh_port} ${module.compute.ssh_user}@${module.compute.bastion_public_ip}"
}

output "ssh_app_command" {
  description = "Command to open an SSH session on the private application server, jumping through the bastion."
  value       = "ssh -i ~/.ssh/sokoprice -o ProxyCommand=\"${local.proxy_command}\" ${module.compute.ssh_user}@${module.compute.app_private_ip}"
}

# -------------------------------- Database -----------------------------------

output "db_endpoint" {
  description = "Host name of the database (reachable only from the application server)."
  value       = module.database.address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the database credentials."
  value       = module.database.secret_arn
}

output "db_password_command" {
  description = "Command that prints the database password (needs AWS permission to read the secret). Used for manual Ansible runs."
  value       = "aws secretsmanager get-secret-value --secret-id ${module.database.secret_arn} --region ${var.aws_region} --query SecretString --output text"
}

# ------------------------------ Observability --------------------------------

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard (CloudWatch console, Dashboards)."
  value       = module.monitoring.dashboard_name
}

output "app_log_group_name" {
  description = "CloudWatch log group that receives the application's container logs."
  value       = module.monitoring.app_log_group_name
}

output "alerts_topic_arn" {
  description = "SNS topic that the alarms notify."
  value       = module.monitoring.alerts_topic_arn
}

# ---------------------------------- CI/CD ------------------------------------

output "github_actions_role_arn" {
  description = "ARN of the IAM role that the GitHub Actions deployment workflow assumes through OIDC."
  value       = module.cicd.role_arn
}

output "github_actions_variables" {
  description = "Non-secret values the deployment workflow needs. Store each one as a GitHub repository VARIABLE (Settings, Secrets and variables, Actions, Variables), or use github_cli_commands."

  value = {
    AWS_REGION         = var.aws_region
    AWS_ROLE_ARN       = module.cicd.role_arn
    ECR_REPOSITORY_URL = module.registry.repository_url
    BASTION_HOST       = module.compute.bastion_public_ip
    BASTION_SG_ID      = module.security.bastion_security_group_id
    APP_PRIVATE_IP     = module.compute.app_private_ip
    DB_HOST            = module.database.address
    DB_NAME            = module.database.db_name
    DB_USER            = module.database.username
    DB_SECRET_ARN      = module.database.secret_arn
    APP_URL            = local.app_url
    APP_LOG_GROUP      = module.monitoring.app_log_group_name
  }
}

output "github_cli_commands" {
  description = "The same variables as ready-to-run GitHub CLI commands. Run them once: terraform output -raw github_cli_commands | bash"

  value = <<-EOT
    gh variable set AWS_REGION --repo ${var.github_repository} --body "${var.aws_region}"
    gh variable set AWS_ROLE_ARN --repo ${var.github_repository} --body "${module.cicd.role_arn}"
    gh variable set ECR_REPOSITORY_URL --repo ${var.github_repository} --body "${module.registry.repository_url}"
    gh variable set BASTION_HOST --repo ${var.github_repository} --body "${module.compute.bastion_public_ip}"
    gh variable set BASTION_SG_ID --repo ${var.github_repository} --body "${module.security.bastion_security_group_id}"
    gh variable set APP_PRIVATE_IP --repo ${var.github_repository} --body "${module.compute.app_private_ip}"
    gh variable set DB_HOST --repo ${var.github_repository} --body "${module.database.address}"
    gh variable set DB_NAME --repo ${var.github_repository} --body "${module.database.db_name}"
    gh variable set DB_USER --repo ${var.github_repository} --body "${module.database.username}"
    gh variable set DB_SECRET_ARN --repo ${var.github_repository} --body "${module.database.secret_arn}"
    gh variable set APP_URL --repo ${var.github_repository} --body "${local.app_url}"
    gh variable set APP_LOG_GROUP --repo ${var.github_repository} --body "${module.monitoring.app_log_group_name}"
  EOT
}

# ---------------------------------- Ansible ----------------------------------

output "ansible_inventory" {
  description = "Ready-made static Ansible inventory for manual runs. Save it with: terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini"

  value = <<-EOT
    [bastion]
    ${local.name_prefix}-bastion ansible_host=${module.compute.bastion_public_ip}

    [app]
    ${local.name_prefix}-app ansible_host=${module.compute.app_private_ip}

    [sokoprice:children]
    app

    [all:vars]
    ansible_user=${module.compute.ssh_user}
    ansible_port=${var.ssh_port}
    ansible_python_interpreter=/usr/bin/python3
    ansible_ssh_private_key_file=~/.ssh/sokoprice

    # The application server has no public address: Ansible reaches it through the
    # bastion host (see ansible/group_vars/app.yml).
    [app:vars]
    app_db_host=${module.database.address}
    app_db_name=${module.database.db_name}
    app_db_user=${module.database.username}
    app_log_group=${module.monitoring.app_log_group_name}
    app_log_region=${var.aws_region}
    app_public_port=${var.app_port}
  EOT
}
