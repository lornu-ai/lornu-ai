variable "project_id" {
  description = "The GCP project ID for the Agent Spoke"
  type        = string
  default     = "lornu-agent-spoke"
}

variable "region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "node_count" {
  description = "Number of nodes in the GKE node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}
