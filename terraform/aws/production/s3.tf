# S3 bucket for application assets (images, static files, brand assets)
resource "aws_s3_bucket" "assets" {
  bucket              = "lornu-ai-assets-${data.aws_caller_identity.current.account_id}"
  force_destroy       = false
  object_lock_enabled = false

  tags = {
    Name        = "lornu-ai-assets"
    Environment = "production"
    Purpose     = "Application assets and branding"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning for asset rollback capability
resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}

# Block public access to assets by default (CloudFront will serve)
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption for assets
resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CORS configuration for assets (allow frontend to fetch assets)
resource "aws_s3_bucket_cors_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["https://*.lornu.ai", "https://lornu.ai"]
    expose_headers  = ["ETag", "x-amz-version-id"]
    max_age_seconds = 3000
  }
}

# Lifecycle policy to manage asset versions
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Output the bucket name for deployment
output "assets_bucket" {
  description = "S3 bucket name for application assets"
  value       = aws_s3_bucket.assets.id
}

output "assets_bucket_region" {
  description = "Region of the assets bucket"
  value       = aws_s3_bucket.assets.region
}
