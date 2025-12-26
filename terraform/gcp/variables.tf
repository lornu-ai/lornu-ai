variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "gcp-lornu-ai"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
  default     = "lornu-ai-gke"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "lornu.ai"
}
