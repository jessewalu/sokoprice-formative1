output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public (Elastic) IP address of the instance."
  value       = aws_eip.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance inside the VPC."
  value       = aws_instance.this.private_ip
}

output "ssh_user" {
  description = "Operating system user to use for SSH and Ansible."
  value       = var.ssh_user
}

output "ami_id" {
  description = "ID of the machine image the instance was launched from."
  value       = data.aws_ami.ubuntu.id
}

output "instance_role_name" {
  description = "Name of the IAM role attached to the instance."
  value       = aws_iam_role.instance.name
}
