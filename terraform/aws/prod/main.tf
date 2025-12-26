terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.27"
    }
  }

  cloud {
    # Organization and workspace are set via environment variables:
    # TF_CLOUD_ORGANIZATION and TF_WORKSPACE (from GitHub secrets)
  }
}

provider "aws" {
  region = var.aws_region
}
