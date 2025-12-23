# Copilot Context: Tooling & Project Map

This workspace uses Bun for JavaScript/TypeScript and uv for Python. Copilot Chat can reference these docs and your code to give precise answers.

## Tooling
- Bun (apps/web): use `bun install`, `bun run build`, `bun run test:run`.
- Playwright (apps/web): `bun run test:e2e:smoke`.
- uv (packages/api): `uv pip install -e .`, `uv run python main.py`.
- Terraform (terraform/aws): managed via Terraform Cloud.

## Quick Commands
- Web lint/tests:
  - `bun run lint`
  - `bun run test:run`
- Web e2e:
  - `bun run test:e2e:smoke`
- Build web:
  - `bun run build`
- Python api:
  - `uv pip install -e .`
  - `uv run python main.py`

## Copilot Chat Tips
- Ask with workspace context: "@workspace How do we run tests?"
- Point Copilot to docs: "Use docs/COPILOT_CONTEXT.md and apps/web/TESTING.md."
- Reference files directly: "Open apps/web/package.json scripts and suggest Bun commands."
- Use the Tasks view: run tasks like "bun: unit+integration tests (web)".

## AWS & Terraform Cloud
For AWS deployments via Terraform Cloud, set these environment variables/secrets:
- `AWS_ACCESS_KEY_ID`: IAM user access key
- `AWS_SECRET_ACCESS_KEY`: IAM user secret key
- `AWS_DEFAULT_REGION`: e.g., `us-east-1` (or target region)

Store in:
- GitHub Secrets (for CI/CD runner access)
- Terraform Cloud workspace variables (for remote state and apply)

## Project Map
- apps/web: React + Vite app, Cloudflare Worker in `worker.ts`.
- packages/api: Python placeholder with FastAPI dependency.
- docs/: operational docs and testing notes.
- .vscode/: editor settings and tasks for Bun/uv.
