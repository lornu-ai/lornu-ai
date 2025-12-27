# GitHub Actions Workload Identity Federation (WIF) for CI/CD
# Allows GitHub Actions to authenticate to GCP without static service account keys

# Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_actions" {
  project                   = var.project_id
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions OIDC authentication"
}

# Workload Identity Provider for GitHub Actions OIDC
resource "google_iam_workload_identity_pool_provider" "github_actions" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-actions-provider"
  display_name                       = "GitHub Actions Provider"
  description                        = "OIDC provider for GitHub Actions"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.workflow"   = "assertion.workflow"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Service Account for GitHub Actions CI/CD
resource "google_service_account" "github_actions" {
  account_id   = "github-actions"
  display_name = "GitHub Actions CI/CD Service Account"
  description  = "Service account for GitHub Actions workflows to authenticate to GCP"
}

# Grant permissions to the GitHub Actions service account
# Use least privilege principle - specific roles instead of roles/editor
# Compute Engine permissions (for GKE)
resource "google_project_iam_member" "github_actions_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_compute_network" {
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# IAM permissions (for service accounts and roles)
resource "google_project_iam_member" "github_actions_iam" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

resource "google_project_iam_member" "github_actions_iam_workload_identity" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityPoolAdmin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Secret Manager permissions
resource "google_project_iam_member" "github_actions_secret_manager" {
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Artifact Registry permissions (for pushing container images)
resource "google_project_iam_member" "github_actions_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# GKE permissions (for deploying to GKE)
resource "google_project_iam_member" "github_actions_gke" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Cloud Storage permissions (for managing assets)
resource "google_project_iam_member" "github_actions_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# Workload Identity User binding
# Allow GitHub Actions to impersonate this service account
# Restrict to lornu-ai/lornu-ai repository
# Note: Branch restrictions should be enforced via IAM conditions or workflow-level checks
resource "google_service_account_iam_member" "github_actions_wif" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions.workload_identity_pool_id}/attribute.repository/lornu-ai/lornu-ai"

  # Branch restriction via IAM condition (main branch only)
  condition {
    title       = "main-branch-only"
    description = "Only allow access from main branch"
    expression  = "attribute.ref == \"refs/heads/main\""
  }
}

# Data source for project number (needed for principalSet)
data "google_project" "project" {
  project_id = var.project_id
}

# Outputs
output "github_actions_wif_provider" {
  description = "Workload Identity Provider resource name for GitHub Actions"
  value       = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_actions.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github_actions.workload_identity_pool_provider_id}"
}

output "github_actions_service_account_email" {
  description = "Service account email for GitHub Actions"
  value       = google_service_account.github_actions.email
}

output "github_actions_wif_pool_id" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
}

