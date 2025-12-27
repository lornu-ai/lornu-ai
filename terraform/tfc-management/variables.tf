# Input Variables for TFC Management Workspace

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
  default     = "lornu-ai"
}

variable "github_owner" {
  description = "GitHub organization or user that owns the repository"
  type        = string
  default     = "lornu-ai"
}

variable "github_repository" {
  description = "GitHub repository name"
  type        = string
  default     = "lornu-ai"
}

# AWS OIDC Configuration
variable "aws_oidc_role_arn" {
  description = "ARN of the IAM role for TFC Dynamic Provider Credentials (from aws-kustomize workspace output)"
  type        = string
  sensitive   = true
}

# GCP OIDC Configuration
variable "gcp_workload_provider_name" {
  description = "Full resource name of the GCP Workload Identity Provider (from gcp-lornu-ai workspace output)"
  type        = string
  sensitive   = true
}

variable "gcp_service_account_email" {
  description = "Email of the GCP service account for TFC (from gcp-lornu-ai workspace output)"
  type        = string
  sensitive   = true
}
