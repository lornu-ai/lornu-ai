# Plan A — AI Coding Agent Instructions (Lornu AI)

Concise guidance for AI agents to be immediately productive in this monorepo. Document only observed patterns and concrete workflows.

## Big Picture
- **Plan A (MVI)**: One EKS cluster, three namespaces (`lornu-dev`, `lornu-staging`, `lornu-prod`).
- **Kustomize** governs Kubernetes resources: `kubernetes/base/` + `kubernetes/overlays/{dev,staging,prod}`. Helm is deprecated.
- **Runtimes**: Bun for frontend, uv for backend.

## Required Kubernetes Standards
- Use `kubernetes/base/` as the source of truth. Add shared resources there and patch in overlays.
- Each environment has its own namespace manifest in `kubernetes/overlays/<env>/namespace.yaml`.
- Apply **Protective Metadata** to every resource:
  - `lornu.ai/environment`: `development` | `staging` | `production`
  - `lornu.ai/managed-by`: `terraform-cloud`
  - `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`
- Use the `lornu-` prefix for resource names, labels, and namespaces.

## Directory Structure
```
apps/web/              # React frontend (Bun)
packages/api/          # Python backend (uv)
terraform/             # Terraform Cloud infrastructure
kubernetes/base/       # Source of truth manifests
kubernetes/overlays/   # dev, staging, prod overlays
```

## Developer Workflows
### Frontend (Bun)
```bash
cd apps/web
bun install
bun run dev
bun run build
bun run test
```

### Backend (uv)
```bash
cd packages/api
uv sync
uv run python -m packages.api.main
uv run pytest
```

### Kubernetes (Kustomize)
```bash
# Preferred: built-in kubectl Kustomize
kubectl apply -k kubernetes/overlays/dev

# Dev
kustomize build kubernetes/overlays/dev | kubectl apply -f -

# Staging
kustomize build kubernetes/overlays/staging | kubectl apply -f -

# Prod
kustomize build kubernetes/overlays/prod | kubectl apply -f -
```

## Branding
- Brand asset: `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`

## Avoid
- AWS ECS and Cloudflare Workers references.
- Non-DRY manifests (no copy-paste across overlays).
- Helm charts, templates, or values files (Helm is deprecated).

## PR Labeling (Required)
- Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR. If the label doesn't exist, create it first.
- Example commands: `gh label create <agent-name>` (if needed), `gh pr edit <pr-number> --add-label <agent-name>`.
