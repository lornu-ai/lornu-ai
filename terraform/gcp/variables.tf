variable "project_id" {
  description = "GCP Project ID (set via TF_VAR_project_id from GitHub Secrets)"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "lornu-ai-backend"
}

variable "container_image" {
  description = "Container image for Cloud Run service"
  type        = string
  default     = "gcr.io/cloudrun/hello" # Placeholder, will be replaced by CI/CD
}

variable "github_repo" {
  description = "GitHub repository (org/repo format)"
  type        = string
  default     = "lornu-ai/lornu-ai"
}
