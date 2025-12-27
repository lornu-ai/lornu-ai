# Crossplane Workload Identity Setup
# This creates the "Bridge" between Crossplane (running on existing GKE cluster)
# and GCP IAM, allowing Crossplane to create new GCP projects (the "eggs")
#
# Note: We use the EXISTING GKE cluster (lornu-ai-gke) to run Crossplane (the "chicken")
# Crossplane will then create new GCP projects via the XGCPProject Composition

# Workload Identity Binding
# Allow Crossplane's Kubernetes Service Account (on existing GKE cluster) 
# to impersonate the Terraform Cloud SA
# This creates the "Bridge" between Crossplane and GCP IAM
# Format: serviceAccount:[PROJECT_ID].svc.id.goog[[NAMESPACE]/[KSA_NAME]]
#
# Note: This assumes Crossplane is installed on the existing GKE cluster (lornu-ai-gke)
# The cluster must have Workload Identity enabled (which it should already have)
resource "google_service_account_iam_member" "crossplane_workload_identity" {
  service_account_id = google_service_account.tfc_infrastructure.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-default]"
}

# Outputs for Crossplane setup
# Note: These reference the existing GKE cluster, not a newly created one
output "crossplane_cluster_name" {
  description = "Name of the existing GKE cluster where Crossplane will run"
  value       = var.cluster_name # Uses existing cluster: lornu-ai-gke
}

output "crossplane_workload_identity_binding" {
  description = "Workload Identity binding member for Crossplane"
  value       = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp-default]"
}

