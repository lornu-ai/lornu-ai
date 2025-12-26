# Plan A Infrastructure Workflow

This repo uses a layered deployment strategy to keep global AWS resources stable while still shipping app changes quickly.

## Deployment Flow
1. **Stage 1 (ACM)**: Provision/validate CloudFront certificates.
2. **Stage 2 (CDN)**: Create/update CloudFront distribution and DNS records.
3. **Application (Kustomize)**: Deploy namespace-scoped Kubernetes resources.

## Workflow Mapping
- Stage 1: `.github/workflows/terraform-aws-stage1-acm.yml`
- Stage 2: `.github/workflows/terraform-aws-stage2-cdn.yml`
- Application: `.github/workflows/kustomize-deploy.yml`

## Why This Split
- Reduces blast radius: app edits do not re-run global infra layers.
- Speeds feedback: infra stages can be skipped unless relevant files change.
- Clear dependency chain: ACM → CDN → Kustomize.

## Inputs and Outputs
- Stage 1 outputs the CloudFront ACM certificate ARN.
- Stage 2 consumes the Stage 1 output and updates CloudFront/DNS.
- Kustomize deploy runs only after both infra stages succeed.
