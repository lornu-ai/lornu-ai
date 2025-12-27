# Outputs from TFC Management Workspace

output "aws_workspace_id" {
  description = "ID of the aws-kustomize workspace"
  value       = data.tfe_workspace.aws_kustomize.id
}

output "gcp_workspace_id" {
  description = "ID of the gcp-lornu-ai workspace"
  value       = data.tfe_workspace.gcp_lornu_ai.id
}

output "aws_oidc_enabled" {
  description = "Whether OIDC is enabled for AWS workspace"
  value       = tfe_variable.aws_provider_auth.value == "true"
}

output "gcp_oidc_enabled" {
  description = "Whether OIDC is enabled for GCP workspace"
  value       = tfe_variable.gcp_provider_auth.value == "true"
}

output "github_secret_updated" {
  description = "Confirmation that GitHub secret was updated"
  value       = "TF_API_TOKEN updated in ${var.github_owner}/${var.github_repository}"
}
