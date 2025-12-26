# Get the Route53 hosted zone
data "aws_route53_zone" "main" {
  name = var.route53_zone_name
}

# Create Route53 record for staging domain pointing to ALB
resource "aws_route53_record" "staging_alb" {
  count   = var.stage_domain != "" ? 1 : 0
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.stage_domain
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

output "staging_domain" {
  description = "Staging domain name"
  value       = var.stage_domain
}

output "staging_url" {
  description = "Full staging URL"
  value       = var.stage_domain != "" ? "https://${var.stage_domain}" : aws_lb.main.dns_name
}
