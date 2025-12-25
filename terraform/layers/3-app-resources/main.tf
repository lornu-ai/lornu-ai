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
      name = "lornu-ai-app-resources"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Read state from Networking Layer
data "terraform_remote_state" "networking" {
  backend = "remote"

  config = {
    organization = "lornu-ai"
    workspaces = {
      name = "lornu-ai-networking"
    }
  }
}

# Read state from Cluster Layer
data "terraform_remote_state" "cluster" {
  backend = "remote"

  config = {
    organization = "lornu-ai"
    workspaces = {
      name = "lornu-ai-cluster"
    }
  }
}

locals {
  vpc_id          = data.terraform_remote_state.networking.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.networking.outputs.public_subnets
  private_subnets = data.terraform_remote_state.networking.outputs.private_subnets
  oidc_provider_arn = data.terraform_remote_state.cluster.outputs.oidc_provider_arn
}
