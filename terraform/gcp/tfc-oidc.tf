# Terraform Cloud Workload Identity Federation for Dynamic Provider Credentials
# Eliminates static GCP service account JSON keys in TFC workspaces
# Reference: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/gcp-configuration

# Workload Identity Pool for Terraform Cloud
resource "google_iam_workload_identity_pool" "tfc_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "lornu-tfc-pool"
  display_name              = "Terraform Cloud Pool"
  description               = "Identity pool for Terraform Cloud Dynamic Provider Credentials"
}

# OIDC Provider for Terraform Cloud
resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "lornu-tfc-oidc"
  display_name                       = "Terraform Cloud OIDC Provider"
  description                        = "OIDC Identity Provider for Terraform Cloud runs"

  # Map assertions from the TFC OIDC token to Google attributes
  attribute_mapping = {
    "google.subject"                   = "assertion.sub"
    "attribute.terraform_organization" = "assertion.terraform_organization_name"
    "attribute.terraform_workspace"    = "assertion.terraform_workspace_name"
    "attribute.terraform_run_phase"    = "assertion.terraform_run_phase"
  }

  # Restrict to lornu-ai TFC organization
  attribute_condition = "attribute.terraform_organization == \"lornu-ai\""

  oidc {
    issuer_uri = "https://app.terraform.io"
  }
}

# Service Account for Terraform Cloud infrastructure management
resource "google_service_account" "tfc_infrastructure" {
  account_id   = "lornu-tfc-infra"
  display_name = "Terraform Cloud Infrastructure SA"
  description  = "Service Account for Terraform Cloud to manage GCP infrastructure"
}

# Allow Terraform Cloud workloads to impersonate this Service Account
# Scoped to the lornu-ai organization and gcp-lornu-ai workspace
resource "google_service_account_iam_member" "tfc_workload_identity" {
  service_account_id = google_service_account.tfc_infrastructure.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.tfc_pool.workload_identity_pool_id}/attribute.terraform_workspace/gcp-lornu-ai"
}

# IAM Roles for Terraform Cloud Infrastructure Management

# GKE Full Admin - to manage the cluster
resource "google_project_iam_member" "tfc_gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Compute Admin - for networking, load balancers, etc.
resource "google_project_iam_member" "tfc_compute_admin" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# IAM Admin - to manage service accounts and bindings
resource "google_project_iam_member" "tfc_iam_admin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# IAM Workload Identity Pool Admin - to manage WIF pools
resource "google_project_iam_member" "tfc_wif_admin" {
  project = var.project_id
  role    = "roles/iam.workloadIdentityPoolAdmin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Storage Admin - for Cloud Storage buckets
resource "google_project_iam_member" "tfc_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Artifact Registry Admin - for container images
resource "google_project_iam_member" "tfc_artifact_registry_admin" {
  project = var.project_id
  role    = "roles/artifactregistry.admin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Firestore Admin - for database management
resource "google_project_iam_member" "tfc_firestore_admin" {
  project = var.project_id
  role    = "roles/datastore.owner"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Service Usage Admin - to enable/disable APIs
resource "google_project_iam_member" "tfc_service_usage_admin" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageAdmin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Project IAM Admin - to manage project-level IAM policies
resource "google_project_iam_member" "tfc_project_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:${google_service_account.tfc_infrastructure.email}"
}

# Data source for project number (needed for principalSet)
data "google_project" "project" {
  project_id = var.project_id
}

# Outputs for TFC workspace configuration
output "tfc_workload_identity_pool_name" {
  description = "The full resource name of the TFC Workload Identity Pool"
  value       = google_iam_workload_identity_pool.tfc_pool.name
}

output "tfc_workload_identity_provider_name" {
  description = "The full resource name of the TFC Workload Identity Provider"
  value       = google_iam_workload_identity_pool_provider.tfc_provider.name
}

output "tfc_service_account_email" {
  description = "The Service Account email for Terraform Cloud"
  value       = google_service_account.tfc_infrastructure.email
}
