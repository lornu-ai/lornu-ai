# GKE Cluster Configuration
# This manages the main Kubernetes cluster for Lornu AI

resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  # Workload Identity is required for secure pod-to-GCP service integration
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network configuration
  network    = "default"
  subnetwork = "default"

  # Enable network policy for security
  network_policy {
    enabled = true
  }

  # Enable shielded nodes for additional security
  enable_shielded_nodes = true

  # Enable autopilot for easier management (optional, can be disabled for standard)
  # Uncomment the next line to enable GKE Autopilot
  # enable_autopilot = true

  # Binary authorization (optional security feature)
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  # Maintenance policy
  maintenance_policy {
    recurring_window {
      start_time = "2023-01-01T01:00:00Z"
      end_time   = "2023-01-01T05:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SA"
    }
  }

  # Logging and monitoring
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Resource labels
  resource_labels = {
    environment = "production"
    managed-by  = "terraform"
    asset-id    = "lornu-ai-final-clear-bg"
  }
}

# Separately managed node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-nodes"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 2

  # Auto-scaling configuration
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  node_config {
    preemptible  = false
    machine_type = "e2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke_nodes.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # Enable workload identity on nodes
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Shielded VM configuration
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      environment = "production"
      managed-by  = "terraform"
    }

    tags = ["gke-node", "lornu-ai"]
  }

  # Upgrade settings
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Service account for GKE nodes
resource "google_service_account" "gke_nodes" {
  account_id   = "lornu-gke-nodes"
  display_name = "Lornu AI GKE Nodes Service Account"
}

# IAM roles for the GKE nodes service account
resource "google_project_iam_member" "gke_nodes_registry" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_gcr" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

resource "google_project_iam_member" "gke_nodes_monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Output cluster connection information
output "kubernetes_cluster_name" {
  value = google_container_cluster.primary.name
}

output "kubernetes_cluster_host" {
  value = google_container_cluster.primary.endpoint
}