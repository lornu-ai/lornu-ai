terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
  }

  cloud {
    organization = "lornu-ai"
    workspaces {
      name = "aws-kustomize"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
