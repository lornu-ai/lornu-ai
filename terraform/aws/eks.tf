module "lornu_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.10"

  name               = "lornu-ai-production-cluster"
  kubernetes_version = "1.29"

  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = ["0.0.0.0/0"]

  enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id                   = aws_vpc.lornu_vpc.id
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
          namespace = "lornu-dev"
        },
        {
          namespace = "lornu-staging"
        },
        {
          namespace = "lornu-prod"
        },
        {
          namespace = "kube-system"
        },
        {
          namespace = "external-secrets"
        }
      ]
    }
  }

  enable_cluster_creator_admin_permissions = true

  access_entries = {
    # Allow GitHub Actions to deploy to the cluster
    github_actions = {
      principal_arn = aws_iam_role.github_actions.arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  tags = {
    Environment = "production"
    GithubRepo  = "lornu-ai"
  }
}

# OIDC Provider for IAM Roles for Service Accounts (IRSA) is handled by the module
