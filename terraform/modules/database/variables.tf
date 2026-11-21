variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for the database (at least two, in different availability zones)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "The database subnet group needs at least two private subnets in different availability zones."
  }
}

variable "security_group_id" {
  description = "ID of the security group attached to the database."
  type        = string
}

variable "db_name" {
  description = "Name of the initial database."
  type        = string
  default     = "sokoprice"
}

variable "db_username" {
  description = "Master user name."
  type        = string
  default     = "sokoprice"
}

variable "engine_version" {
  description = "PostgreSQL major version (AWS picks the current minor version and upgrades it automatically)."
  type        = string
  default     = "16"
}

variable "parameter_group_family" {
  description = "Parameter group family. It must match the major version in engine_version."
  type        = string
  default     = "postgres16"
}

variable "instance_class" {
  description = "Database instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GiB."
  type        = number
  default     = 20
}

variable "multi_az" {
  description = "Keep a standby copy in a second availability zone (doubles the cost, recommended for prod)."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Days to keep automated backups (1 to 35)."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Refuse to delete the database (turn on for prod)."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot when the database is destroyed (true is convenient for a lab, false for prod)."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply database changes immediately instead of in the next maintenance window."
  type        = bool
  default     = true
}

variable "secret_recovery_window_days" {
  description = "Days the credentials secret can be recovered after deletion. 0 deletes it immediately, which lets terraform destroy and apply be repeated without a name clash."
  type        = number
  default     = 0
}
