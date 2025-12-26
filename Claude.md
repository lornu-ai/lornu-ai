# Plan A — External LLM Context (Claude)

## Project Summary
Lornu AI uses **Plan A (MVI)**: a **single EKS cluster** (AWS) or **GKE cluster** (GCP) with **Kustomize-based multi-namespace isolation**. All environments share the same cluster and are isolated by namespace.

## Multi-Cloud Architecture
- **AWS**: EKS cluster with namespaces `lornu-dev`, `lornu-staging`, `lornu-prod`
- **GCP**: GKE cluster with namespaces `lornu-dev`, `gcp-staging`, `gcp-prod`
- **Terraform Cloud Workspaces**:
  - AWS: `aws-kustomize` (organization: `lornu-ai`)
  - GCP: `gcp-lornu-ai` (organization: `lornu-ai`)

## Branch Model (Plan A)
- **Primary Branches**:
  - `main`: Production
  - `develop`: Staging/Integration
- **Feature Branches**: Created from `develop`, target `develop` in PRs
- **Principle**: "Kustomize is in our DNA" — deployment definitions are code, managed through standard feature branch workflow
- **No separate environment branches**: All Kustomize changes integrated in feature branches

## Namespaces
- `lornu-dev` (development)
- `lornu-staging` / `gcp-staging` (staging)
- `lornu-prod` / `gcp-prod` (production)

## Kubernetes Structure (DRY)
```
kubernetes/base/              # Source of truth manifests
kubernetes/overlays/          # Environment-specific overlays
  ├── lornu-dev/              # Development
  ├── lornu-staging/          # AWS Staging
  ├── aws-prod/              # AWS Production
  ├── gcp-staging/           # GCP Staging
  └── gcp-prod/              # GCP Production
```

## Terraform Structure
```
terraform/
  ├── aws/                   # AWS production (aws-kustomize workspace)
  ├── aws/staging/           # AWS staging (separate workspace)
  └── gcp/                   # GCP production (gcp-lornu-ai workspace)
```

## Protective Metadata (Required)
- `lornu.ai/environment`: `development` | `staging` | `production`
- `lornu.ai/managed-by`: `terraform-cloud`
- `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Tooling
- **Frontend**: Bun (`apps/web`) — `bun install`, `bun run`, `bunx`
- **Backend**: uv (`packages/api`) — `uv sync`, `uv run`
- **Infrastructure**: Terraform Cloud (`terraform/`)
- **Container**: Podman (for builds)

## Branding
- Asset: `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`

## Avoid
- AWS ECS or Cloudflare Workers references
- Helm charts, templates, or values files
- Separate environment-specific branches (kustomize, gcp-develop, etc.)
