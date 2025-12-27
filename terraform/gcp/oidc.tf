resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "lornu-github-actions"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions authentication"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "lornu-github-actions-oidc"
  display_name                       = "GitHub Actions OIDC Provider"
  description                        = "OIDC Identity Provider for GitHub Actions"

  # Map assertions from the OIDC token to Google attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions is defined in github-wif.tf
# This file only defines the OIDC pool and provider
# Outputs are also defined in github-wif.tf
