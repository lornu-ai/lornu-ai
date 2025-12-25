# Plan A — External LLM Context (Claude)

## Project Summary
Lornu AI uses **Plan A (MVI)**: a **single EKS cluster** with **Kustomize-based multi-namespace isolation**. All environments share the same cluster and are isolated by namespace.

## Namespaces
- `lornu-dev`
- `lornu-staging`
- `lornu-prod`

## Kubernetes Structure (DRY)
```
kubernetes/base/       # Source of truth manifests
kubernetes/overlays/   # dev, staging, prod overlays
```

## Protective Metadata (Required)
- `lornu.ai/environment`: `development` | `staging` | `production`
- `lornu.ai/managed-by`: `terraform-cloud`
- `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Tooling
- **Frontend**: Bun (`apps/web`)
- **Backend**: uv (`packages/api`)
- **Infrastructure**: Terraform Cloud (`terraform/`)

## Branding
- Asset: `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`

## Avoid
- AWS ECS or Cloudflare Workers references.
