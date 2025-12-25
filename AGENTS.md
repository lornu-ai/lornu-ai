# AGENTS.md

This repo is structured to be AI-native. Start here and follow the rules below.

## Quick Start (Required Reading)
1. `.ai/MISSION.md` for product goals.
2. `.ai/ARCHITECTURE.md` for system design context.
3. `.ai/RULES.md` for coding standards and workflow.

If there is any conflict between docs, follow `.ai/RULES.md`.

## Repo Layout
- `apps/web`: Frontend (React + Vite).
- `packages/api`: Backend (Python 3.11+).
- `docs/`: Project documentation.
- `terraform/`, `kubernetes/`: Infrastructure.

## Tooling
- JS/TS package manager: **Bun** only (`bun install`, `bun run`, `bunx`).
- Python package manager: **uv** (`uv sync`, `uv run`, `uv pip install`).

## Git Workflow
- `main`: Production
- `develop`: Staging/Integration
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main` or `develop`.

## Testing & Linting
- Frontend tests: `bun run test`, `bun run test:e2e`
- Backend tests: `uv run pytest`
- Backend lint: `uv run ruff check .`
