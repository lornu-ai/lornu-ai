# Stage 1: Build React Frontend
FROM oven/bun:alpine AS frontend-builder
WORKDIR /app/apps/web
COPY apps/web/package.json apps/web/bun.lock ./
RUN bun install --frozen-lockfile
COPY apps/web/ ./
RUN bun run build

# Stage 2: Backend Builder (Compilers included for dependencies)
FROM python:3.12-slim AS backend-builder
WORKDIR /app

# Install build dependencies (gcc, make for any native python modules)
# Removed curl as we copy uv from image
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc libc6-dev make && \
    rm -rf /var/lib/apt/lists/*

# Securely install uv via image copy (Supply Chain Security)
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /bin/uv

# Create venv and install dependencies
# UV_COMPILE_BYTECODE=1 speeds up startup
ENV UV_COMPILE_BYTECODE=1
COPY packages/api/pyproject.toml packages/api/uv.lock ./
# --no-dev: production deps only
# --no-editable: standard install
RUN uv sync --frozen --no-dev --no-editable

# Stage 3: Final Runtime (Slim, Secure, Non-root)
FROM python:3.12-slim AS runtime
WORKDIR /app

# Create non-root user for security (best practice for EKS)
# Use fixed UID 1000 to match kubernetes/base/deployment.yaml runAsUser context
RUN groupadd -r -g 1000 lornu && useradd -r -u 1000 -g lornu lornu

# Copy Virtual Environment from builder (contains all installed deps)
COPY --from=backend-builder /app/.venv /app/.venv
# Add venv to PATH so we can just run "python"
ENV PATH="/app/.venv/bin:$PATH"

# Copy Application Code
COPY packages/api/ ./packages/api/
COPY --from=frontend-builder /app/apps/web/dist ./apps/web/dist

# Set permissions for non-root user
RUN chown -R lornu:lornu /app

# Switch to non-root user
USER lornu

ENV PORT=8080
EXPOSE 8080

# Run directly with python (no uv wrapper needed in runtime)
CMD ["python", "-m", "packages.api.main"]
