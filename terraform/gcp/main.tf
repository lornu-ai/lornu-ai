terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.14"
    }
  }

  cloud {
    organization = "lornu-ai"
    workspaces {
      name = "gcp-lornu-ai"
    }
  }
}

provider "google" {
  credentials = var.GOOGLE_CREDENTIALS != null ? jsondecode(var.GOOGLE_CREDENTIALS) : null
  project     = var.project_id
  region      = var.region
}
