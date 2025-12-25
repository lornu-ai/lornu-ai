# Service Account for Kubernetes workloads with Vertex AI and Firestore permissions
resource "google_service_account" "lornu_backend" {
  account_id   = "lornu-backend"
  display_name = "Lornu AI Backend Service Account"
  description  = "Service account for Kubernetes workloads with Vertex AI and Firestore access"

  depends_on = [
    google_project_service.iam
  ]
}

# Grant Vertex AI User role (for Gemini API access)
resource "google_project_iam_member" "vertex_ai_user" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.lornu_backend.email}"
}

# Grant Firestore User role (read/write access)
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.lornu_backend.email}"
}

# Bind service account to Kubernetes service accounts across all environments
resource "google_service_account_iam_member" "workload_identity_binding" {
  for_each = toset(["lornu-prod", "lornu-stage", "lornu-dev"])

  service_account_id = google_service_account.lornu_backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${each.value}/lornu-ai]"
}

# Provisioning Service Account (Managed for role visibility)
resource "google_service_account" "terraform_provisioner" {
  account_id   = "terraform-provisioner"
  display_name = "Terraform Provisioning Service Account"
  description  = "Service account used by GitHub Actions/Terraform Cloud to provision infrastructure"
}

# Key for the provisioning service account (to be exported to GitHub Secrets)
resource "google_service_account_key" "provisioner_key" {
  service_account_id = google_service_account.terraform_provisioner.name
}

# Provisioning Service Account Roles
resource "google_project_iam_member" "terraform_provisioner_roles" {
  for_each = toset([
    "roles/serviceusage.serviceUsageAdmin",
    "roles/container.admin",
    "roles/compute.networkAdmin",
    "roles/datastore.owner",
    "roles/iam.serviceAccountAdmin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
    "roles/dns.admin"
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.terraform_provisioner.email}"
}
