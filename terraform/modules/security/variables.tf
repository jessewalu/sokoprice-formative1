variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the security groups are created."
  type        = string
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC. DNS queries are only allowed towards this range (the VPC resolver)."
  type        = string
}

variable "ssh_port" {
  description = "TCP port of the SSH service."
  type        = number
  default     = 22
}

variable "admin_cidrs" {
  description = "IPv4 CIDR blocks allowed to connect to the bastion host over SSH."
  type        = list(string)
}

variable "app_port" {
  description = "TCP port the application listens on (the load balancer forwards to it)."
  type        = number
  default     = 80
}

variable "db_port" {
  description = "TCP port of the database."
  type        = number
  default     = 5432
}

variable "alb_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the load balancer."
  type        = list(string)
}

variable "enable_https" {
  description = "Also open port 443 on the load balancer (set when a certificate is configured)."
  type        = bool
  default     = false
}
