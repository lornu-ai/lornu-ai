# Terraform Cloud OIDC federation for Dynamic Provider Credentials
# Eliminates static AWS credentials in TFC workspaces
# Reference: https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration

# TLS certificate for OIDC provider verification
data "tls_certificate" "tfc" {
  url = "https://app.terraform.io"
}

# OIDC provider for Terraform Cloud
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = [data.tls_certificate.tfc.certificates[0].sha1_fingerprint]

  tags = {
    Name                   = "terraform-cloud-oidc"
    Environment            = "production"
    "lornu.ai/managed-by"  = "terraform-cloud"
    "lornu.ai/environment" = "production"
    "lornu.ai/asset-id"    = "lornu-ai-final-clear-bg"
  }
}

# IAM role that Terraform Cloud assumes via OIDC
resource "aws_iam_role" "tfc_oidc" {
  name = "terraform-cloud-oidc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.tfc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
          StringLike = {
            # Scoped to lornu-ai organization, aws-kustomize workspace
            # run_phase:* allows both plan and apply operations
            "app.terraform.io:sub" = "organization:lornu-ai:project:*:workspace:aws-kustomize:run_phase:*"
          }
        }
      }
    ]
  })

  tags = {
    Name                   = "terraform-cloud-oidc-role"
    Environment            = "production"
    "lornu.ai/managed-by"  = "terraform-cloud"
    "lornu.ai/environment" = "production"
    "lornu.ai/asset-id"    = "lornu-ai-final-clear-bg"
  }
}

# Policy for Terraform Cloud to manage AWS infrastructure
# Mirrors the permissions from github_terraform_aws policy for consistency
# Note: Broad permissions (iam:*, kms:*) are required for Terraform Cloud to manage
# infrastructure resources including IAM roles, policies, OIDC providers, and KMS keys.
# The trust policy restricts this role to only be assumable by the aws-kustomize workspace
# in the lornu-ai organization, providing an additional security boundary.
resource "aws_iam_policy" "tfc_infrastructure" {
  name        = "terraform-cloud-infrastructure"
  description = "Allow Terraform Cloud to manage AWS infrastructure via Dynamic Provider Credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformInfrastructureManagement"
        Effect = "Allow"
        Action = [
          # VPC and Networking
          "ec2:*",
          # Container Services
          "ecs:*",
          "ecr:*",
          "eks:*",
          # IAM (for roles, policies, OIDC providers)
          # Restricted to specific actions needed for infrastructure management
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:ListPolicies",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
          "iam:SetDefaultPolicyVersion",
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:TagPolicy",
          "iam:UntagPolicy",
          "iam:ListPolicyTags",
          "iam:PassRole",
          # Logging
          "logs:*",
          # Load Balancing
          "elasticloadbalancing:*",
          # Auto Scaling
          "autoscaling:*",
          # Encryption (KMS keys for EBS volumes, RDS, etc.)
          # Restricted to key management operations, not key usage
          "kms:CreateKey",
          "kms:DeleteKey",
          "kms:DescribeKey",
          "kms:ListKeys",
          "kms:ListAliases",
          "kms:UpdateKeyDescription",
          "kms:EnableKey",
          "kms:DisableKey",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ListResourceTags",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:UpdateAlias",
          "kms:PutKeyPolicy",
          "kms:GetKeyPolicy",
          "kms:ListKeyPolicies",
          # Secrets (read for runtime, write for Terraform management)
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets",
          "secretsmanager:CreateSecret",
          "secretsmanager:UpdateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:TagResource",
          # Database
          "rds:*",
          # CDN
          "cloudfront:*",
          # DNS
          "route53:*",
          # WAF
          "wafv2:*",
          # Certificates
          "acm:*",
          # STS for role chaining if needed
          "sts:GetCallerIdentity",
        ]
        Resource = "*"
      },
      {
        Sid    = "TerraformStateS3"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation",
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-*",
          "arn:aws:s3:::terraform-state-*/*",
        ]
      },
      {
        Sid    = "TerraformStateDynamoDB"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
        ]
        Resource = "arn:aws:dynamodb:*:*:table/terraform-*"
      },
    ]
  })

  tags = {
    Name                   = "terraform-cloud-infrastructure"
    Environment            = "production"
    "lornu.ai/managed-by"  = "terraform-cloud"
    "lornu.ai/environment" = "production"
    "lornu.ai/asset-id"    = "lornu-ai-final-clear-bg"
  }
}

resource "aws_iam_role_policy_attachment" "tfc_infrastructure" {
  role       = aws_iam_role.tfc_oidc.name
  policy_arn = aws_iam_policy.tfc_infrastructure.arn
}

# Outputs for TFC workspace configuration
output "tfc_oidc_provider_arn" {
  description = "ARN of the Terraform Cloud OIDC provider"
  value       = aws_iam_openid_connect_provider.tfc.arn
}

output "tfc_oidc_role_arn" {
  description = "ARN of the IAM role for Terraform Cloud Dynamic Provider Credentials"
  value       = aws_iam_role.tfc_oidc.arn
}

output "tfc_oidc_role_name" {
  description = "Name of the IAM role for Terraform Cloud"
  value       = aws_iam_role.tfc_oidc.name
}
