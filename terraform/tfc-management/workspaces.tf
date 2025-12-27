# TFC Workspace Data Sources and Configuration
# We use data sources since workspaces already exist

data "tfe_workspace" "aws_kustomize" {
  name         = "aws-kustomize"
  organization = var.tfc_organization
}

data "tfe_workspace" "gcp_lornu_ai" {
  name         = "gcp-lornu-ai"
  organization = var.tfc_organization
}

# AWS Workspace OIDC Variables
# Enable Dynamic Provider Credentials for AWS
resource "tfe_variable" "aws_provider_auth" {
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  workspace_id = data.tfe_workspace.aws_kustomize.id
  description  = "Enable OIDC authentication for AWS provider"
}

resource "tfe_variable" "aws_run_role_arn" {
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = var.aws_oidc_role_arn
  category     = "env"
  workspace_id = data.tfe_workspace.aws_kustomize.id
  sensitive    = true
  description  = "IAM role ARN for TFC to assume via OIDC"
}

# GCP Workspace OIDC Variables
# Enable Dynamic Provider Credentials for GCP
resource "tfe_variable" "gcp_provider_auth" {
  key          = "TFC_GCP_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  workspace_id = data.tfe_workspace.gcp_lornu_ai.id
  description  = "Enable OIDC authentication for GCP provider"
}

resource "tfe_variable" "gcp_run_service_account_email" {
  key          = "TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL"
  value        = var.gcp_service_account_email
  category     = "env"
  workspace_id = data.tfe_workspace.gcp_lornu_ai.id
  sensitive    = true
  description  = "GCP service account email for TFC workload identity"
}

resource "tfe_variable" "gcp_workload_provider_name" {
  key          = "TFC_GCP_WORKLOAD_PROVIDER_NAME"
  value        = var.gcp_workload_provider_name
  category     = "env"
  workspace_id = data.tfe_workspace.gcp_lornu_ai.id
  sensitive    = true
  description  = "Full resource name of the GCP Workload Identity Provider"
}
