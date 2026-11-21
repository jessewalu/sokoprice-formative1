variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "bastion_subnet_id" {
  description = "ID of the PUBLIC subnet in which the bastion host is launched."
  type        = string
}

variable "app_subnet_id" {
  description = "ID of the PRIVATE subnet in which the application server is launched."
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the security group attached to the bastion host."
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the security group attached to the application server."
  type        = string
}

variable "app_log_group_arn" {
  description = "ARN of the CloudWatch log group that the application server may write container logs to."
  type        = string
}

variable "bastion_instance_type" {
  description = "EC2 instance type of the bastion host (it only forwards SSH, so it can be tiny)."
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
}

variable "ssh_public_key" {
  description = "Public SSH key (text of the .pub file) installed for the default user."
  type        = string
}

variable "ami_owner_id" {
  description = "AWS account ID that publishes the machine image (Canonical for Ubuntu)."
  type        = string
}

variable "ami_name_pattern" {
  description = "Name pattern of the machine image to use."
  type        = string
}

variable "enable_detailed_monitoring" {
  description = "Enable 1-minute EC2 metrics (extra cost)."
  type        = bool
  default     = false
}

variable "ssh_user" {
  description = "Default operating system user of the machine image (ubuntu for Ubuntu images)."
  type        = string
  default     = "ubuntu"
}
