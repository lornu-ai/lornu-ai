# Workflow Index

## Layered Deployment (Plan A)
The deployment pipeline is intentionally split into three layers to keep global AWS resources stable:

1. **Part 1 - ACM**
   - File: `.github/workflows/terraform-aws-part1-acm.yml`
   - Purpose: Issue/validate CloudFront ACM certs.
2. **Part 2 - CDN**
   - File: `.github/workflows/terraform-aws-part2-cdn.yml`
   - Purpose: CloudFront distribution + Route53 records.
3. **Kustomize Deploy**
   - Handled by `terraform-aws.yml` after terraform apply
   - Purpose: Apply namespace-scoped Kubernetes manifests.

## Orchestration
`infra-orchestrator.yml` orchestrates Part 1 and Part 2 workflows. Kustomize deployments are handled by `terraform-aws.yml` after successful terraform apply.
