# Multi-stage build for Lornu AI
FROM oven/bun:alpine AS base
WORKDIR /app

# Stage 1: Build Frontend (if bundled)
COPY frontend/package.json frontend/bun.lockb ./frontend/
RUN cd frontend && bun install --frozen-lockfile
COPY frontend/ ./frontend/
RUN cd frontend && bun run build

# Stage 2: Backend Execution (Python 3.11+ for ADK)
FROM python:3.11-slim
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Install dependencies
COPY backend/pyproject.toml backend/uv.lock ./
RUN uv sync --frozen

# Copy Application logic
COPY backend/ ./backend/
COPY --from=base /app/frontend/dist ./frontend/dist

# Environment variables for A2A and Gemini
ENV PORT=8080
EXPOSE 8080

CMD ["uv", "run", "python", "-m", "backend.main"]
