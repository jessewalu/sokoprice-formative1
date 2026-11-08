# -----------------------------------------------------------------------------
# Outputs: the details you (and Ansible) need after `terraform apply`.
# Nothing here is secret. Show them with `terraform output`.
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.network.public_subnet_ids
}

output "security_group_id" {
  description = "ID of the application server security group."
  value       = module.security.security_group_id
}

output "instance_id" {
  description = "ID of the EC2 instance."
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public (Elastic) IP address of the server. It stays the same if the instance is stopped and started."
  value       = module.compute.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the server inside the VPC."
  value       = module.compute.private_ip
}

output "app_url" {
  description = "URL of the SokoPrice API once Ansible has deployed it."
  value       = "http://${module.compute.public_ip}:${var.app_port}"
}

output "ssh_command" {
  description = "Command to open an SSH session (add -i with the path of your private key)."
  value       = "ssh -p ${var.ssh_port} ${module.compute.ssh_user}@${module.compute.public_ip}"
}

output "ansible_inventory" {
  description = "Ready-made static Ansible inventory. Save it with: terraform output -raw ansible_inventory > ../ansible/inventory/hosts.ini"

  value = <<-EOT
    [sokoprice]
    ${local.name_prefix}-app ansible_host=${module.compute.public_ip} ansible_port=${var.ssh_port} ansible_user=${module.compute.ssh_user}

    [sokoprice:vars]
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
