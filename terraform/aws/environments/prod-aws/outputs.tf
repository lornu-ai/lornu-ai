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

output "eks_cluster_name" {
  description = "Kubernetes Cluster Name (Epic Requirement)"
  value       = module.eks.cluster_name
}

output "oidc_provider_arn" {
  description = "The ARN of the OIDC Provider for EKS IRSA"
  value       = module.eks.oidc_provider_arn
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

output "waf_acl_arn" {
  description = "ARN of the WAFv2 Web ACL"
  value       = aws_wafv2_web_acl.main.arn
}
