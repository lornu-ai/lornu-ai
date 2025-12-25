# Service Account for the Backend Application
resource "google_service_account" "backend" {
  account_id   = "lornu-backend"
  display_name = "Lornu AI Backend Service Account"
}

# Grant permissions to the Service Account
# Access to Firestore
resource "google_project_iam_member" "firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

# Access to Cloud Storage (Assets)
resource "google_project_iam_member" "storage_viewer" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

# Access to Artifact Registry (for pulling images - actually GKE creates its own SA for nodes, 
# but if we used this for something else it would be needed. Nodes use the compute SA by default.)

# Workload Identity Binding
# Allow Kubernetes ServiceAccount to act as this GCP ServiceAccount
resource "google_service_account_iam_member" "workload_identity_user_dev" {
  service_account_id = google_service_account.backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[lornu-dev/lornu-ai]"
}

resource "google_service_account_iam_member" "workload_identity_user_prod" {
  service_account_id = google_service_account.backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[lornu-prod/lornu-ai]"
}

# Output the Service Account Email
output "backend_cn_email" {
  value = google_service_account.backend.email
}
