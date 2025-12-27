# --------------------------------------------------------------------------------
# HUB SERVICE ACCOUNT
# --------------------------------------------------------------------------------

# EXISTING: The Hub Admin Service Account
resource "google_service_account" "hub_admin_sa" {
  account_id   = "terraform-admin-sa" # Matches your gcloud setup
  display_name = "Lornu-AI Hub Orchestrator"
}

# --------------------------------------------------------------------------------
# WORKLOAD IDENTITY FEDERATION (OIDC BINDINGS)
# --------------------------------------------------------------------------------

# EXISTING: Allow GitHub OIDC to impersonate this SA
resource "google_service_account_iam_member" "wif_github_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# UPDATED: Allow HCP Terraform (Remote Runners) to impersonate this SA
# We use the workspace name attribute for a clean, secure handshake.
resource "google_service_account_iam_member" "wif_tfc_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"

  # Targets specifically the 'lornu-ai-hub' workspace
  member = "principalSet://iam.googleapis.com/projects/${var.hub_project_id}/locations/global/workloadIdentityPools/github-pool/attribute.terraform_workspace_name/lornu-ai-hub"
}

# --------------------------------------------------------------------------------
# ORGANIZATION-LEVEL PERMISSIONS (FOR PROJECT SPAWNING)
# --------------------------------------------------------------------------------

# Permission to create projects within the Org
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}

# Permission to link new projects to your Billing Account
resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}