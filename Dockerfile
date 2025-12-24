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

# Install build dependencies for Rust-based packages (vtracer, rembg)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy uv from a tagged version (digest removed to unblock build)
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

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
