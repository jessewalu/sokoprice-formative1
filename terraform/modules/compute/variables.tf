variable "name_prefix" {
  description = "Prefix for resource names, for example sokoprice-dev."
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet in which the instance is launched."
  type        = string
}

variable "security_group_ids" {
  description = "IDs of the security groups attached to the instance."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Size of the encrypted root volume in GiB."
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
