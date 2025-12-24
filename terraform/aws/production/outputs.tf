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

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "db_cluster_endpoint" {
  description = "The cluster endpoint for the Aurora database"
  value       = aws_rds_cluster.main.endpoint
}

output "db_cluster_reader_endpoint" {
  description = "The cluster reader endpoint for the Aurora database"
  value       = aws_rds_cluster.main.reader_endpoint
}
