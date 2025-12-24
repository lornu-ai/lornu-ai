# Stage 1: Build React Frontend
FROM oven/bun:alpine AS frontend-builder
WORKDIR /app
COPY apps/web/package.json apps/web/bun.lock ./apps/web/
RUN cd apps/web && bun install --frozen-lockfile
COPY apps/web/ ./apps/web/
RUN cd apps/web && bun run build

# Stage 2: Backend Builder (Compilers included)
FROM python:3.11-slim AS backend-builder
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libc6-dev make curl && \
    rm -rf /var/lib/apt/lists/*

# Install uv via official image (no digest to avoid staleness issues)
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

# Create venv and install dependencies
ENV UV_COMPILE_BYTECODE=1 
COPY packages/api/pyproject.toml packages/api/uv.lock ./
RUN uv sync --frozen --no-dev --no-editable

# Stage 3: Final Runtime (Slim & Secure)
FROM python:3.11-slim AS runtime
WORKDIR /app

# Create non-root user for security
RUN groupadd -r lornu && useradd -r -g lornu lornu

# Copy Virtual Environment from builder (contains all installed deps)
COPY --from=backend-builder /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Copy Application Code
COPY packages/api/ ./packages/api/
COPY --from=frontend-builder /app/apps/web/dist ./apps/web/dist

# Set permissions
RUN chown -R lornu:lornu /app

# Switch to non-root user
USER lornu

ENV PORT=8080
EXPOSE 8080

# Run directly with python (no uv wrapper needed in runtime)
CMD ["python", "-m", "packages.api.main"]
