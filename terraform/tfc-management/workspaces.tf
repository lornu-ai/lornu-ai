resource "tfe_workspace" "aws_environments" {
  for_each = var.aws_environments

  name         = each.value.workspace_name
  organization = var.organization
  auto_apply   = each.value.auto_apply

  working_directory = each.value.vcs_repo_path

  vcs_repo {
    identifier         = var.github_repository
    oauth_token_id     = var.github_oauth_token_id
    ingress_submodules = false
  }

  tag_names = ["aws", each.value.environment, "managed-by-tfe"]
}

# Standardized Variables (Environment Type)
resource "tfe_variable" "environment_type" {
  for_each = var.aws_environments

  key          = "ENVIRONMENT_TYPE"
  value        = each.value.environment
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.key].id
  description  = "The environment type (staging/production)"
}

# Standardized Variables (Cost Center)
resource "tfe_variable" "cost_center" {
  for_each = {
    for pair in setproduct(keys(var.aws_environments), keys(var.global_variables)) :
    "${pair[0]}-${pair[1]}" => {
      workspace_key = pair[0]
      var_key       = pair[1]
      var_value     = var.global_variables[pair[1]]
    }
  }

  key          = each.value.var_key
  value        = each.value.var_value
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.value.workspace_key].id
  description  = "Global governance variable for ROI reporting"
}

# AWS Region Injection
resource "tfe_variable" "aws_region" {
  for_each = var.aws_environments

  key          = "AWS_DEFAULT_REGION"
  value        = each.value.aws_region
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.key].id
  description  = "Default AWS region for the environment"
}

# OIDC Security Injection: TFC_AWS_PROVIDER_AUTH
resource "tfe_variable" "aws_provider_auth" {
  for_each = var.aws_environments

  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.key].id
  description  = "Enable OIDC authentication for AWS provider"
}

# OIDC Security Injection: TFC_AWS_RUN_ROLE_ARN
resource "tfe_variable" "aws_run_role_arn" {
  for_each = var.aws_environments

  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = each.value.role_arn
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.key].id
  description  = "The IAM Role ARN for TFC to assume via OIDC"
}

# Example of a sensitive variable (Placeholder for Gemini API Key)
# In a real scenario, the value would be provided via a secret or sensitive variable in the management workspace
resource "tfe_variable" "gemini_api_key" {
  for_each = var.aws_environments

  key          = "GEMINI_API_KEY"
  value        = "REPLACE_ME" # This should be set manually or via a secure method
  category     = "env"
  workspace_id = tfe_workspace.aws_environments[each.key].id
  sensitive    = true
  description  = "The Gemini API Key for ADK Agents"

  lifecycle {
    ignore_changes = [value]
  }
}
