output "role_arn" {
  description = "ARN of the IAM role the deployment workflow assumes. Store it as the GitHub variable AWS_ROLE_ARN."
  value       = aws_iam_role.deploy.arn
}

output "role_name" {
  description = "Name of the deployment role."
  value       = aws_iam_role.deploy.name
}
