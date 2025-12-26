# Workflow Index

## Layered Deployment (Plan A)
The deployment pipeline is intentionally split into three layers to keep global AWS resources stable:

1. **Stage 1 - ACM**
   - File: `.github/workflows/terraform-aws-stage1-acm.yml`
   - Purpose: Issue/validate CloudFront ACM certs.
2. **Stage 2 - CDN**
   - File: `.github/workflows/terraform-aws-stage2-cdn.yml`
   - Purpose: CloudFront distribution + Route53 records.
3. **Kustomize Deploy**
   - Handled by `terraform-aws.yml` after terraform apply
   - Purpose: Apply namespace-scoped Kubernetes manifests.

## Orchestration
`infra-orchestrator.yml` orchestrates Stage 1 and Stage 2 workflows. Kustomize deployments are handled by `terraform-aws.yml` after successful terraform apply.
