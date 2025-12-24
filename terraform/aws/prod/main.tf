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
      name = "lornu-ai-staging-aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
