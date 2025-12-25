# ACM Certificate for the ALB (Regional, not US-East-1)
resource "aws_acm_certificate" "main" {
  domain_name       = var.api_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "lornu-ai-production-alb-cert"
    Environment = "production"
    GithubRepo  = var.github_repo
  }
}

resource "aws_route53_record" "cert_validation" {
  zone_id = local.route53_zone_id
  name    = one([for dvo in aws_acm_certificate.main.domain_validation_options : dvo.resource_record_name])
  type    = one([for dvo in aws_acm_certificate.main.domain_validation_options : dvo.resource_record_type])
  ttl     = 60
  records = [one([for dvo in aws_acm_certificate.main.domain_validation_options : dvo.resource_record_value])]

  depends_on = [aws_acm_certificate.main]
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}
