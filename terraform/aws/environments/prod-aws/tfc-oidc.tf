# Terraform Cloud OIDC federation
# Enables TFC to authenticate to AWS via OIDC for passwordless provisioning

resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

resource "aws_iam_role" "tfc_role" {
  name = "lornu-ai-production-tfc-role"

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
            "app.terraform.io:sub" = "organization:lornu-ai:project:*:workspace:lornu-ai-prod-aws:run_phase:*"
          }
        }
      }
    ]
  })

  tags = {
    Name        = "tfc-production-role"
    Environment = "production"
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
