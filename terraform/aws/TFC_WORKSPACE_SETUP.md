# Terraform Cloud Variables for aws-kustomize workspace
# Add these environment variables to the TFC workspace:
# 
# Required (from GitHub Secrets):
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_DEFAULT_REGION=us-east-1
#
# Optional (Terraform variables):
# - domain_name=lornu.ai
# - route53_zone_name=lornu.ai
# - create_route53_zone=false
# - environment=production
# - cluster_name=lornu-ai-eks-production
# - cluster_version=1.29

# Example locals (if needed, add to main.tf):
# locals {
#   workspace = terraform.workspace
#   environment = var.environment
#   tags = {
#     Workspace   = local.workspace
#     Environment = local.environment
#     ManagedBy   = "terraform-cloud"
#     Repository  = "lornu-ai"
#     Branch      = "main"
#   }
# }
