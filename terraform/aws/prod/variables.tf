variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "us-east-1"
}

variable "docker_image" {
  description = "The Docker image to deploy to the ECS cluster."
  type        = string
  default     = "lornuai/lornu-ai:latest" # placeholder, will be overridden via TF_VAR
}

variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for the secrets the application needs to access (prod)."
  type        = string
}

variable "git_sha" {
  description = "Git commit SHA used for image tagging."
  type        = string
}

variable "domain" {
  description = "The domain name for the application (e.g., lornu.ai)"
  type        = string
}
