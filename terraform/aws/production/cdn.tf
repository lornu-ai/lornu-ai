data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer" {
  name = "Managed-AllViewer"
}

# Query Kubernetes Ingress resource for ALB endpoint
# The ALB Controller provisions an ALB based on the Ingress configuration
# This data source retrieves the ALB's DNS name from the Ingress status
#
# CRITICAL DEPENDENCIES: This lookup has three key coupling points:
# 1. k8s_namespace_prefix: Terraform variable (default: "prod-")
# 2. namePrefix: From deployed Kustomize overlay (k8s/overlays/production/ uses "prod-")
# 3. Ingress base name: From k8s base manifests (currently "lornu-ai")
#
# Current composition: {k8s_namespace_prefix}{ingress_base_name}
#   = "prod-" + "lornu-ai" = "prod-lornu-ai"
#
# ⚠️  If ANY of these change, this lookup will FAIL:
#   • If k8s_namespace_prefix variable value changes
#   • If Kustomize overlay namePrefix changes
#   • If the base Ingress name in k8s/base/ingress.yaml changes
#   • If the overlay is changed to a different one (e.g., staging instead of production)
#
# To prevent lookup failures, keep all three components synchronized.
data "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.k8s_namespace_prefix}lornu-ai"
    namespace = "lornu-prod"
  }

  depends_on = [module.eks]
}

# Local variable for ALB origin domain with robust validation
# Handles both empty strings and whitespace-only values from Ingress status
#
# Primary: ALB provisioned by Kubernetes ALB Controller (auto-populated in Ingress status)
#   - Uses trimspace() to remove leading/trailing whitespace
#   - Ternary operator checks that trimmed value is not empty
#   - Returns null if empty or whitespace-only
#
# Secondary: Explicit alb_domain_name variable (useful for non-standard ALB setups or testing)
#   - Also normalized with trimspace() and ternary to handle operator input edge cases
#
# If both are unavailable (null), precondition will fail at terraform plan time
locals {
  ingress_hostname = try(
    trimspace(data.kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname) != "" ? trimspace(data.kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].hostname) : null,
    null
  )

  alb_origin_domain = coalesce(
    local.ingress_hostname,
    trimspace(var.alb_domain_name) != "" ? trimspace(var.alb_domain_name) : null
  )
}

# Precondition validation: Fail fast at terraform plan if ALB domain is not available
# This prevents applying CloudFront with an invalid origin domain.
# Operators will see this error during terraform plan, not during apply.
#
# Root causes for precondition failure:
# 1. Ingress status not yet populated by ALB Controller (wait for controller to provision ALB)
# 2. var.alb_domain_name not set and is empty/whitespace (explicitly provide ALB domain)
#
# Resolution:
# - Option 1: Wait for ALB Controller to populate Ingress status (automatic, no action needed)
# - Option 2: Set var.alb_domain_name to your ALB's DNS name (e.g., "k8s-lornu-xxx.elb.us-east-1.amazonaws.com")
resource "null_resource" "validate_alb_origin" {
  lifecycle {
    precondition {
      condition     = local.alb_origin_domain != null
      error_message = "ALB origin domain is not available. Either wait for ALB Controller to provision the ALB and populate Ingress status (automatic after EKS cluster is ready), or explicitly set var.alb_domain_name to your ALB's DNS name (e.g., 'k8s-lornu-xxx.elb.us-east-1.amazonaws.com')."
    }
  }
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


# Route53 Zone Management
# CloudFront-only architecture: All DNS records (apex and subdomains) point to CloudFront
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
  domain_name = var.api_domain != "" ? var.api_domain : var.domain_name
  validation_method = "DNS"

  # Use conditional to exclude empty strings from subject_alternative_names
  # Ensure both apex and API domains are covered by the certificate
  subject_alternative_names = var.api_domain != "" ? [var.domain_name, var.api_domain] : [var.domain_name]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = local.route53_zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  ttl     = 60
  records = [each.value.resource_record_value]

  depends_on = [aws_acm_certificate.cloudfront]
}

# Wait for ACM certificate validation to complete
resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_cert_validation : record.fqdn]
}

resource "aws_cloudfront_distribution" "api" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Lornu AI distribution"
  # Use compact() to remove empty strings from aliases list
  # Handles both: with api_domain (two aliases) and without (one alias)
  aliases             = compact([var.domain_name, var.api_domain])
  price_class         = "PriceClass_100"
  default_root_object = ""
  http_version        = "http2and3"

  depends_on = [aws_acm_certificate_validation.cloudfront, null_resource.validate_alb_origin]

  # Origin: ALB created by Kubernetes ALB Controller
  # The ALB Controller watches for Ingress resources and automatically provisions an ALB
  # The Ingress must be annotated with alb.ingress.kubernetes.io/certificate-arn to enable SSL
  #
  # Domain name resolution (defined in locals.alb_origin_domain):
  # 1. Kubernetes Ingress status (populated by ALB Controller after provisioning)
  # 2. var.alb_domain_name variable (for manual override or non-controller setups)
  # 3. Precondition validation ensures both #1 and #2 are evaluated before CloudFront is created
  #
  # If neither source provides a valid domain, the precondition will fail at terraform plan,
  # preventing CloudFront from being created with an invalid origin. This is safer than
  # allowing a placeholder value that would silently route traffic to nowhere.
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

# DNS Records for CloudFront-only Architecture
# All traffic for apex and API domains routes through CloudFront
# CHANGED: Previously dns.tf managed apex domain with ALB certificate validation (1h15m timeout)
# Now all DNS is managed here with CloudFront aliases (no validation delays)
# Using for_each to consolidate A and AAAA records and reduce code duplication

resource "aws_route53_record" "apex" {
  for_each = toset(["A", "AAAA"])

  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "api_cloudfront" {
  # Only create DNS records if api_domain is set (not empty)
  for_each = var.api_domain != "" ? toset(["A", "AAAA"]) : toset([])

  zone_id = local.route53_zone_id
  name    = var.api_domain
  type    = each.key

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}
