terraform {
  cloud {
    organization = "lornu-ai"
    workspaces {
      name = "lornu-ai-hub"
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
  project = var.hub_project_id
}

# --------------------------------------------------------------------------------
# WORKLOAD IDENTITY POOL (Now renamed to tfc_pool to match reality)
# --------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "tfc_pool" {
  workload_identity_pool_id = "tfc-pool"
  display_name              = "TFC Pool"
}

# --------------------------------------------------------------------------------
# PROVIDER: HCP TERRAFORM (TFC)
# --------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.tfc_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "tfc-provider"
  display_name                       = "HCP Terraform Provider"

  attribute_mapping = {
    "google.subject"                        = "assertion.sub"
    "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name"
    "attribute.terraform_organization_name" = "assertion.terraform_organization_name"
  }

  oidc {
    issuer_uri = "https://app.terraform.io"
  }

  # This matches the "dummy condition" we used to bypass the gcloud CLI bug
  attribute_condition = "assertion.sub != 'foo'"
}