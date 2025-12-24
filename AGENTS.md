# Agent Contributor Guidelines

Welcome to the Lornu AI repository. This document summarizes how to navigate the codebase and contribute safely.

## Project Structure & Module Organization

- `.ai/` contains mission, architecture, and coding standards.
- `apps/web/` is the React + Vite frontend plus the Cloudflare Worker (`worker.ts`) and assets in `apps/web/src/assets/`.
- `packages/api/` hosts the FastAPI backend (`packages/api/src/`) with entrypoint `packages/api/main.py`.
- `docs/` stores technical strategy and ops notes; `terraform/aws/staging/` contains AWS staging infrastructure.

## Build, Test, and Development Commands

Frontend (Bun only; do not use npm/yarn):
- `bun install` install dependencies in `apps/web/`.
- `bun run dev` start the Vite dev server.
- `bun run build` build the production bundle to `apps/web/dist/`.
- `bun run lint` run ESLint.
- `bun run test` run Vitest; `bun run test:e2e` runs Playwright.
- `bunx wrangler dev` run the Worker locally after `bun run build`.

Backend (uv + Python 3.12+):
- `uv sync` install dependencies in `packages/api/`.
- `uv run python packages/api/main.py` start the API with reload.
- `uv run pytest` run backend tests (when present).
- `uv run ruff check .` lint backend code.

Infrastructure:
- `terraform plan` from `terraform/aws/staging/` to validate staging changes.

## Coding Style & Naming Conventions

- Python: follow PEP 8, use `snake_case`, and lint with Ruff.
- TypeScript: use `camelCase` for variables and `PascalCase` for React components; formatting via Prettier/ESLint in `apps/web/`.
- Environment: do not hardcode secrets; use runtime config or environment variables.

## Testing Guidelines

- Frontend uses Vitest + React Testing Library (`apps/web/TESTING.md`); tests are co-located as `.test.tsx` or `.integration.test.tsx`.
- E2E tests live in `apps/web/tests/e2e/`.
- Target >80% frontend coverage; add tests for new UI, routing, or Worker changes.

## Commit & Pull Request Guidelines

- Use Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:` (example: `feat: add contact form validation`).
- Branches: `main` (prod), `develop` (staging), feature branches `feat/` or `feature/`.
- Never push directly to `main` or `develop`; open PRs with a clear description, link related issues, and include screenshots for UI changes. If CI checks exist, ensure they pass before review.

## Agent-Specific Instructions

- Start with `.ai/MISSION.md`, `.ai/ARCHITECTURE.md`, and `.ai/RULES.md`.
- Agent implementations live in `packages/api/src/agents/` and are wired into the API via `packages/api/src/router/message_router.py`.
