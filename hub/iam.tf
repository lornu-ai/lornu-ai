
# --------------------------------------------------------------------------------
# HUB SERVICE ACCOUNT (LOCALS)
# --------------------------------------------------------------------------------

# Using locals to avoid API Permission Errors when the SA tries to read itself
locals {
  hub_sa_email = "tf-cloud-sa@${var.hub_project_id}.iam.gserviceaccount.com"
  hub_sa_name  = "projects/${var.hub_project_id}/serviceAccounts/tf-cloud-sa@${var.hub_project_id}.iam.gserviceaccount.com"
}

# --------------------------------------------------------------------------------
# WORKLOAD IDENTITY FEDERATION BINDINGS
# --------------------------------------------------------------------------------

# Allow HCP Terraform to impersonate this SA via the NEW pool
resource "google_service_account_iam_member" "wif_tfc_impersonation" {
  service_account_id = local.hub_sa_name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-ai-hub"
}

# Allow HCP Terraform to get access tokens for this SA (required for WIF)
resource "google_service_account_iam_member" "wif_tfc_token_creator" {
  service_account_id = data.google_service_account.hub_admin_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.tfc_pool.name}/attribute.terraform_workspace_name/lornu-ai-hub"
}

# --------------------------------------------------------------------------------
# PERMISSIONS FOR THE ADMIN SA
# --------------------------------------------------------------------------------

# 1. ORG-LEVEL: Create Projects
resource "google_organization_iam_member" "project_creator" {
  org_id = var.org_id
  role   = "roles/resourcemanager.projectCreator"
  member = "serviceAccount:${local.hub_sa_email}"
}

# 2. BILLING: Attach to Billing Account
resource "google_billing_account_iam_member" "billing_user" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = "serviceAccount:${local.hub_sa_email}"
}

# 3. PROJECT-LEVEL: Administer Service Accounts
resource "google_project_iam_member" "sa_admin" {
  project = var.hub_project_id
  role    = "roles/iam.serviceAccountAdmin"
  member  = "serviceAccount:${local.hub_sa_email}"
}