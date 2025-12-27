# Meta-Terraform: Terraform Cloud Management Workspace
# This workspace manages TFC configuration, variable injection, and GitHub secrets
# Reference: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials

terraform {
  required_version = ">= 1.6"

  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }

  cloud {
    organization = "lornu-ai"
    workspaces {
      name = "tfc-management"
    }
  }
}

# TFE provider uses TFE_TOKEN environment variable
provider "tfe" {
  organization = var.tfc_organization
}

# GitHub provider uses GITHUB_TOKEN environment variable
provider "github" {
  owner = var.github_owner
}
