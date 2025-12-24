# Multi-stage build for Lornu AI
FROM oven/bun:alpine AS base
WORKDIR /app

# Stage 1: Build React Frontend
COPY apps/web/package.json apps/web/bun.lock ./apps/web/
RUN cd apps/web && bun install --frozen-lockfile
COPY apps/web/ ./apps/web/
RUN cd apps/web && bun run build

# Stage 2: Python FastAPI Backend
FROM python:3.11-slim
WORKDIR /app

# Copy uv from pinned version for supply chain security
COPY --from=ghcr.io/astral-sh/uv:0.5.11@sha256:2eb7a6045100ebc45c88530c73ce6f8050b2aa57b44e1b48c8e2e9d6574e8c24 /uv /bin/uv

# Install Python dependencies
COPY packages/api/pyproject.toml packages/api/uv.lock ./
RUN uv sync --frozen

# Copy application code and built frontend
COPY packages/api/ ./packages/api/
COPY --from=base /app/apps/web/dist ./apps/web/dist

# Runtime configuration
ENV PORT=8080
EXPOSE 8080

CMD ["uv", "run", "python", "-m", "packages.api.main"]
