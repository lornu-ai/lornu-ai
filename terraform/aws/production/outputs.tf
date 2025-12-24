output "cluster_name" {
  description = "Name of the ECS Cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_name" {
  description = "Name of the ECS Service"
  value       = aws_ecs_service.main.name
}

output "task_definition_arn" {
  description = "ARN of the Task Definition"
  value       = aws_ecs_task_definition.main.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution for api.lornu.ai"
  value       = aws_cloudfront_distribution.api.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.api.domain_name
}

output "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1)"
  value       = aws_acm_certificate.cloudfront.arn
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID used for api.lornu.ai"
  value       = local.route53_zone_id
}

output "db_cluster_endpoint" {
  description = "The cluster endpoint for the Aurora database"
  value       = aws_rds_cluster.main.endpoint
}

output "db_cluster_reader_endpoint" {
  description = "The cluster reader endpoint for the Aurora database"
  value       = aws_rds_cluster.main.reader_endpoint
}
