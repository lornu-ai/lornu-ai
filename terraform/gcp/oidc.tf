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

# Service Account for GitHub Actions (CI/CD)
# We create a specific SA for CI/CD instead of reusing the app runtime SA (lornu-backend)
# to follow the Principle of Least Privilege.
resource "google_service_account" "github_actions" {
  account_id   = "lornu-github-actions"
  display_name = "GitHub Actions Service Account"
  description  = "Service Account used by GitHub Actions for CI/CD"
}

# Allow GitHub Actions to impersonate only this Service Account
# Restricted to the specific repository 'lornu-ai/lornu-ai'
resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/lornu-ai/lornu-ai"
}

# Role: Artifact Registry Writer (to push Docker images)
resource "google_project_iam_member" "artifact_registry_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Role: Kubernetes Developer (to deploy to GKE)
resource "google_project_iam_member" "gke_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Role: Service Account User (scoped to the GitHub Actions service account)
# Allows the SA to act as itself (often required for GKE interactions where the caller identity is checked)
resource "google_service_account_iam_member" "github_actions_service_account_user" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_actions_service_account_email" {
  description = "The Service Account email for GitHub Actions"
  value       = google_service_account.github_actions.email
}
