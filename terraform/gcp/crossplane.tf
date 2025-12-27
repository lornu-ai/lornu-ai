# Crossplane GKE Autopilot Cluster Setup
# This creates the "Egg" (GKE cluster) that will host the "Chicken" (Crossplane)
# Crossplane will then manage GCP resources using Workload Identity

# VPC Network for the Management/Control Plane Cluster
resource "google_compute_network" "crossplane_vpc" {
  name                    = "crossplane-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false

  labels = {
    environment = "production"
    managed-by  = "terraform"
    purpose     = "crossplane-control-plane"
  }
}

# Subnet for the Management Cluster
resource "google_compute_subnetwork" "crossplane_subnet" {
  name          = "crossplane-subnet"
  project       = var.project_id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.crossplane_vpc.id

  labels = {
    environment = "production"
    managed-by  = "terraform"
    purpose     = "crossplane-control-plane"
  }
}

# GKE Autopilot Cluster for Crossplane
# Autopilot is perfect for a management cluster because Google handles nodes
# and Workload Identity is enabled by default
resource "google_container_cluster" "crossplane_host" {
  name     = "crossplane-control-plane"
  project  = var.project_id
  location = var.region

  # Use Autopilot for zero-node-management
  enable_autopilot = true
  network          = google_compute_network.crossplane_vpc.name
  subnetwork       = google_compute_subnetwork.crossplane_subnet.name

  # Required for secure Crossplane-to-GCP communication via Workload Identity
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Resource labels for organization
  resource_labels = {
    environment = "production"
    managed-by  = "terraform"
    purpose     = "crossplane-control-plane"
  }

  deletion_protection = true

  depends_on = [
    google_compute_subnetwork.crossplane_subnet
  ]
}

# Workload Identity Binding
# Allow Crossplane's Kubernetes Service Account to impersonate the Terraform Cloud SA
# This creates the "Bridge" between Crossplane and GCP IAM
# Format: serviceAccount:[PROJECT_ID].svc.id.goog[[NAMESPACE]/[KSA_NAME]]
resource "google_service_account_iam_member" "crossplane_workload_identity" {
  service_account_id = google_service_account.tfc_infrastructure.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-default]"

  depends_on = [
    google_container_cluster.crossplane_host
  ]
}

# Output the cluster name and endpoint for kubectl configuration
output "crossplane_cluster_name" {
  description = "Name of the GKE cluster hosting Crossplane"
  value       = google_container_cluster.crossplane_host.name
}

output "crossplane_cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = google_container_cluster.crossplane_host.endpoint
}

output "crossplane_cluster_location" {
  description = "Location (region) of the GKE cluster"
  value       = google_container_cluster.crossplane_host.location
}

output "crossplane_gke_cluster_ca_certificate" {
  description = "Base64 encoded public certificate for the cluster"
  value       = google_container_cluster.crossplane_host.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

