output "security_group_id" {
  description = "ID of the application server security group."
  value       = aws_security_group.app.id
}

output "security_group_arn" {
  description = "ARN of the application server security group."
  value       = aws_security_group.app.arn
}
