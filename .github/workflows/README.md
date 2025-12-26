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
   - File: `.github/workflows/kustomize-deploy.yml`
   - Purpose: Apply namespace-scoped Kubernetes manifests.

## Orchestration
`kustomize-deploy.yml` calls the Stage 1 and Stage 2 workflows via `workflow_call` and only deploys after both succeed.
