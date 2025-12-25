data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# S3 bucket for CloudFront access logs
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = "lornu-ai-cloudfront-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = {
    Name        = "lornu-ai-cloudfront-logs"
    Environment = "production"
    GithubRepo  = var.github_repo
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "current" {}


data "aws_route53_zone" "primary" {
  count        = var.create_route53_zone ? 0 : 1
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_zone" "primary" {
  count = var.create_route53_zone ? 1 : 0
  name  = var.route53_zone_name
}

locals {
  route53_zone_id = var.create_route53_zone ? aws_route53_zone.primary[0].zone_id : data.aws_route53_zone.primary[0].zone_id
}

resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us_east_1
  domain_name       = var.api_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = toset([var.api_domain])

  zone_id = local.route53_zone_id
  name    = one([for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.resource_record_name])
  type    = one([for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.resource_record_type])
  ttl     = 60
  records = [one([for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.resource_record_value])]

  depends_on = [aws_acm_certificate.cloudfront]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "api" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Lornu AI API distribution"
  aliases             = [var.api_domain]
  price_class         = "PriceClass_100"
  default_root_object = ""
  http_version        = "http2and3"

  depends_on = [aws_acm_certificate_validation.cloudfront]

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "alb-origin"

    viewer_protocol_policy   = "redirect-to-https"
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs.bucket_regional_domain_name
    prefix          = "cloudfront-logs"
  }

  web_acl_id = var.cloudfront_web_acl_id != "" ? var.cloudfront_web_acl_id : null
}

resource "aws_route53_record" "api_cloudfront" {
  zone_id = local.route53_zone_id
  name    = var.api_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_cloudfront_ipv6" {
  zone_id = local.route53_zone_id
  name    = var.api_domain
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}
