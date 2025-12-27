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
# WORKLOAD IDENTITY POOL
# --------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "Lornu-AI Multi-Platform Pool"
}

# --------------------------------------------------------------------------------
# PROVIDER 1: GITHUB ACTIONS
# --------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
  }

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  attribute_condition = "assertion.repository == \"${var.github_repo}\""
}

# --------------------------------------------------------------------------------
# PROVIDER 2: HCP TERRAFORM (TFC)
# --------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool_provider" "tfc_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "terraform-cloud-provider"
  display_name                       = "HCP Terraform Provider"

  attribute_mapping = {
    "google.subject"                        = "assertion.sub"
    "attribute.terraform_workspace_name"    = "assertion.terraform_workspace_name"
    "attribute.terraform_organization_name" = "assertion.terraform_organization_name"
  }

  oidc {
    issuer_uri = "https://app.terraform.io"
  }
}