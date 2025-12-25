variable "organization" {
  description = "The TFC organization name"
  type        = string
  default     = "lornu-ai"
}

variable "github_repository" {
  description = "The GitHub repository for VCS integration"
  type        = string
  default     = "lornu-ai/lornu-ai"
}

variable "github_oauth_token_id" {
  description = "The OAuth Token ID for GitHub integration in TFC"
  type        = string
  default     = "" # Should be provided via TFC variable
}

variable "aws_environments" {
  description = "Map of AWS environments to manage"
  type = map(object({
    workspace_name = string
    auto_apply     = bool
    environment    = string # staging, production
    vcs_repo_path  = string # path within the repo
    aws_region     = string
    role_arn       = string
  }))
  default = {
    staging = {
      workspace_name = "lornu-ai-staging-aws"
      auto_apply     = true
      environment    = "staging"
      vcs_repo_path  = "terraform/aws/environments/staging"
      aws_region     = "us-east-2"
      role_arn       = "arn:aws:iam::123456789012:role/lornu-ai-staging-tfc-role" # Placeholder or to be updated
    },
    production = {
      workspace_name = "lornu-ai-prod-aws"
      auto_apply     = false
      environment    = "production"
      vcs_repo_path  = "terraform/aws/environments/production"
      aws_region     = "us-east-2"
      role_arn       = "arn:aws:iam::123456789012:role/lornu-ai-production-tfc-role" # Placeholder or to be updated
    }
  }
}

variable "global_variables" {
  description = "Global variables to apply to all workspaces"
  type        = map(string)
  default = {
    COST_CENTER = "Lornu-AI-R&D"
  }
}
