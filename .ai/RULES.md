# Project Rules & Context (Lornu AI)

## Tech Stack
- **Frontend:** React + Vite (located in `apps/web`)
- **Package Manager (JS):** **Bun** (Always use `bun install`, `bun run`, `bunx`). NEVER use npm/yarn.
- **Backend:** Python 3.11+ (located in `packages/api`)
- **Package Manager (Python):** **uv** (Use `uv sync`, `uv pip install`).
- **Infrastructure:** Terraform (AWS), Docker, Kubernetes (Kustomize).
  - **Terraform Cloud Config:** Uses `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` for authentication.

## Directory Structure
- `apps/web`: Frontend application.
- `packages/api`: Backend API/Logic.
- `terraform/`: Infrastructure as Code.
- `k8s/`: Kubernetes manifests (Base + Overlays).
- `docs/`: Project documentation.

## Workflow Rules
1. **Git:**
   - Main branch: `main` (Production)
   - Develop branch: `develop` (Staging/Integration)
   - Feature branches: `feat/` or `feature/`
   - **Never push directly to main/develop.** Always use PRs.
2. **Testing:**
   - Frontend: `bun run test` (Vitest), `bun run test:e2e` (Playwright).
   - Backend: `uv run pytest`.
3. **Linting:**
   - Frontend: ESLint + Prettier.
   - Backend: Ruff (`uv run ruff check .`).

## Specific Configurations
- **Tailwind:** Configured in `apps/web/tailwind.config.js`. Uses `oklch` colors.
- **Docker:** Multi-stage build located at root `Dockerfile`.
