# Plan A — AGENTS.md

This repo is AI-native and optimized for **Plan A (MVI)**. Agents should generate code that respects the single-cluster, multi-namespace Kubernetes model.

## Quick Start (Required Reading)
1. `.ai/MISSION.md` for product goals.
2. `.ai/ARCHITECTURE.md` for system design context.
3. `.ai/RULES.md` for coding standards and workflow.

If there is any conflict between docs, follow `.ai/RULES.md`.

## Repo Layout
- `apps/web`: Frontend (React + Vite).
- `packages/api`: Backend (Python 3.11+).
- `terraform/`: Infrastructure (Terraform Cloud).
- `kubernetes/`: Kustomize manifests.
- `docs/`: Project documentation.

## Plan A Kubernetes Model
- **Single EKS cluster**, namespaces:
  - `lornu-dev`
  - `lornu-staging`
  - `lornu-prod`
- **DRY manifests**: `kubernetes/base/` is source of truth; overlays live in `kubernetes/overlays/`.
- **Helm is deprecated**; use `kubectl apply -k` or `kustomize build`.
- **Protective Metadata** on all resources:
  - `lornu.ai/environment`: `development` | `staging` | `production`
  - `lornu.ai/managed-by`: `terraform-cloud`
  - `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Tooling
- JS/TS package manager: **Bun** only (`bun install`, `bun run`, `bunx`).
- Python package manager: **uv** only (`uv sync`, `uv run`, `uv pip install`).

## Git Workflow
- `main`: Production
- `develop`: Staging/Integration
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main` or `develop`.
- Always open PRs against `develop`. For kustomize docs updates, use base `kustomize-develop`.
## PR Labeling (Required)
- Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR. If the label doesn't exist, create it first.
- Example commands: `gh label create <agent-name>` (if needed), `gh pr edit <pr-number> --add-label <agent-name>`.

## Testing & Linting
- Frontend tests: `bun run test`, `bun run test:e2e`
- Backend tests: `uv run pytest`
- Backend lint: `uv run ruff check .`
