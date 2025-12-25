# This file serves as the environment map for Lornu AI fleet management.
# Adding a new environment here will trigger GHA to provision a corresponding TFC workspace.

organization = "lornu-ai"

aws_environments = {
  "staging-aws" = {
    workspace_name = "lornu-ai-staging-aws"
    auto_apply     = true
    environment    = "staging"
    vcs_repo_path  = "terraform/aws/environments/staging-aws"
    aws_region     = "us-east-2"
    role_arn       = "arn:aws:iam::702555543026:role/lornu-ai-staging-tfc-role"
  },
  "prod-aws" = {
    workspace_name = "lornu-ai-prod-aws"
    auto_apply     = false
    environment    = "production"
    vcs_repo_path  = "terraform/aws/environments/prod-aws"
    aws_region     = "us-east-2"
    role_arn       = "arn:aws:iam::702555543026:role/lornu-ai-production-tfc-role"
  }
}

global_variables = {
  COST_CENTER      = "Lornu-AI-R&D"
  ENVIRONMENT_TYPE = "managed"
}
