# Production Terraform

This directory contains the production-grade Terraform stack for Lornu AI.

- EKS cluster, node groups, add-ons
- RDS (Aurora Serverless v2)
- WAFv2 + ALB Ingress
- Route53 + DNS, ACM

Changes here will trigger CI checks for PRs targeting `develop` or `main`. 
