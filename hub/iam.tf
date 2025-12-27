# --------------------------------------------------------------------------------
# HUB SERVICE ACCOUNT
# --------------------------------------------------------------------------------

resource "google_service_account" "hub_admin_sa" {
  account_id   = "terraform-admin-sa"
  display_name = "Lornu-AI Hub Orchestrator"
}

# --------------------------------------------------------------------------------
# WORKLOAD IDENTITY FEDERATION (OIDC BINDINGS)
# --------------------------------------------------------------------------------

# Allow GitHub Actions to impersonate this SA
resource "google_service_account_iam_member" "wif_github_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# Allow HCP Terraform (Remote Runners) to impersonate this SA
resource "google_service_account_iam_member" "wif_tfc_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"

  # Note: This uses the 'terraform_workspace_name' attribute defined in main.tf
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.terraform_workspace_name/lornu-ai-hub"
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