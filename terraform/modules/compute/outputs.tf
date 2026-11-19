output "bastion_instance_id" {
  description = "ID of the bastion host."
  value       = aws_instance.bastion.id
}

output "bastion_public_ip" {
  description = "Public (Elastic) IP address of the bastion host."
  value       = aws_eip.bastion.public_ip
}

output "bastion_private_ip" {
  description = "Private IP address of the bastion host inside the VPC."
  value       = aws_instance.bastion.private_ip
}

output "app_instance_id" {
  description = "ID of the application server."
  value       = aws_instance.app.id
}

output "app_private_ip" {
  description = "Private IP address of the application server (reachable through the bastion only)."
  value       = aws_instance.app.private_ip
}

output "ssh_user" {
  description = "Operating system user for SSH."
  value       = var.ssh_user
}

output "key_name" {
  description = "Name of the EC2 key pair."
  value       = aws_key_pair.this.key_name
}
