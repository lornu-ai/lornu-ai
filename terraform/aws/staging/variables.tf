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

variable "container_image" {
  description = "Docker image to deploy (ECR URI or Docker Hub)"
  type        = string
  # Placeholder until we have the ECR repo set up
  default     = "lornu-ai/backend:0.1.0"
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "secret_gemini_api_key_arn" {
  description = "ARN of the Gemini API Key in AWS Secrets Manager"
  type        = string
  default     = "" # To be provided at runtime
}
