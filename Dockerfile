# Multi-stage build for Lornu AI (ECS Fargate)
# ------------------------------------------------------------------------------
# Stage 1: Build Frontend (React/Vite with Bun)
# ------------------------------------------------------------------------------
FROM oven/bun:alpine AS frontend-builder
WORKDIR /app

# Copy frontend dependency files
# We need to preserve the directory structure for relative path references if any,
# but for a standalone app `apps/web` works fine.
COPY apps/web/package.json apps/web/bun.lockb* ./apps/web/

# Install dependencies
WORKDIR /app/apps/web
RUN bun install --frozen-lockfile

# Copy source code and build
COPY apps/web/ ./
RUN bun run build

# ------------------------------------------------------------------------------
# Stage 2: Backend Execution (Python 3.11+ / FastAPI)
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS runtime
WORKDIR /app

# Install uv for fast Python package management
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

# Copy backend dependency files
COPY packages/api/pyproject.toml packages/api/uv.lock ./

# Install backend dependencies
# --system flag installs into the system python environment, which is fine for a container
RUN uv sync --frozen --system

# Copy Backend Application Logic
# We rename 'packages/api' to 'backend' inside the container for clarity/import convention
COPY packages/api/ ./backend/

# Copy Frontend Build Artifacts
# These will be served by the FastAPI app (StaticFiles)
COPY --from=frontend-builder /app/apps/web/dist ./frontend/dist

# Environment configuration
ENV PORT=8080
ENV HOST=0.0.0.0
# Ensure python path includes the current directory so 'backend' module is found
ENV PYTHONPATH=/app

# Expose the port ECS Fargate will route to
EXPOSE 8080

# Run the application
# Note: 'backend.main' assumes the file packages/api/main.py exists.
# This CMD will need to be updated once FastAPI is fully implemented (e.g. uvicorn backend.main:app)
CMD ["uv", "run", "uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8080"]
