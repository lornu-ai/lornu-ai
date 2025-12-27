output "hub_project_id" {
  description = "The ID of the Master Hub Project"
  value       = var.hub_project_id
}

output "workload_identity_provider" {
  description = "The full identifier of the OIDC provider"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "terraform_admin_sa_email" {
  description = "The email of the SA used for spawning Spokes"
  value       = google_service_account.hub_admin_sa.email
}