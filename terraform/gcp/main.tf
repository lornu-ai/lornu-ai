provider "google" {
  project = var.project_id
  region  = var.region
}

# VPC Network for GKE
resource "google_compute_network" "vpc" {
  name                    = "lornu-ai-vpc"
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute
  ]
}

# Subnet for GKE cluster
resource "google_compute_subnetwork" "gke_subnet" {
  name          = "lornu-ai-gke-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# GKE Autopilot Cluster (serverless Kubernetes)
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # Enable Autopilot mode for serverless management
  enable_autopilot = true

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.gke_subnet.name

  # IP allocation for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity for IRSA-like functionality
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Maintenance window
  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  # Wait for required APIs to be enabled
  depends_on = [
    google_project_service.container,
    google_project_service.compute
  ]
}

# Firestore Database for agent state persistence
resource "google_firestore_database" "lornu_db" {
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"

  deletion_policy = "DELETE"

  depends_on = [
    google_project_service.firestore
  ]
}

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

# Bind service account to Kubernetes service account via Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.lornu_backend.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/lornu-ai]"
}
