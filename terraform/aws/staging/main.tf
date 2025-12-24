terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    workspaces {
      name = "lornu-ai-staging-aws"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.resource_prefix
      ManagedBy = "Terraform"
      Repo      = var.github_repo
    }
  }
}
