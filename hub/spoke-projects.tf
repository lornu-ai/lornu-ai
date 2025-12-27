# --------------------------------------------------------------------------------
# SPOKE PROJECTS
# The Hub creates and manages spoke projects for different workloads
# --------------------------------------------------------------------------------

# Spoke 1: Agent Infrastructure (AI Agent runtime and services)
resource "google_project" "agent_spoke" {
  name            = "Lornu Agent Spoke"
  project_id      = "lornu-agent-spoke"
  org_id          = var.org_id
  billing_account = var.billing_account_id

  labels = {
    "lornu-ai-managed-by"  = "terraform-cloud"
    "lornu-ai-environment" = "production"
    "lornu-ai-spoke-type"  = "agent"
  }
}

# Enable required APIs for Agent Spoke
resource "google_project_service" "agent_spoke_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "artifactregistry.googleapis.com",
  ])

  project = google_project.agent_spoke.project_id
  service = each.value

  disable_on_destroy = false
}

# --------------------------------------------------------------------------------
# SPOKE SERVICE ACCOUNT
# Each spoke has its own SA for infrastructure management
# --------------------------------------------------------------------------------

resource "google_service_account" "agent_spoke_sa" {
  project      = google_project.agent_spoke.project_id
  account_id   = "tf-cloud-agent-sa"
  display_name = "Terraform Cloud Agent Spoke SA"

  depends_on = [google_project_service.agent_spoke_apis]
}

# Grant spoke SA permissions within its own project
resource "google_project_iam_member" "agent_spoke_permissions" {
  for_each = toset([
    "roles/compute.admin",
    "roles/container.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
  ])

  project = google_project.agent_spoke.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.agent_spoke_sa.email}"

  depends_on = [google_service_account.agent_spoke_sa]
}

# --------------------------------------------------------------------------------
# WIF BINDINGS FOR SPOKE
# Allow TFC workspace to impersonate the spoke SA
# --------------------------------------------------------------------------------

resource "google_service_account_iam_member" "agent_spoke_wif_impersonation" {
  service_account_id = google_service_account.agent_spoke_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-agent-spoke"
}

resource "google_service_account_iam_member" "agent_spoke_wif_token_creator" {
  service_account_id = google_service_account.agent_spoke_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-agent-spoke"
}

# --------------------------------------------------------------------------------
# OUTPUTS FOR SPOKE
# --------------------------------------------------------------------------------

output "agent_spoke_project_id" {
  description = "The ID of the Agent Spoke project"
  value       = google_project.agent_spoke.project_id
}

output "agent_spoke_sa_email" {
  description = "The email of the Agent Spoke service account"
  value       = google_service_account.agent_spoke_sa.email
}

output "agent_spoke_workload_provider" {
  description = "The workload identity provider for Agent Spoke TFC workspace"
  value       = google_iam_workload_identity_pool_provider.tfc_provider.name
}
