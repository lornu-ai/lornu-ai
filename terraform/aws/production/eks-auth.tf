# EKS aws-auth ConfigMap Management
# Allows GitHub Actions OIDC role and other IAM roles to access the cluster

locals {
  aws_auth_configmap_yaml = yamlencode({
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "aws-auth"
      namespace = "kube-system"
    }
    data = {
      mapRoles = yamlencode([
        {
          rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
          username = "system:bootstrap"
          groups   = ["system:bootstrappers", "system:nodes"]
        },
        {
          rolearn  = module.eks.worker_iam_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        },
        {
          # GitHub Actions OIDC Role - allows GHA to deploy to the cluster
          rolearn  = var.github_actions_role_arn
          username = "github-actions"
          groups   = ["system:masters"]  # Full access for deployments (can be restricted to specific namespaces)
        }
      ])
      mapUsers = yamlencode([
        # Add additional IAM users here if needed
      ])
    }
  })
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Create/update the aws-auth ConfigMap using kubectl
resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = yamlencode([
      {
        rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS"
        username = "system:bootstrap"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = module.eks.worker_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        # GitHub Actions OIDC Role - allows GHA to deploy to the cluster
        rolearn  = var.github_actions_role_arn
        username = "github-actions"
        groups   = ["system:masters"]  # Full access for deployments
      }
    ])
  }

  depends_on = [
    module.eks
  ]
}

# Output the aws-auth entry for reference
output "github_actions_aws_auth_entry" {
  description = "The aws-auth ConfigMap entry for GitHub Actions OIDC role"
  value = {
    rolearn  = var.github_actions_role_arn
    username = "github-actions"
    groups   = ["system:masters"]
  }
}
