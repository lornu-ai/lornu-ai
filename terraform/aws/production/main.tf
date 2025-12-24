terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  cloud {
    organization = "lornu-ai"

    workspaces {
      name = "lornu-ai-prod-aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
