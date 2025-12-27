resource "google_service_account" "hub_admin_sa" {
  account_id   = "tf-cloud-sa"
  display_name = "Lornu-AI Hub Orchestrator"
}

# Allow HCP Terraform to impersonate this SA via the NEW pool
resource "google_service_account_iam_member" "wif_tfc_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-ai-hub"
}

# Org permissions for project creation
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}

# Billing permissions
resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}
