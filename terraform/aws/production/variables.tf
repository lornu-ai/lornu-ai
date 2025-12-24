variable "aws_region" {
  description = "The AWS region to deploy the infrastructure to."
  type        = string
  default     = "us-east-2"
}

variable "docker_image" {
  description = "The Docker image to deploy to the EKS cluster."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application (e.g. lornu.ai)"
  type        = string
  default     = "lornu.ai"
}

variable "api_domain" {
  description = "DNS name for the API CloudFront distribution (e.g. api.lornu.ai)"
  type        = string
  default     = "api.lornu.ai"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for the ALB"
  type        = string
}

variable "route53_zone_name" {
  description = "The Route53 hosted zone name"
  type        = string
  default     = "lornu.ai"
}

variable "create_route53_zone" {
  description = "Whether to create the Route53 hosted zone"
  type        = bool
  default     = false
}

variable "cloudfront_web_acl_id" {
  description = "Optional WAFv2 Web ACL ID to associate with CloudFront"
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
