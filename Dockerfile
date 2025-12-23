# Multi-stage build for Lornu AI
FROM oven/bun:alpine AS base
WORKDIR /app

# Stage 1: Build Frontend (if bundled)
COPY apps/web/package.json apps/web/bun.lockb ./apps/web/
RUN cd apps/web && bun install --frozen-lockfile
COPY apps/web/ ./apps/web/
RUN cd apps/web && bun run build

# Stage 2: Backend Execution (Python 3.11+ for ADK)
FROM python:3.11-slim
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

# Install dependencies
COPY packages/api/pyproject.toml packages/api/uv.lock ./packages/api/
RUN cd packages/api && uv sync --frozen

# Copy Application logic
COPY packages/api/ ./packages/api/
COPY --from=base /app/apps/web/dist ./frontend/dist

# Environment variables for A2A and Gemini
ENV PORT=8080
EXPOSE 8080

CMD ["uv", "run", "--directory", "packages/api", "python", "-m", "main"]
