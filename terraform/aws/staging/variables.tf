variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
}

variable "docker_image" {
  description = "The Docker image to deploy to the ECS cluster."
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the ALB."
  type        = string
}

variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for the secrets the application needs to access."
  type        = string
}
