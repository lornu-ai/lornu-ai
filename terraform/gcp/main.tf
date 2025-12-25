provider "google" {
  project = var.project_id
  region  = var.region
}

# Firestore Database for agent state persistence
resource "google_firestore_database" "lornu_db" {
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  # Prevent accidental deletion
  deletion_policy = "DELETE"
}

# Service Account for Cloud Run with Vertex AI and Firestore permissions
resource "google_service_account" "lornu_backend" {
  account_id   = "lornu-backend"
  display_name = "Lornu AI Backend Service Account"
  description  = "Service account for Cloud Run backend with Vertex AI and Firestore access"
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

# Cloud Run Service for backend
resource "google_cloud_run_v2_service" "backend" {
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.lornu_backend.email

    containers {
      image = var.container_image

      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "FIRESTORE_DATABASE"
        value = google_firestore_database.lornu_db.name
      }

      env {
        name  = "ENVIRONMENT"
        value = "gcp-develop"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
    }

    scaling {
      min_instance_count = 0 # Scale to zero for OpEx optimization
      max_instance_count = 10
    }
  }

  depends_on = [
    google_firestore_database.lornu_db,
    google_service_account.lornu_backend
  ]
}

# Make Cloud Run service publicly accessible
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  name     = google_cloud_run_v2_service.backend.name
  location = google_cloud_run_v2_service.backend.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
