# DynamoDB table for rate limiting (RATE_LIMIT_KV)
# Stores rate limit counters per IP address or user ID
resource "aws_dynamodb_table" "rate_limit_kv" {
  name             = "lornu-ai-rate-limit-kv"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "key"
  stream_enabled   = false
  deletion_protection = true

  attribute {
    name = "key"
    type = "S"
  }

  tags = {
    Name        = "lornu-ai-rate-limit-kv"
    Environment = "production"
    Purpose     = "Rate limiting key-value store"
    ManagedBy   = "Terraform"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# DynamoDB table for general KV store (caching, sessions, etc.)
resource "aws_dynamodb_table" "general_kv" {
  name             = "lornu-ai-general-kv"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "key"
  stream_enabled   = false
  deletion_protection = true

  attribute {
    name = "key"
    type = "S"
  }

  tags = {
    Name        = "lornu-ai-general-kv"
    Environment = "production"
    Purpose     = "General-purpose key-value store for caching and sessions"
    ManagedBy   = "Terraform"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# IAM role for application to access DynamoDB
resource "aws_iam_role" "app_dynamodb" {
  name = "lornu-ai-app-dynamodb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:lornu-prod:lornu-ai"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "lornu-ai-app-dynamodb-role"
    ManagedBy = "Terraform"
  }
}

# IAM policy for DynamoDB access
resource "aws_iam_role_policy" "app_dynamodb" {
  name = "lornu-ai-app-dynamodb-policy"
  role = aws_iam_role.app_dynamodb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchGetItem",
          "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.rate_limit_kv.arn,
          aws_dynamodb_table.general_kv.arn
        ]
      }
    ]
  })
}

# Output table names for deployment
output "rate_limit_table" {
  description = "DynamoDB table name for rate limiting"
  value       = aws_dynamodb_table.rate_limit_kv.name
}

output "general_kv_table" {
  description = "DynamoDB table name for general KV operations"
  value       = aws_dynamodb_table.general_kv.name
}

output "app_dynamodb_role_arn" {
  description = "IAM role ARN for application DynamoDB access"
  value       = aws_iam_role.app_dynamodb.arn
}
