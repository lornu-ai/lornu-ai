# GitHub Actions Secrets Management
# Automates TFC API token rotation for CI/CD workflows

# Create a least-privileged team for GitHub Actions CI/CD
# This follows the principle of least privilege instead of using the "owners" team
resource "tfe_team" "github_actions" {
  name         = "github-actions-ci"
  organization = var.tfc_organization

  organization_access {
    # Minimal org-level access - only what's needed for CI
    manage_workspaces       = false
    manage_policies         = false
    manage_policy_overrides = false
    manage_run_tasks        = false
    manage_vcs_settings     = false
    manage_membership       = false
    manage_modules          = false
    manage_providers        = false
    manage_agent_pools      = false
    read_workspaces         = true
    read_projects           = true
  }
}

# Grant the CI team access to specific workspaces only
resource "tfe_team_access" "aws_kustomize" {
  team_id      = tfe_team.github_actions.id
  workspace_id = data.tfe_workspace.aws_kustomize.id

  permissions {
    runs              = "apply"
    variables         = "read"
    state_versions    = "read"
    sentinel_mocks    = "none"
    workspace_locking = false
    run_tasks         = false
  }
}

resource "tfe_team_access" "gcp_lornu_ai" {
  team_id      = tfe_team.github_actions.id
  workspace_id = data.tfe_workspace.gcp_lornu_ai.id

  permissions {
    runs              = "apply"
    variables         = "read"
    state_versions    = "read"
    sentinel_mocks    = "none"
    workspace_locking = false
    run_tasks         = false
  }
}

# Team token for GitHub Actions to interact with TFC
# Scoped to the least-privileged github-actions-ci team
resource "tfe_team_token" "github_actions" {
  team_id = tfe_team.github_actions.id
}

# Inject the TFC API token into GitHub Actions secrets
resource "github_actions_secret" "tf_api_token" {
  repository      = var.github_repository
  secret_name     = "TF_API_TOKEN"
  plaintext_value = tfe_team_token.github_actions.token
}

# Also set the TFC organization as a variable (not sensitive)
resource "github_actions_variable" "tfc_organization" {
  repository    = var.github_repository
  variable_name = "TFC_ORGANIZATION"
  value         = var.tfc_organization
}
