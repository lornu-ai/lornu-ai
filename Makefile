.PHONY: help install dev build test lint clean format docker-build docker-run

# Color output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help:
	@echo "$(BLUE)Lornu AI Development Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Frontend Commands:$(NC)"
	@echo "  make install          - Install frontend dependencies (bun)"
	@echo "  make dev              - Start Vite dev server (http://localhost:5174)"
	@echo "  make build            - Build React app for production"
	@echo "  make test             - Run unit/integration tests (vitest)"
	@echo "  make test-watch       - Run tests in watch mode"
	@echo "  make test:e2e         - Run e2e smoke tests (playwright)"
	@echo "  make test:contact     - Test contact form endpoint"
	@echo "  make lint             - Run ESLint"
	@echo "  make format           - Format code with prettier"
	@echo ""
	@echo "$(GREEN)Backend Commands:$(NC)"
	@echo "  make api-install      - Install API dependencies (uv)"
	@echo "  make api-run          - Run FastAPI server locally"
	@echo "  make api-lint         - Lint Python code (ruff)"
	@echo "  make api-test         - Run API tests (pytest)"
	@echo ""
	@echo "$(GREEN)Docker Commands:$(NC)"
	@echo "  make docker-build     - Build Docker image locally"
	@echo "  make docker-run       - Run Docker container locally"
	@echo ""
	@echo "$(GREEN)Utility Commands:$(NC)"
	@echo "  make clean            - Clean build artifacts and caches"
	@echo "  make health-check     - Test API /health endpoint"
	@echo "  make setup            - Full local setup (install + dependencies)"
	@echo ""

# Frontend targets
install:
	@echo "$(BLUE)Installing frontend dependencies...$(NC)"
	cd apps/web && bun install

dev:
	@echo "$(BLUE)Starting Vite dev server...$(NC)"
	cd apps/web && bun run dev

build:
	@echo "$(BLUE)Building React app...$(NC)"
	cd apps/web && bun run build

test:
	@echo "$(BLUE)Running unit/integration tests...$(NC)"
	cd apps/web && bun run test:run

test-watch:
	@echo "$(BLUE)Running tests in watch mode...$(NC)"
	cd apps/web && bun run test

test:e2e:
	@echo "$(BLUE)Running e2e smoke tests...$(NC)"
	cd apps/web && bun run test:e2e:smoke

test:contact:
	@echo "$(BLUE)Testing contact form...$(NC)"
	cd apps/web && bun run test:contact

lint:
	@echo "$(BLUE)Running ESLint...$(NC)"
	cd apps/web && bun run lint

format:
	@echo "$(BLUE)Formatting code...$(NC)"
	cd apps/web && bun run format

# Backend targets
api-install:
	@echo "$(BLUE)Installing API dependencies...$(NC)"
	cd packages/api && uv sync

api-run:
	@echo "$(BLUE)Starting FastAPI server (port 8080)...$(NC)"
	cd packages/api && uv run python -m packages.api.main

api-lint:
	@echo "$(BLUE)Linting Python code...$(NC)"
	cd packages/api && uv run ruff check .

api-test:
	@echo "$(BLUE)Running API tests...$(NC)"
	cd packages/api && uv run pytest

# Docker targets
docker-build:
	@echo "$(BLUE)Building Docker image...$(NC)"
	docker build -t lornu-ai:latest .
	@echo "$(GREEN)✓ Built lornu-ai:latest$(NC)"

docker-run:
	@echo "$(BLUE)Running Docker container...$(NC)"
	docker run -p 8080:8080 -e RESEND_API_KEY="${RESEND_API_KEY}" lornu-ai:latest
	@echo "$(GREEN)✓ Container running on http://localhost:8080$(NC)"

# Utility targets
clean:
	@echo "$(BLUE)Cleaning build artifacts...$(NC)"
	rm -rf apps/web/dist apps/web/.vite apps/web/node_modules
	rm -rf packages/api/__pycache__ packages/api/.pytest_cache packages/api/.venv
	rm -rf terraform/aws/production/.terraform terraform/aws/production/tfplan*
	@echo "$(GREEN)✓ Cleaned$(NC)"

health-check:
	@echo "$(BLUE)Checking API health...$(NC)"
	@curl -s http://localhost:8080/api/health | jq . || echo "API not responding. Start with: make api-run"

setup: install api-install
	@echo "$(GREEN)✓ Setup complete. Run 'make dev' and 'make api-run' to start development$(NC)"

# Development workflow
.PHONY: dev-setup dev-start
dev-setup: clean setup
	@echo "$(GREEN)✓ Full development environment ready$(NC)"

dev-start:
	@echo "$(BLUE)Starting development environment...$(NC)"
	@echo "$(YELLOW)Frontend will start on http://localhost:5174$(NC)"
	@echo "$(YELLOW)API will run on http://localhost:8080$(NC)"
	@echo "$(YELLOW)Open two terminals and run:$(NC)"
	@echo "  Terminal 1: $(BLUE)make dev$(NC)"
	@echo "  Terminal 2: $(BLUE)make api-run$(NC)"
