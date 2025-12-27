# Artifact Registry for Docker images
# This replaces Google Container Registry (GCR) as the recommended solution

resource "google_artifact_registry_repository" "docker_repo" {
  location      = var.region
  repository_id = "lornu-ai"
  description   = "Docker repository for Lornu AI application images"
  format        = "DOCKER"

  labels = {
    "lornu.ai/environment" = "production"
    "lornu.ai/managed-by"  = "terraform-cloud"
    "lornu.ai/asset-id"    = "lornu-ai-final-clear-bg"
    purpose                = "container-images"
  }
}

# IAM binding to allow the GitHub Actions service account to push images
resource "google_artifact_registry_repository_iam_member" "github_actions_writer" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.github_actions.email}"
}

# Allow GKE nodes to pull images
resource "google_artifact_registry_repository_iam_member" "gke_reader" {
  project    = var.project_id
  location   = google_artifact_registry_repository.docker_repo.location
  repository = google_artifact_registry_repository.docker_repo.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_nodes.email}"
}

# Output the repository URL for use in CI/CD
output "docker_repository_url" {
  description = "The URL of the Docker repository"
  value       = "${google_artifact_registry_repository.docker_repo.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker_repo.repository_id}"
}