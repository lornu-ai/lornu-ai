terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "disposable-org"
    workspaces {
      name = "lornu-ai-staging-aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
