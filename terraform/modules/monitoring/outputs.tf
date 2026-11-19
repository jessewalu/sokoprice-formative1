output "app_log_group_name" {
  description = "Name of the CloudWatch log group that receives the application's container logs."
  value       = aws_cloudwatch_log_group.app.name
}

output "app_log_group_arn" {
  description = "ARN of the application log group."
  value       = aws_cloudwatch_log_group.app.arn
}

output "alerts_topic_arn" {
  description = "ARN of the SNS topic that alarms notify."
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}
