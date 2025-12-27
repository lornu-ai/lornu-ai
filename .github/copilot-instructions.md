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

## GitHub Actions (Main Branch Only)

The `main` branch uses **five consolidated workflows** (Issue #440):

- **orchestrator.yml**: Multi-cloud TFC dispatch (AWS/GCP via OIDC)
- **ci-unified.yml**: Unified lint/test (uv + bun)
- **synthetic-monitors.yml**: Playwright health checks
- **manage-workspaces.yml**: TFC workspace management
- **security-scan.yml**: tfsec & CodeQL

**All workflows use OIDC** - no static AWS/GCP keys. TFC workspaces: `aws-kustomize`, `gcp-lornu-ai`.

See `.github/workflows/README.md` for the complete architecture.

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
- AWS ECS (use EKS instead).
- **Cloudflare Workers and Wrangler** (DEPRECATED. This project is 100% Kubernetes via Kustomize).
  - DO NOT suggest `wrangler.toml`, `worker.ts`, or `bunx wrangler` commands.
  - DO NOT reference Cloudflare Pages, AI Gateway, or Workers runtime.
  - DO NOT use `cloudflare/wrangler-action` in GitHub Actions.
- Non-DRY manifests (no copy-paste across overlays).
- Helm charts, templates, or values files (Helm is deprecated).

## Asset Serving & API Routes (Plan A Standard)
- **Asset serving**: Handled by Kubernetes Ingress (AWS ALB or GCP GCE Load Balancer).
- **API routes** (e.g., `/api/contact`): Handled by FastAPI backend in `packages/api/`.
- All requests route through `kubernetes/overlays/{dev,staging,prod}/` Ingress definitions with TLS termination.
- No Worker scripts or edge computing; all logic runs in containers on the cluster.

## PR Labeling (Required)
- Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR. If the label doesn't exist, create it first.
- Example commands: `gh label create <agent-name>` (if needed), `gh pr edit <pr-number> --add-label <agent-name>`.

## PR Base Branch (Required)
- Always open PRs against `main`.

## Terraform Hygiene (Required)
- Before pushing, run `terraform fmt` and `terraform validate` for any Terraform changes.
