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

variable "cloudfront_acm_certificate_arn" {
  description = "The ARN of the ACM certificate (us-east-1) for the CloudFront distribution."
  type        = string
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for lornu.ai."
  type        = string
}

variable "api_domain" {
  description = "DNS name for the API CloudFront distribution."
  type        = string
  default     = "api.lornu.ai"
}

variable "cloudfront_web_acl_id" {
  description = "Optional WAFv2 Web ACL ID to associate with CloudFront."
  type        = string
  default     = ""
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
