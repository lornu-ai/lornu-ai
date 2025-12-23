# Multi-stage build for Lornu AI (ECS Fargate)
# Stage 1: Build Frontend (React/Vite with Bun)
FROM oven/bun:alpine AS frontend-builder
WORKDIR /app

# Copy and install frontend dependencies
COPY apps/web/package.json apps/web/bun.lockb* ./apps/web/
WORKDIR /app/apps/web
RUN bun install --frozen-lockfile

# Copy source and build
COPY apps/web/ ./
RUN bun run build

# Stage 2: Backend Execution (Python 3.11+ for ADK)
FROM python:3.11-slim
WORKDIR /app

# Copy uv from specific pinned version (not latest)
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

# Install backend dependencies
COPY packages/api/pyproject.toml packages/api/uv.lock ./packages/api/
WORKDIR /app/packages/api
RUN uv sync --frozen --system

# Copy backend application logic
COPY packages/api/ ./

# Copy frontend build artifacts
WORKDIR /app
COPY --from=frontend-builder /app/apps/web/dist ./public/

# Environment configuration
ENV PORT=8080
ENV HOST=0.0.0.0
ENV PYTHONPATH=/app/packages/api

EXPOSE 8080

# Run the application (FastAPI via uvicorn)
CMD ["uv", "run", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]

# Expose the port ECS Fargate will route to
EXPOSE 8080

# Run the application
# Note: 'backend.main' assumes the file packages/api/main.py exists.
# This CMD will need to be updated once FastAPI is fully implemented (e.g. uvicorn backend.main:app)
CMD ["uv", "run", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8080"]
