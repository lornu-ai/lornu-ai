# Multi-stage build for Lornu AI
FROM oven/bun:alpine AS frontend-builder
WORKDIR /app

# Stage 1: Build Frontend
COPY apps/web/package.json apps/web/bun.lockb ./apps/web/
RUN cd apps/web && bun install --frozen-lockfile
COPY apps/web/ ./apps/web/
RUN cd apps/web && bun run build

# Stage 2: Backend Execution (Python 3.12+ for FastAPI)
FROM python:3.12-slim
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install dependencies
COPY packages/api/pyproject.toml packages/api/uv.lock ./packages/api/
RUN cd packages/api && uv sync --frozen

# Copy Application logic
COPY packages/api/ ./packages/api/
COPY --from=frontend-builder /app/apps/web/dist ./apps/web/dist

# Environment variables
ENV PORT=8080
EXPOSE 8080

CMD ["uv", "run", "python", "-m", "packages.api.main"]
