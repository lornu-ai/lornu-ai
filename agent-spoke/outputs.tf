output "project_id" {
  description = "The Agent Spoke project ID"
  value       = var.project_id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.agent_cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for the GKE cluster"
  value       = google_container_cluster.agent_cluster.endpoint
  sensitive   = true
}

output "artifact_registry_url" {
  description = "The URL for the Artifact Registry repository"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.agent_images.repository_id}"
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.agent_network.name
}

output "subnet_name" {
  description = "The name of the subnet"
  value       = google_compute_subnetwork.agent_subnet.name
}
