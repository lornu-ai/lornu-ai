module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "lornu-ai-production-cluster"
  cluster_version = "1.29"

  cluster_endpoint_public_access       = true
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id                   = aws_vpc.main.id
  subnet_ids               = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  control_plane_subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  # Fargate Profile configuration
  fargate_profiles = {
    lornu-ai = {
      name = "lornu-ai-production-profile"
      selectors = [
        {
          namespace = "lornu-ai"
        },
        {
          namespace = "kube-system"
        }
      ]
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "production"
    GithubRepo  = "lornu-ai"
  }
}

# OIDC Provider for IAM Roles for Service Accounts (IRSA) is handled by the module
