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

variable "route53_zone_name" {
  description = "The Route53 hosted zone name"
  type        = string
  default     = "lornu.ai"
}

variable "create_route53_zone" {
  description = "Whether to create the Route53 hosted zone"
  type        = bool
  default     = true
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

variable "k8s_namespace_prefix" {
  description = "Kubernetes namespace prefix (e.g., 'prod-' for production) to match Kustomize namePrefix"
  type        = string
  default     = "prod-"
}

variable "alb_domain_name" {
  description = "The ALB domain name for CloudFront origin (e.g., alb.internal.lornu.ai). Falls back to Kubernetes Ingress status if not provided."
  type        = string
  default     = ""
}

variable "db_password" {
  description = "The master password for the database."
  type        = string
  sensitive   = true
}

variable "deploy_stage" {
  description = "Deployment stage: 1 = ACM + Route53 zone + validation, 2 = CloudFront + alias records (requires stage 1 complete)"
  type        = number
  default     = 2

  validation {
    condition     = var.deploy_stage >= 1 && var.deploy_stage <= 2
    error_message = "deploy_stage must be 1 or 2"
  }
}

variable "existing_acm_certificate_arn" {
  description = "ARN of an existing ACM certificate to use for CloudFront. If provided, skips certificate creation."
  type        = string
  default     = ""
}
