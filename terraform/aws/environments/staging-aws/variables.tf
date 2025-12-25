# Trigger CI
variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "us-east-2"
}

variable "docker_image" {
  description = "The Docker image to deploy to the ECS cluster."
  type        = string
  default     = "lornu-ai/api:latest"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the ALB."
  type        = string
  default     = "arn:aws:acm:us-east-2:123456789012:certificate/placeholder"
}

variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for the secrets the application needs to access."
  type        = string
  default     = "arn:aws:secretsmanager:us-east-2:123456789012:secret:placeholder-*"
}

variable "resource_prefix" {
  description = "The resource prefix for naming (e.g., lornu-ai)"
  type        = string
  default     = "lornu-ai"
}

variable "github_repo" {
  description = "The GitHub repository name for tagging resources"
  type        = string
  default     = "lornu-ai"
}
