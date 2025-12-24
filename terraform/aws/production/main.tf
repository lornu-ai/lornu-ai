terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "lornu-ai"

    workspaces {
      tags = ["prod", "aws"]
    }
  }
}

provider "aws" {
  region = var.aws_region
}
