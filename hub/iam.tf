
# --------------------------------------------------------------------------------
# HUB SERVICE ACCOUNT
# --------------------------------------------------------------------------------

resource "google_service_account" "hub_admin_sa" {
  account_id   = "tf-cloud-sa"
  display_name = "Lornu-AI Hub Orchestrator"
}

# --------------------------------------------------------------------------------
# WORKLOAD IDENTITY FEDERATION BINDINGS
# --------------------------------------------------------------------------------

# Allow HCP Terraform to impersonate this SA via the NEW pool
resource "google_service_account_iam_member" "wif_tfc_impersonation" {
  service_account_id = google_service_account.hub_admin_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-ai-hub"
}

# --------------------------------------------------------------------------------
# PERMISSIONS FOR THE ADMIN SA
# --------------------------------------------------------------------------------

# 1. ORG-LEVEL: Create Projects
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}

# 2. BILLING: Attach to Billing Account
resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}

# 3. PROJECT-LEVEL: Administer Service Accounts (Fixes 403 error on self-read)
resource "google_project_iam_member" "sa_admin" {
  project = var.hub_project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${google_service_account.hub_admin_sa.email}"
}