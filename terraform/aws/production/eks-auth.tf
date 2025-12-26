# EKS aws-auth ConfigMap Management
# NOTE: GitHub Actions access is now managed via access_entries in eks.tf (modern approach)
# This file only manages node role mappings for worker nodes

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
          rolearn  = module.lornu_cluster.worker_iam_role_arn
          username = "system:node:{{EC2PrivateDNSName}}"
          groups   = ["system:bootstrappers", "system:nodes"]
        }
        # GitHub Actions access is managed via access_entries in eks.tf
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
        rolearn  = module.lornu_cluster.worker_iam_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      }
      # GitHub Actions access is managed via access_entries in eks.tf
    ])
  }

  depends_on = [
    module.lornu_cluster
  ]
}
