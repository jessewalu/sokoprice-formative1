output "alb_security_group_id" {
  description = "ID of the load balancer security group."
  value       = aws_security_group.alb.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion host security group."
  value       = aws_security_group.bastion.id
}

output "bastion_security_group_arn" {
  description = "ARN of the bastion host security group (the deployment role may open and close SSH access on it)."
  value       = aws_security_group.bastion.arn
}

output "app_security_group_id" {
  description = "ID of the application server security group."
  value       = aws_security_group.app.id
}

output "db_security_group_id" {
  description = "ID of the database security group."
  value       = aws_security_group.db.id
}
