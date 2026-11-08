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
  description = "IPv4 CIDR blocks of the public subnets, one per availability zone. The server runs in the first one."
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 1 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "public_subnet_cidrs needs at least one valid IPv4 CIDR block."
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
  description = "IPv4 CIDR blocks allowed to connect over SSH, for example [\"203.0.113.25/32\"] (your own address). Required. 0.0.0.0/0 is rejected."
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

variable "app_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the API. The default is public because farmers and USSD gateways call it from anywhere; restrict it for private environments."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.app_allowed_cidrs : can(cidrnetmask(cidr))])
    error_message = "Every app_allowed_cidrs entry must be a valid IPv4 CIDR block."
  }
}

# ----------------------------- Compute ---------------------------------------

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the encrypted root volume in GiB."
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
