# Lornu AI

This monorepo contains a React web app (Vite + Bun), a Cloudflare Worker, and a Python package (uv).

## Developer Quick Start
- Web app (apps/web)
	- Install: `bun install`
	- Lint: `bun run lint`
	- Tests: `bun run test:run`
	- E2E: `bun run test:e2e:smoke`
	- Build: `bun run build`
- Python API (packages/api)
	- Install: `uv pip install -e .`
	- Run: `uv run python main.py`

See [docs/COPILOT_CONTEXT.md](docs/COPILOT_CONTEXT.md) and apps/web/TESTING.md for more.

## Project Structure
- apps/web: React + Vite app, Cloudflare Worker in `worker.ts`
- packages/api: Python package managed with `uv`
- docs/: operational docs and testing notes
- .vscode/: workspace settings and tasks
- .ai/: AI context and documentation
