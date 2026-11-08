variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which the security group is created."
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
  description = "IPv4 CIDR blocks allowed to connect over SSH."
  type        = list(string)
}

variable "app_port" {
  description = "Public TCP port of the application."
  type        = number
  default     = 80
}

variable "app_allowed_cidrs" {
  description = "IPv4 CIDR blocks allowed to reach the application port."
  type        = list(string)
}
