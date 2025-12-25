output "cloud_run_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.backend.uri
}

output "service_account_email" {
  description = "Email of the backend service account"
  value       = google_service_account.lornu_backend.email
}

output "firestore_database_name" {
  description = "Name of the Firestore database"
  value       = google_firestore_database.lornu_db.name
}

output "project_id" {
  description = "GCP Project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP Region"
  value       = var.region
}
