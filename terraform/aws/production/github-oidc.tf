# GitHub Actions OIDC federation for production CI/CD
# Same as staging, but scoped to production deployments

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-prod"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:lornu-ai/lornu-ai:ref:refs/heads/main",
              "repo:lornu-ai/lornu-ai:pull_request",
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "github-actions-prod"
    Environment = "production"
  }
}

resource "aws_iam_policy" "github_ecr_push" {
  name        = "github-actions-prod-ecr-push"
  description = "Allow GitHub Actions to push images to prod ECR"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetAuthorizationToken",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_ecr_push.arn
}

resource "aws_iam_policy" "github_terraform_aws" {
  name        = "github-actions-prod-terraform-aws"
  description = "Allow GitHub Actions to apply production Terraform configurations"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformReadWrite"
        Effect = "Allow"
        Action = [
          "ec2:*",
          "ecs:*",
          "ecr:*",
          "iam:*",
          "logs:*",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "kms:*",
          "secretsmanager:GetSecretValue",
          "eks:*",
          "rds:*",
          "cloudfront:*",
          "route53:*",
          "wafv2:*",
          "acm:*",
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-*",
          "arn:aws:s3:::terraform-state-*/*",
        ]
      },
      {
        Sid    = "AllowDynamoDBStateLock"
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
}

resource "aws_iam_role_policy_attachment" "github_terraform_aws" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_terraform_aws.arn
}

output "github_actions_role_arn" {
  description = "ARN of the production GitHub Actions role for CI/CD"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the production GitHub Actions role"
  value       = aws_iam_role.github_actions.name
}
