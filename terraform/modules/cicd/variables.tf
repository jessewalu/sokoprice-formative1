variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "aws_region" {
  description = "AWS region. Needed to build resource ARNs and the KMS service condition."
  type        = string
}

variable "github_repository" {
  description = "GitHub repository allowed to deploy, in the form owner/name."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must look like owner/name, for example jessewalu/sokoprice-formative1."
  }
}

variable "github_branch" {
  description = "Branch whose workflows may deploy. Workflows on any other branch cannot assume the role."
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC identity provider. Set to false if your AWS account already has one (an account can hold only one)."
  type        = bool
  default     = true
}

variable "ecr_repository_arn" {
  description = "ARN of the container repository the role may push to."
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the database credentials secret the role may read."
  type        = string
}

variable "db_secret_kms_key_arn" {
  description = "ARN of the KMS key that encrypts the database credentials secret."
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the bastion security group on which the role may open and close SSH access."
  type        = string
}
