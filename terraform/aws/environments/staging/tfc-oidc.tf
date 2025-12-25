# Terraform Cloud OIDC federation for staging
# Enables TFC to authenticate to AWS via OIDC for passwordless provisioning

data "aws_iam_openid_connect_provider" "tfc" {
  url = "https://app.terraform.io"
}

resource "aws_iam_role" "tfc_role" {
  name = "lornu-ai-staging-tfc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.tfc.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
          StringLike = {
            "app.terraform.io:sub" = "organization:lornu-ai:project:*:workspace:lornu-ai-staging:run_phase:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "tfc-staging-role"
    Environment = "staging"
    ManagedBy   = "terraform"
  }
}

# Attach the same permissions as GitHub Actions for Terraform
resource "aws_iam_role_policy_attachment" "tfc_terraform_aws" {
  role       = aws_iam_role.tfc_role.name
  policy_arn = aws_iam_policy.github_terraform_aws.arn
}

output "tfc_role_arn" {
  description = "ARN of the IAM role for Terraform Cloud"
  value       = aws_iam_role.tfc_role.arn
}
