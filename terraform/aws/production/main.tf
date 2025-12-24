terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = var.tf_cloud_org

    workspaces {
      tags = ["prod", "aws"]
    }
  }
}

provider "aws" {
  region = var.aws_region
}
