output "address" {
  description = "Host name of the database."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the database."
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the database."
  value       = var.db_name
}

output "username" {
  description = "Master user name."
  value       = var.db_username
}

output "identifier" {
  description = "Identifier of the database instance (used by monitoring)."
  value       = aws_db_instance.this.identifier
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret that holds the database credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "secret_kms_key_arn" {
  description = "ARN of the KMS key that encrypts the credentials secret."
  value       = aws_kms_key.secret.arn
}
