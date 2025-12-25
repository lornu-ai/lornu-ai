# AI Coding Agent Instructions for Lornu AI

Concise guidance for AI agents to be immediately productive in this monorepo. Document only observed patterns and concrete workflows.

## Big Picture
- Monorepo with three areas:
  - `apps/web`: React + Vite frontend app (built static assets).
  - `packages/api`: Python FastAPI backend serving React assets and handling API endpoints.
  - `terraform/aws/staging`: AWS infra (EKS cluster, ALB, ECR, IAM, VPC) with Terraform Cloud remote backend.
- Primary runtime is AWS EKS (Kubernetes) running containerized FastAPI backend serving React frontend from `apps/web/dist/` and implementing `/api` endpoints.
- Kubernetes manifests managed with Kustomize in `kubernetes/` directory.

## Developer Workflows
- Package manager: Bun.
- VS Code tasks exist (recommended use):
  - Install: bun (web) → installs deps in `apps/web`.
  - Lint: bun (web) → `bun run lint`.
  - Unit+Integration: bun (web) → `bun run test:run`.
  - E2E smoke: bun (web) → `bun run test:e2e:smoke`.
  - Build: bun (web) → `bun run build`.
  - API hello: uv (api) → `uv run python main.py`.
- CLI equivalents (from `apps/web`):
  ```bash
  bun install
  bun run dev         # vite dev server (5174 by default)
  bun run build       # creates dist/
  bun run lint        # eslint over repo
  bun run test:run    # vitest unit+integration
  bun run test:e2e    # playwright e2e (starts dev server)
  ```
- Backend (from `packages/api`):
  ```bash
  uv sync             # install dependencies
  uv run python -m packages.api.main  # run FastAPI server
  ```

## Web App Architecture & Patterns
- Backend entry: `packages/api/main.py` FastAPI application.
- Serves React static assets from `apps/web/dist/` via StaticFiles mount.
- API endpoints implemented in FastAPI:
  - `GET /api/health`: simple JSON `{ "status": "ok" }`.
  - `POST /api/contact`: validates input (Pydantic), rate-limits per IP, sends email via Resend.
- Rate limiting:
  - In-memory store; limits 5 requests/hour/IP.
  - Bypass headers for CI: `X-Bypass-Rate-Limit` when matching `RATE_LIMIT_BYPASS_SECRET`.
- Environment variables:
  - `RESEND_API_KEY` (required for email), `CONTACT_EMAIL` (optional), `RATE_LIMIT_BYPASS_SECRET` (optional for CI), `PORT` (default 8080).
- CORS configured via FastAPI middleware: `allow_origins=["*"]`, all methods and headers allowed.

## Testing Conventions
- Unit/Integration: Vitest (`apps/web/vitest.config.ts`).
  - Environment `jsdom`, globals enabled, CSS allowed.
  - Integration test files use suffix `.integration.test.tsx`.
  - Coverage via V8; e2e directory excluded.
- E2E: Playwright (`apps/web/playwright.config.ts`).
  - Base URL defaults to `http://localhost:5174`.
  - `webServer.command` is `bun run dev`; tests can reuse existing server locally.
  - Smoke tests: `tests/e2e/smoke-test.spec.ts`.
- Additional script: `bun run test:contact` executes `apps/web/scripts/test-contact-form.ts`.

## Frontend Conventions
- Aliases: `@` → `apps/web/src`.
- UI components under `apps/web/src/components/ui/*` (Radix UI + Tailwind 4 patterns).
- Pages in `apps/web/src/pages/*`; routing via React Router.
- Helpers in `apps/web/src/lib/utils.ts`.
- SEO and consent patterns: `apps/web/src/components/SEOHead.tsx`, `CookieConsent.tsx`.

## Configuration & Deployment
- Docker build: Multi-stage build in `Dockerfile` (Bun for frontend, Python for backend).
  - Stage 1: Builds React app with Bun → `apps/web/dist/`.
  - Stage 2: Python image with uv, copies API code and built frontend assets.
- AWS EKS deployment:
  - Docker images pushed to ECR (`lornu-ai-staging` repository).
  - EKS cluster pulls from ECR and runs pods.
  - Kubernetes service exposes pods via ALB ingress.
  - Manifests deployed via Kustomize (`kubernetes/overlays/staging`).
- CI/CD: `.github/workflows/terraform-aws.yml` builds Docker image, pushes to ECR, runs Terraform, applies k8s manifests.
- Environment vars managed via Kubernetes ConfigMaps and AWS Secrets Manager.

## Python API
- FastAPI application at `packages/api/main.py` serving both API and frontend assets.
- Endpoints: `/api/health`, `/api/contact` (with rate limiting and Resend integration).
- Mounts React static files at root path `/`.
- Install/run via uv:
  ```bash
  cd packages/api
  uv sync
  uv run python -m packages.api.main
  ```

## Terraform
- Staging stack under `terraform/aws/staging/*` with Terraform Cloud remote backend:
  - Organization `lornu-ai`, workspace `lornu-ai-staging-aws`.
- Resources: VPC, EKS cluster, ALB Ingress Controller, ECR, IAM roles, Security Groups.
- Files: `eks.tf`, `ecr.tf`, `iam.tf`, `vpc.tf`, `main.tf`, `variables.tf`, `outputs.tf`.
- Terraform variables passed via GitHub Secrets: `ACM_CERTIFICATE_ARN`, `SECRETS_MANAGER_ARN_PATTERN`, plus Docker image URI.
- AWS authentication via OIDC (GitHub Actions assumes IAM role).
- Post-Terraform: Apply Kustomize manifests to EKS cluster.

## Examples
- Adding a new API endpoint: Add route to `packages/api/main.py` using FastAPI decorator (`@app.get`, `@app.post`), keep CORS configured via middleware.
- Building Docker image locally: `docker build -t lornu-ai .` from repo root.
- Writing an integration test: Place in `apps/web/src/*/*.integration.test.tsx`; use Testing Library with jsdom.
- Testing API locally: Run `uv run python -m packages.api.main` and access `http://localhost:8080`.

---
Questions or gaps? Tell us where this feels thin (e.g., API usage, deployment specifics), and we’ll refine this file.
