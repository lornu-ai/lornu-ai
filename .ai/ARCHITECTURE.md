# Plan A — System Architecture

## Overview
Plan A delivers a **single EKS cluster** with **multi-namespace isolation** managed by Kustomize. Infrastructure is controlled via Terraform Cloud and deployed through GitHub Actions.

## Runtime Stack
- **Frontend**: React + Vite (`apps/web`) with Bun.
- **Backend**: Python (`packages/api`) with uv.
- **Infrastructure**: Terraform Cloud + AWS EKS.

## Hub-and-Spoke Model (Terraform Cloud)
- **Hub**: Terraform Cloud workspace for shared governance and variables.
- **Spokes**: Environment-specific workspaces (dev/staging/prod) managed through CI.

## Kubernetes Structure (DRY)
```
kubernetes/base/       # Source of truth manifests
kubernetes/overlays/   # dev, staging, prod overlays
```

## Namespace Isolation
- `lornu-dev`
- `lornu-staging`
- `lornu-prod`

Each namespace includes the **Protective Metadata** standard:
- `lornu.ai/environment`
- `lornu.ai/managed-by`
- `lornu.ai/asset-id`

## Branding Asset
- `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`
