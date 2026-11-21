variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "project_name" {
  description = "Project name, used in the log group name."
  type        = string
}

variable "environment" {
  description = "Environment name, used in the log group name."
  type        = string
}

variable "aws_region" {
  description = "AWS region. Needed for the KMS key policy and the dashboard."
  type        = string
}

variable "alert_email" {
  description = "E-mail address that receives alarm notifications. Leave empty to create the topic without a subscriber."
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "Days to keep application logs. Must be a value CloudWatch Logs supports."
  type        = number
  default     = 365
}

variable "app_instance_id" {
  description = "ID of the application server being monitored."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the load balancer (CloudWatch dimension)."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the target group (CloudWatch dimension)."
  type        = string
}

variable "db_identifier" {
  description = "Identifier of the database instance being monitored."
  type        = string
}
