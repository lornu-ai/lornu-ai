# Plan A — Lornu AI

## Mission
Deliver a **50–70% reduction in engineering time** through a hardened, metadata-driven **Minimum Viable Infrastructure (MVI)**. Plan A consolidates delivery onto **one EKS cluster** with **Kustomize-based multi-namespace isolation**.

## Plan A Snapshot
- **Single EKS cluster** with three namespaces:
  - `lornu-dev`
  - `lornu-staging`
  - `lornu-prod`
- **Kustomize overlays** per environment (Helm is deprecated).
- **Terraform Cloud** as infrastructure control plane.
- **Modern runtimes**: Bun (frontend), uv (backend).

## Directory Structure (DRY)
```
apps/web/              # React frontend (Bun)
packages/api/          # Python backend (uv)
terraform/             # Infrastructure (Terraform Cloud)
kubernetes/base/       # Source of truth manifests
kubernetes/overlays/   # dev, staging, prod overlays
```

## Protective Metadata Standard
Every Kubernetes resource must include:
- `lornu.ai/environment`: `development` | `staging` | `production`
- `lornu.ai/managed-by`: `terraform-cloud`
- `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Quick Start
1. Read `.ai/MISSION.md`
2. Read `.ai/ARCHITECTURE.md`
3. Read `.ai/RULES.md`

## Runtime Standards
- **Frontend**: Bun (`bun install`, `bun run`, `bunx`)
- **Backend**: uv (`uv sync`, `uv run`, `uv pip install`)

## Branding
- Brand asset: `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`

## Kubernetes Apply (Examples)
```bash
kubectl apply -k kubernetes/overlays/dev
kustomize build kubernetes/overlays/dev | kubectl apply -f -
kustomize build kubernetes/overlays/staging | kubectl apply -f -
kustomize build kubernetes/overlays/prod | kubectl apply -f -
```

## Notes
Plan A documentation is authoritative for this repo. Legacy references to ECS or Cloudflare Workers are deprecated.
