# GitHub Actions Secrets Management
# Automates TFC API token rotation for CI/CD workflows

# Team token for GitHub Actions to interact with TFC
# This token is used by GitHub Actions workflows to trigger TFC runs
resource "tfe_team_token" "github_actions" {
  team_id = data.tfe_team.owners.id
}

data "tfe_team" "owners" {
  name         = "owners"
  organization = var.tfc_organization
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
