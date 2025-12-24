variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "us-east-1"
}

variable "docker_image" {
  description = "The Docker image to deploy to the ECS cluster."
  type        = string
  default     = "lornuai/lornu-ai:commit-sha"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the ALB."
  type        = string
}

variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for the secrets the application needs to access."
  type        = string
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "lornu_production"
}

variable "db_username" {
  description = "The master username for the database."
  type        = string
  default     = "lornu_admin"
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "resource_prefix" {
  description = "Prefix for all resources"
  type        = string
}

variable "github_repo" {
  description = "The name of the GitHub repository"
  type        = string
}
