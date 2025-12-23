variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Environment name (e.g., staging, production)"
  type        = string
  default     = "staging"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "docker_image" {
  description = "Docker image to deploy (ECR URI or Docker Hub)"
  type        = string
  default     = "lornuai/lornu-ai:commit-sha"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for the ALB"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:acm:", var.acm_certificate_arn))
    error_message = "Must be a valid ACM certificate ARN starting with 'arn:aws:acm:'"
  }
}

variable "secrets_manager_arn_pattern" {
  description = "The ARN pattern for the secrets the application needs to access"
  type        = string
  default     = "arn:aws:secretsmanager:*:*:secret:*"
}

variable "secret_gemini_api_key_arn" {
  description = "ARN of the Gemini API Key in AWS Secrets Manager"
  type        = string
  default     = "" # To be provided at runtime
}
