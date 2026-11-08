variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "aws_region" {
  description = "AWS region. Needed to build the KMS key policy for the log service."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "IPv4 CIDR blocks of the public subnets, one per availability zone."
  type        = list(string)
}

variable "enable_flow_logs" {
  description = "Create the encrypted CloudWatch log group, IAM role and VPC flow log."
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "Days to keep VPC flow logs."
  type        = number
  default     = 365
}
