resource "aws_route53_zone" "main" {
  name = "lornu.ai"

  tags = {
    Name        = "lornu-ai-prod-zone"
    Environment = "production"
  }
}

resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "lornu.ai"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.lornu.ai"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

output "nameservers" {
  description = "Nameservers for lornu.ai - update these at your domain registrar"
  value       = aws_route53_zone.main.name_servers
}

output "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = aws_route53_zone.main.zone_id
}
