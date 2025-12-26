# =============================================================================
# TWO-STAGE DEPLOYMENT FOR ACM CERTIFICATE
# =============================================================================
#
# Stage 1 (deploy_stage >= 1): Route53 zone + ACM certificate + DNS validation
#   - Creates Route53 hosted zone (if create_route53_zone = true)
#   - Creates ACM certificate with DNS validation
#   - Creates DNS CNAME records for certificate validation
#   - Waits for certificate to be issued (5-15 minutes)
#
# Stage 2 (deploy_stage >= 2): CloudFront + Route53 alias records
#   - Creates CloudFront distribution using validated certificate
#   - Creates Route53 A/AAAA records pointing to CloudFront
#   - Requires Stage 1 to be complete (certificate must be ISSUED)
#
# Usage:
#   Stage 1: terraform apply -var="deploy_stage=1"
#   Stage 2: terraform apply -var="deploy_stage=2" (after Stage 1 completes)
#
# =============================================================================

# -----------------------------------------------------------------------------
# STAGE 1: Route53 Zone
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# STAGE 1: ACM Certificate + DNS Validation (skipped if existing cert provided)
# -----------------------------------------------------------------------------

# Only create certificate if no existing certificate ARN is provided
resource "aws_acm_certificate" "cloudfront" {
  count             = var.existing_acm_certificate_arn == "" ? 1 : 0
  provider          = aws.us_east_1
  domain_name       = var.api_domain != "" ? var.api_domain : var.domain_name
  validation_method = "DNS"

  subject_alternative_names = distinct(compact(concat([var.domain_name, var.api_domain], var.extra_domain_names)))

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "lornu-ai-cloudfront-cert"
    Environment = "production"
    Stage       = "1"
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = var.existing_acm_certificate_arn == "" ? {
    for dvo in aws_acm_certificate.cloudfront[0].domain_validation_options : dvo.domain_name => dvo
  } : {}

  zone_id = local.route53_zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]

  depends_on = [aws_acm_certificate.cloudfront]
}

resource "aws_acm_certificate_validation" "cloudfront" {
  count                   = var.existing_acm_certificate_arn == "" ? 1 : 0
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]

  timeouts {
    create = "45m"
  }
}

locals {
  # Use existing certificate ARN if provided, otherwise use the created one
  acm_certificate_arn = var.existing_acm_certificate_arn != "" ? var.existing_acm_certificate_arn : try(aws_acm_certificate.cloudfront[0].arn, "")
}

# -----------------------------------------------------------------------------
# STAGE 2: CloudFront Prerequisites (Data Sources & Validation)
# -----------------------------------------------------------------------------

data "aws_cloudfront_cache_policy" "caching_disabled" {
  count = var.deploy_stage >= 2 ? 1 : 0
  name  = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  count = var.deploy_stage >= 2 ? 1 : 0
  name  = "Managed-AllViewer"
}

data "kubernetes_ingress_v1" "app" {
  count = var.deploy_stage >= 2 ? 1 : 0

  metadata {
    # Kustomize overlays no longer use namePrefix, so Ingress is just "lornu-ai"
    name      = "lornu-ai"
    namespace = "lornu-prod"
  }

  depends_on = [module.lornu_cluster]
}

locals {
  # Only compute these when in stage 2
  ingress_hostname = var.deploy_stage >= 2 ? try(
    trimspace(data.kubernetes_ingress_v1.app[0].status[0].load_balancer[0].ingress[0].hostname) != "" ? trimspace(data.kubernetes_ingress_v1.app[0].status[0].load_balancer[0].ingress[0].hostname) : null,
    null
  ) : null

  alb_origin_domain = var.deploy_stage >= 2 ? coalesce(
    local.ingress_hostname,
    trimspace(var.alb_domain_name) != "" ? trimspace(var.alb_domain_name) : null
  ) : null
}

resource "null_resource" "validate_alb_origin" {
  count = var.deploy_stage >= 2 ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.alb_origin_domain != null
      error_message = "ALB origin domain is not available. Either wait for ALB Controller to provision the ALB and populate Ingress status, or explicitly set var.alb_domain_name."
    }
  }
}

# -----------------------------------------------------------------------------
# STAGE 2: S3 Bucket for CloudFront Logs
# -----------------------------------------------------------------------------

# Note: aws_caller_identity.current is defined in eks-auth.tf

resource "aws_s3_bucket" "cloudfront_logs" {
  count         = var.deploy_stage >= 2 ? 1 : 0
  bucket        = "lornu-ai-cloudfront-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = false

  tags = {
    Name        = "lornu-ai-cloudfront-logs"
    Environment = "production"
    Stage       = "2"
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  count  = var.deploy_stage >= 2 ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  count  = var.deploy_stage >= 2 ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  count  = var.deploy_stage >= 2 ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# STAGE 2: CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "api" {
  count = var.deploy_stage >= 2 ? 1 : 0

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Lornu AI distribution"
  aliases             = distinct(compact(concat([var.domain_name, var.api_domain], var.extra_domain_names)))
  price_class         = "PriceClass_100"
  default_root_object = ""
  http_version        = "http2and3"

  # Only depend on certificate validation if we're creating a new certificate
  depends_on = [null_resource.validate_alb_origin]

  origin {
    domain_name = local.alb_origin_domain
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
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled[0].id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer[0].id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = local.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_regional_domain_name
    prefix          = "cloudfront-logs"
  }

  web_acl_id = var.cloudfront_web_acl_id != "" ? var.cloudfront_web_acl_id : null
}

# -----------------------------------------------------------------------------
# STAGE 2: Route53 Alias Records (pointing to CloudFront)
# -----------------------------------------------------------------------------

resource "aws_route53_record" "apex" {
  for_each = var.deploy_stage >= 2 ? toset(["A", "AAAA"]) : toset([])

  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.api[0].domain_name
    zone_id                = aws_cloudfront_distribution.api[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_cloudfront" {
  for_each = var.deploy_stage >= 2 && var.api_domain != "" ? toset(["A", "AAAA"]) : toset([])

  zone_id = local.route53_zone_id
  name    = var.api_domain
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.api[0].domain_name
    zone_id                = aws_cloudfront_distribution.api[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "extra_cloudfront" {
  for_each = var.deploy_stage >= 2 ? {
    for pair in setproduct(var.extra_domain_names, ["A", "AAAA"]) :
    "${pair[0]}-${pair[1]}" => {
      name = pair[0]
      type = pair[1]
    }
  } : {}

  zone_id = local.route53_zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = aws_cloudfront_distribution.api[0].domain_name
    zone_id                = aws_cloudfront_distribution.api[0].hosted_zone_id
    evaluate_target_health = false
  }
}
