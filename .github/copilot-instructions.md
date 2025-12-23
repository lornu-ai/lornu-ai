# AI Coding Agent Instructions for Lornu AI

Concise guidance for AI agents to be immediately productive in this monorepo. Document only observed patterns and concrete workflows.

## Big Picture
- Monorepo with three areas:
  - `apps/web`: React + Vite app using Cloudflare Workers for asset serving and lightweight APIs.
  - `packages/api`: Python package (uv-managed) currently minimal; FastAPI is declared but not yet used.
  - `terraform/aws/staging`: AWS infra (ALB, ECS, IAM, VPC) with a Terraform Cloud remote backend.
- Primary runtime is the Cloudflare Worker in `apps/web/worker.ts` that serves built assets from `dist/` and implements `/api` endpoints.

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
  bunx wrangler dev   # run worker locally against built assets
  bunx wrangler deploy
  ```

## Web App Architecture & Patterns
- Worker entry: `apps/web/worker.ts` with `ASSETS` binding (configured in `apps/web/wrangler.toml`).
- Explicit `MIME_TYPES` mapping used when `ASSETS` lacks `Content-Type` — ensure new asset types are added here.
- API endpoints implemented in worker:
  - `GET /api/health`: simple JSON `{ "status": "ok" }`.
  - `POST /api/contact`: validates input, rate-limits per IP, sends email via Resend.
- Rate limiting:
  - Uses optional KV namespace `RATE_LIMIT_KV`; limits 5 requests/hour/IP.
  - Bypass headers for CI: `X-Bypass-Rate-Limit` and `X-Bypass-Email` when matching corresponding secrets.
- Secrets required in Cloudflare:
  - `RESEND_API_KEY` (required), `CONTACT_EMAIL` (optional), `RATE_LIMIT_BYPASS_SECRET` (optional), `EMAIL_BYPASS_SECRET` (optional).
- CORS for `/api/contact`: `Access-Control-Allow-Origin: *` and `POST, OPTIONS` allowed.

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
- Worker config: `apps/web/wrangler.toml`.
  - `assets.directory` is `./dist`; build via `bun run build` before `wrangler dev/deploy`.
  - Routes configured for `lornu.ai` and `www.lornu.ai`; staging env `env.staging` uses `workers_dev`.
- Cloudflare Git integration recommended; ensure Bun is configured for builds (see web README).
- Environment vars can be added to `wrangler.toml [vars]` and secrets via `wrangler secret`.

## Python API
- Minimal hello-world at `packages/api/main.py`; FastAPI declared in `pyproject.toml`.
- Install/run via uv:
  ```bash
  cd packages/api
  uv pip install -e .
  uv run python main.py
  ```

## Terraform
- Staging stack under `terraform/aws/staging/*` with remote backend:
  - Organization `lornu-ai`, workspace `lornu-ai` in Terraform Cloud.
- Files include `alb.tf`, `ecs.tf`, `iam.tf`, `vpc.tf`, `variables.tf`, `outputs.tf`.

## Examples
- Adding a new worker route: Update `apps/web/worker.ts` `fetch()` handler to route `/api/your-endpoint`, keep CORS + JSON responses consistent.
- Serving a new asset type: Add its extension to `MIME_TYPES` in `apps/web/worker.ts`.
- Writing an integration test: Place in `apps/web/src/*/*.integration.test.tsx`; use Testing Library with jsdom.

---
Questions or gaps? Tell us where this feels thin (e.g., API usage, deployment specifics), and we’ll refine this file.
