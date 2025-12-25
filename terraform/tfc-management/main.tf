terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.50.0"
    }
  }

  cloud {
    organization = "lornu-ai"

    workspaces {
      name = "lornu-ai-management"
    }
  }
}

provider "tfe" {
  # Token should be provided via TFC_TOKEN environment variable in TFC
}
