# Compatibility variables to satisfy Terraform Cloud's strict variable checking
# These variables are often set in TFC workspaces or by CI environments but may not be
# directly used in the current configuration.

variable "GCP_PROJECT_ID" {
  type        = string
  description = "Duplicate of project_id, sometimes required by TFC environment mappings"
  default     = ""
}

variable "GOOGLE_CREDENTIALS" {
  type        = string
  description = "GCP Credentials JSON, sometimes mapped as a TF variable by TFC"
  default     = ""
}

variable "TF_VAR_project_id" {
  type        = string
  description = "Direct mapping of the env var to a TF var to satisfy TFC"
  default     = ""
}
