variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC."
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets (at least two, in different availability zones)."
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "A load balancer needs at least two public subnets in different availability zones."
  }
}

variable "security_group_id" {
  description = "ID of the load balancer security group."
  type        = string
}

variable "target_instance_id" {
  description = "ID of the application server that receives the traffic."
  type        = string
}

variable "app_port" {
  description = "Port the application listens on."
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path the load balancer calls to decide whether the server is healthy."
  type        = string
  default     = "/health"
}

variable "certificate_arn" {
  description = "ARN of an AWS Certificate Manager certificate. When set, the load balancer serves HTTPS and redirects HTTP to HTTPS."
  type        = string
  default     = ""
}

variable "deletion_protection" {
  description = "Refuse to delete the load balancer (turn on for prod)."
  type        = bool
  default     = false
}
