# --------------------------------------------------------------------------------
# AGENT SPOKE - App-specific infrastructure for AI Agent workloads
# --------------------------------------------------------------------------------
# This spoke project is managed by the Hub and contains:
# - GKE cluster for agent runtime
# - Artifact Registry for container images
# - Network infrastructure
# --------------------------------------------------------------------------------

terraform {
  cloud {
    organization = "lornu-ai"
    workspaces {
      name = "lornu-agent-spoke"
    }
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
}

# --------------------------------------------------------------------------------
# NETWORK
# --------------------------------------------------------------------------------

resource "google_compute_network" "agent_network" {
  name                    = "agent-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "agent_subnet" {
  name          = "agent-subnet"
  ip_cidr_range = "10.0.0.0/20"
  region        = var.region
  network       = google_compute_network.agent_network.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.4.0.0/14"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.8.0.0/20"
  }
}

# --------------------------------------------------------------------------------
# ARTIFACT REGISTRY
# --------------------------------------------------------------------------------

resource "google_artifact_registry_repository" "agent_images" {
  location      = var.region
  repository_id = "agent-images"
  description   = "Container images for Lornu AI Agents"
  format        = "DOCKER"

  labels = {
    "lornu-ai-managed-by"  = "terraform-cloud"
    "lornu-ai-environment" = "production"
    "lornu-ai-spoke-type"  = "agent"
  }
}

# --------------------------------------------------------------------------------
# GKE CLUSTER
# --------------------------------------------------------------------------------

resource "google_container_cluster" "agent_cluster" {
  name     = "agent-cluster"
  location = var.region

  # Use VPC-native cluster
  network    = google_compute_network.agent_network.name
  subnetwork = google_compute_subnetwork.agent_subnet.name

  # Remove default node pool, we'll create our own
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Workload Identity for secure pod authentication
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Enable network policy
  network_policy {
    enabled = true
  }

  # Release channel for automatic upgrades
  release_channel {
    channel = "REGULAR"
  }

  resource_labels = {
    "lornu-ai-managed-by"  = "terraform-cloud"
    "lornu-ai-environment" = "production"
    "lornu-ai-spoke-type"  = "agent"
  }
}

resource "google_container_node_pool" "agent_nodes" {
  name       = "agent-nodes"
  location   = var.region
  cluster    = google_container_cluster.agent_cluster.name
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type

    # Use Workload Identity
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      "lornu-ai-spoke-type" = "agent"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
