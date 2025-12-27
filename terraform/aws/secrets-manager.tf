# AWS Secrets Manager configuration for application secrets
# This allows GitHub Actions to sync secrets from GitHub Secrets to AWS Secrets Manager
# Terraform reads environment variables set by GitHub Actions and creates/updates secrets

resource "aws_secretsmanager_secret" "resend_api_key" {
  name                           = "lornu-ai/resend-api-key"
  description                    = "Resend API key for contact form email service"
  recovery_window_in_days        = 7
  force_overwrite_replica_secret = true

  tags = {
    Name        = "lornu-ai-resend-api-key"
    Environment = "production"
    ManagedBy   = "Terraform"
    Source      = "GitHub-Secrets"
  }
}

resource "aws_secretsmanager_secret_version" "resend_api_key" {
  secret_id = aws_secretsmanager_secret.resend_api_key.id
  secret_string = jsonencode({
    RESEND_API_KEY = var.resend_api_key
  })
}

# Add more secrets as needed
# Example:
# resource "aws_secretsmanager_secret" "database_password" {
#   name = "lornu-ai/database-password"
#   ...
# }

output "resend_api_key_secret_arn" {
  description = "ARN of the Resend API key secret"
  value       = aws_secretsmanager_secret.resend_api_key.arn
}

output "resend_api_key_secret_name" {
  description = "Name of the Resend API key secret"
  value       = aws_secretsmanager_secret.resend_api_key.name
}
