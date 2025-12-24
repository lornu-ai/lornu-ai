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

# Install minimal build dependencies (gcc for Rust linker, curl for uv)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libc6-dev \
    make \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:$PATH"

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
