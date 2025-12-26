# Plan A — Project Rules

## Core Standards
1. **Single EKS cluster** with namespace isolation.
2. **DRY manifests**: `kubernetes/base/` is the source of truth; overlays live in `kubernetes/overlays/`.
3. **Protective Metadata** on all Kubernetes resources:
   - `lornu.ai/environment`: `development` | `staging` | `production`
   - `lornu.ai/managed-by`: `terraform-cloud`
   - `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`
4. **Naming**: Use the `lornu-` prefix for namespaces and resource names.

## Tooling
- **Frontend**: Bun only (`bun install`, `bun run`, `bunx`).
- **Backend**: uv only (`uv sync`, `uv run`, `uv pip install`).

## Workflow Rules
- `main`: Production (single source of truth)
- `develop`: (deprecated) Staging/Integration
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main`.
- Always open PRs against `main`.
## PR Labeling (Required)
- Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR. If the label doesn't exist, create it first.
- Example commands: `gh label create <agent-name>` (if needed), `gh pr edit <pr-number> --add-label <agent-name>`.

## Testing & Linting
- Frontend tests: `bun run test`, `bun run test:e2e`
- Backend tests: `uv run pytest`
- Backend lint: `uv run ruff check .`

## Terraform Hygiene (Required)
- Before pushing, run `terraform fmt` and `terraform validate` for any Terraform changes.

## Infrastructure
- Terraform Cloud is the source of truth for AWS infrastructure.
- GitHub Actions drives plans/applies and Kustomize deployments.

## Prohibited References
- Do not introduce AWS ECS or Cloudflare Workers references.
- Do not introduce Helm charts, templates, or values files.
