# -----------------------------------------------------------------------------
# Input variables. Values for these live in a tfvars file (see
# terraform.tfvars.example and environments/*.tfvars.example), never in code.
# Variables without a default are REQUIRED and have no secret value baked in.
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into. No default on purpose: choose the region closest to your users and set it in your tfvars file."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-[0-9]$", var.aws_region))
    error_message = "aws_region must look like an AWS region code, for example eu-west-1."
  }
}

variable "project_name" {
  description = "Short project name used in resource names and tags."
  type        = string
  default     = "sokoprice"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 characters: lowercase letters, digits and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Used in names and tags."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "extra_tags" {
  description = "Additional tags added to every resource (for example an owner or cost centre)."
  type        = map(string)
  default     = {}
}

# ----------------------------- Network ---------------------------------------

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  type        = string
  default     = "10.20.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block such as 10.20.0.0/16."
  }
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks of the public subnets, one per availability zone. The load balancer needs two; the bastion host runs in the first."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "public_subnet_cidrs needs at least two valid IPv4 CIDR blocks (the load balancer needs two availability zones)."
  }
}

variable "private_subnet_cidrs" {
  description = "IPv4 CIDR blocks of the private subnets, one per availability zone. The application server runs in the first; the database needs two."
  type        = list(string)
  default     = ["10.20.11.0/24", "10.20.12.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "private_subnet_cidrs needs at least two valid IPv4 CIDR blocks (the database subnet group needs two availability zones)."
  }
}

variable "enable_flow_logs" {
  description = "Record VPC flow logs (network traffic metadata) in an encrypted CloudWatch log group."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Days to keep VPC flow logs. Must be a value CloudWatch Logs supports."
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_log_retention_days)
    error_message = "flow_log_retention_days must be a retention period supported by CloudWatch Logs (for example 30, 90 or 365)."
  }
}

# ----------------------------- Firewall --------------------------------------

variable "ssh_port" {
  description = "TCP port of the SSH service. Must match the Ansible variable security_ssh_port."
  type        = number
  default     = 22

  validation {
    condition     = var.ssh_port >= 1 && var.ssh_port <= 65535
    error_message = "ssh_port must be between 1 and 65535."
  }
}

variable "admin_cidrs" {
  description = "IPv4 CIDR blocks allowed to connect to the bastion host over SSH, for example [\"203.0.113.25/32\"] (your own address). Required. 0.0.0.0/0 is rejected."
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0
    error_message = "admin_cidrs needs at least one CIDR block, otherwise nobody can administer the server."
  }

  validation {
    condition     = alltrue([for cidr in var.admin_cidrs : can(cidrnetmask(cidr)) && cidr != "0.0.0.0/0"])
    error_message = "Every admin_cidrs entry must be a valid IPv4 CIDR block and must not be 0.0.0.0/0 (SSH must never be open to the whole internet)."
  }
}

variable "app_port" {
  description = "Public TCP port on which the SokoPrice API is served."
  type        = number
  default     = 80

  validation {
    condition     = var.app_port >= 1 && var.app_port <= 65535
    error_message = "app_port must be between 1 and 65535."
  }
}

variable "alb_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the load balancer. The default is public because farmers and USSD gateways call the API from anywhere; restrict it for private environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.alb_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every alb_allowed_cidrs entry must be a valid IPv4 CIDR block."
  }
}

variable "certificate_arn" {
  description = "ARN of an AWS Certificate Manager certificate for your domain name. When set, the load balancer serves HTTPS and redirects HTTP to HTTPS. Leave empty to serve plain HTTP."
  type        = string
  default     = ""

  validation {
    condition     = var.certificate_arn == "" || can(regex("^arn:aws[a-z-]*:acm:", var.certificate_arn))
    error_message = "certificate_arn must be empty or an AWS Certificate Manager ARN (arn:aws:acm:...)."
  }
}

# ----------------------------- Compute ---------------------------------------

variable "bastion_instance_type" {
  description = "EC2 instance type of the bastion host. It only forwards SSH, so the smallest size is enough."
  type        = string
  default     = "t3.micro"
}

variable "instance_type" {
  description = "EC2 instance type of the application server."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the application server's encrypted root volume in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "root_volume_size must be between 8 and 100 GiB."
  }
}

variable "ssh_public_key" {
  description = "Public half of your SSH key pair (the text of your .pub file). This is NOT a secret. Keep the private key on your own computer."
  type        = string

  validation {
    condition     = can(regex("^(ssh-rsa|ssh-ed25519) ", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key starting with ssh-ed25519 or ssh-rsa."
  }
}

variable "ami_owner_id" {
  description = "AWS account ID that publishes the machine image. The default is Canonical, the publisher of the official Ubuntu images. Pinning the publisher stops look-alike images from being used."
  type        = string
  default     = "099720109477"
}

variable "ami_name_pattern" {
  description = "Name pattern of the machine image to use (default: the latest Ubuntu 24.04 LTS image)."
  type        = string
  default     = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
}

variable "enable_detailed_monitoring" {
  description = "Enable 1-minute EC2 metrics. Costs extra, so it is off by default and recommended for prod."
  type        = bool
  default     = false
}

# ----------------------------- Database --------------------------------------

variable "db_name" {
  description = "Name of the PostgreSQL database."
  type        = string
  default     = "sokoprice"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a lowercase letter and contain only lowercase letters, digits and underscores."
  }
}

variable "db_username" {
  description = "Master user name of the database. The password is generated and stored in Secrets Manager, never set here."
  type        = string
  default     = "sokoprice"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,15}$", var.db_username))
    error_message = "db_username must start with a lowercase letter and be at most 16 characters of lowercase letters, digits and underscores."
  }
}

variable "db_engine_version" {
  description = "PostgreSQL major version. AWS selects the current minor version and keeps it patched."
  type        = string
  default     = "16"
}

variable "db_parameter_group_family" {
  description = "Parameter group family. Must match db_engine_version."
  type        = string
  default     = "postgres16"
}

variable "db_instance_class" {
  description = "Database instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Database storage in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 1000
    error_message = "db_allocated_storage must be between 20 and 1000 GiB."
  }
}

variable "db_multi_az" {
  description = "Keep a standby copy of the database in a second availability zone. Doubles the cost; recommended for prod."
  type        = bool
  default     = false
}

variable "db_backup_retention_days" {
  description = "Days to keep automated database backups. Some new AWS accounts (free plan) only allow 1."
  type        = number
  default     = 1

  validation {
    condition     = var.db_backup_retention_days >= 1 && var.db_backup_retention_days <= 35
    error_message = "db_backup_retention_days must be between 1 and 35."
  }
}

variable "db_deletion_protection" {
  description = "Refuse to delete the database. Off by default so a lab can be destroyed; turn on for prod."
  type        = bool
  default     = false
}

variable "db_skip_final_snapshot" {
  description = "Skip the final snapshot when the database is destroyed. True suits a lab; use false for prod."
  type        = bool
  default     = true
}

variable "db_secret_recovery_window_days" {
  description = "Days the database credentials secret can be recovered after deletion. 0 deletes it at once so that destroy and apply can be repeated."
  type        = number
  default     = 0

  validation {
    condition     = var.db_secret_recovery_window_days == 0 || (var.db_secret_recovery_window_days >= 7 && var.db_secret_recovery_window_days <= 30)
    error_message = "db_secret_recovery_window_days must be 0, or between 7 and 30."
  }
}

# --------------------------- Registry and load balancer ----------------------

variable "ecr_force_delete" {
  description = "Allow terraform destroy to delete the container repository even if it still holds images. True suits a lab; use false for prod."
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path the load balancer calls to check that the application is healthy."
  type        = string
  default     = "/health"
}

variable "alb_deletion_protection" {
  description = "Refuse to delete the load balancer. Off by default so a lab can be destroyed; turn on for prod."
  type        = bool
  default     = false
}

# ----------------------------- CI/CD (GitHub) --------------------------------

variable "github_repository" {
  description = "GitHub repository whose deployment workflow may assume the AWS deployment role, as owner/name."
  type        = string
  default     = "jessewalu/sokoprice-formative1"

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name, for example jessewalu/sokoprice-formative1."
  }
}

variable "github_branch" {
  description = "Branch whose workflows may deploy. Workflows on other branches cannot assume the role."
  type        = string
  default     = "main"
}

variable "create_github_oidc_provider" {
  description = "Create the GitHub OIDC identity provider in this AWS account. Set to false if the account already has one (only one is allowed)."
  type        = bool
  default     = true
}

# ----------------------------- Monitoring ------------------------------------

variable "alert_email" {
  description = "E-mail address that receives alarm notifications. AWS sends a confirmation link that must be clicked. Leave empty for no subscriber."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Days to keep the application logs. Must be a value CloudWatch Logs supports."
  type        = number
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.log_retention_days)
    error_message = "log_retention_days must be a retention period supported by CloudWatch Logs (for example 30, 90 or 365)."
  }
}
