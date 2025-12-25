output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cloudfront_distribution_id" {
  description = "The ID of the main CloudFront distribution."
  value       = aws_cloudfront_distribution.main.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_certificate_arn" {
  description = "ACM certificate ARN for CloudFront (us-east-1)"
  value       = aws_acm_certificate.cloudfront.arn
}

output "alb_certificate_arn" {
  description = "ACM certificate ARN for ALB (us-east-2)"
  value       = aws_acm_certificate.alb.arn
}

output "route53_zone_id" {
  description = "Route53 hosted zone ID used for the domain"
  value       = local.route53_zone_id
}

output "alb_dns_name" {
  description = "The DNS name of the ALB."
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "The ARN of the main ALB target group."
  value       = aws_lb_target_group.main.arn
}

output "frontend_s3_bucket" {
  description = "The name of the frontend S3 bucket."
  value       = aws_s3_bucket.frontend.id
}

output "waf_acl_global_arn" {
  description = "ARN of the Global WAFv2 Web ACL (CloudFront)"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "waf_acl_regional_arn" {
  description = "ARN of the Regional WAFv2 Web ACL (ALB)"
  value       = aws_wafv2_web_acl.regional.arn
}
