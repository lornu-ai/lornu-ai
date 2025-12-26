# Secrets variables - populated by GitHub Actions from GitHub Secrets
# These are passed as environment variables during terraform apply
variable "resend_api_key" {
  description = "Resend API key for contact form email service"
  type        = string
  sensitive   = true
  default     = ""
}

# Add more secret variables as needed
# variable "database_password" {
#   description = "Database password"
#   type        = string
#   sensitive   = true
#   default     = ""
# }
