# Secret Manager Secret for Resend API Key
resource "google_secret_manager_secret" "resend_api_key" {
  secret_id = "resend-api-key"
  replication {
    auto {}
  }

  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}

# Allow GKE Service Account (Workload Identity) to access this secret
resource "google_secret_manager_secret_iam_member" "resend_api_key_access" {
  secret_id = google_secret_manager_secret.resend_api_key.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:lornu-backend@${var.project_id}.iam.gserviceaccount.com"
}
