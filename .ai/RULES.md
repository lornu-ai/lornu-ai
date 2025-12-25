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
- `main`: Production
- `develop`: Staging/Integration
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main` or `develop`.
## PR Labeling (Required)
- Create (if missing) a GitHub label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) and apply it to every PR.
- Use `gh label create` and `gh pr edit --add-label`.

## Testing & Linting
- Frontend tests: `bun run test`, `bun run test:e2e`
- Backend tests: `uv run pytest`
- Backend lint: `uv run ruff check .`

## Infrastructure
- Terraform Cloud is the source of truth for AWS infrastructure.
- GitHub Actions drives plans/applies and Kustomize deployments.

## Prohibited References
- Do not introduce AWS ECS or Cloudflare Workers references.
- Do not introduce Helm charts, templates, or values files.
