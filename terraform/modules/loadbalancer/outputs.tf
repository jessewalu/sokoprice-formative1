output "dns_name" {
  description = "Public DNS name of the load balancer. This is the address of the live application."
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ARN of the load balancer."
  value       = aws_lb.this.arn
}

output "arn_suffix" {
  description = "ARN suffix of the load balancer, used in CloudWatch metric dimensions."
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group, used in CloudWatch metric dimensions."
  value       = aws_lb_target_group.app.arn_suffix
}
