# EXISTING: The Hub Admin Service Account
resource "google_service_account" "hub_admin_sa" {
  account_id   = "terraform-admin-sa" # Matches your gcloud setup
  display_name = "Lornu-AI Hub Orchestrator"
}

# EXISTING/UPDATE: Allow GitHub OIDC to impersonate this SA
resource "google_service_account_iam_member" "wif_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}

# NEW/UPDATE: Permissions to create projects and attach billing
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}

resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}