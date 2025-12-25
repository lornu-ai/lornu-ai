variable "project_id" {
  description = "GCP Project ID (set via TF_VAR_project_id from GitHub Secrets). Use project ID (string), NOT project number (numeric)."
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "lornu-ai-gke"
}

variable "github_repo" {
  description = "GitHub repository (org/repo format)"
  type        = string
  default     = "lornu-ai/lornu-ai"
}
