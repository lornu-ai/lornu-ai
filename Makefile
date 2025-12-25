.PHONY: help install dev build test lint clean format podman-build podman-run minikube-start minikube-build minikube-deploy minikube-logs minikube-stop k3s-start k3s-build k3s-deploy k3s-logs k3s-stop k3s-check

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
	@echo "$(GREEN)Podman Commands:$(NC)"
	@echo "  make podman-build      - Build image with Podman"
	@echo "  make podman-run        - Run container with Podman"
	@echo ""
	@echo "$(GREEN)Kubernetes (Minikube) Commands:$(NC)"
	@echo "  make minikube-start    - Start minikube cluster"
	@echo "  make minikube-build    - Build image in minikube"
	@echo "  make minikube-deploy   - Deploy to minikube with Kustomize"
	@echo "  make minikube-logs     - Tail logs from minikube pods"
	@echo "  make minikube-stop     - Stop minikube cluster"
	@echo ""
	@echo "$(GREEN)Kubernetes (K3s) Commands:$(NC)"
	@echo "  make k3s-start         - Start k3s cluster in minikube"
	@echo "  make k3s-build         - Build image for k3s"
	@echo "  make k3s-deploy        - Deploy to k3s with Kustomize"
	@echo "  make k3s-logs          - Tail logs from k3s pods"
	@echo "  make k3s-check         - Check k3s cluster status"
	@echo "  make k3s-stop          - Stop k3s cluster"
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

# Podman targets (replaces Docker)
podman-build:
	@echo "$(BLUE)Building image with Podman...$(NC)"
	podman build -t lornu-ai:latest .
	@echo "$(GREEN)✓ Built lornu-ai:latest$(NC)"

podman-run:
	@echo "$(BLUE)Running container with Podman...$(NC)"
	podman run -p 8080:8080 -e RESEND_API_KEY="${RESEND_API_KEY}" lornu-ai:latest
	@echo "$(GREEN)✓ Container running on http://localhost:8080$(NC)"

# Minikube targets (K8s local development)
minikube-start:
	@echo "$(BLUE)Starting minikube cluster...$(NC)"
	minikube start --cpus=4 --memory=4096
	@echo "$(GREEN)✓ Minikube cluster started$(NC)"
	@eval $$(minikube docker-env) && echo "$(YELLOW)Docker env configured for minikube$(NC)"

minikube-build:
	@echo "$(BLUE)Building image in minikube docker env...$(NC)"
	eval $$(minikube docker-env) && podman build -t lornu-ai:latest .
	@echo "$(GREEN)✓ Built lornu-ai:latest in minikube$(NC)"

minikube-deploy: build minikube-build
	@echo "$(BLUE)Deploying to minikube with Kustomize...$(NC)"
	kubectl apply -k k8s/overlays/dev
	@echo "$(GREEN)✓ Deployed to minikube$(NC)"
	@echo "$(YELLOW)Check status with: kubectl get pods -n default$(NC)"

minikube-logs:
	@echo "$(BLUE)Tailing logs from lornu-ai pods...$(NC)"
	kubectl logs -f deployment/lornu-ai -n default --all-containers=true 2>/dev/null || echo "No pods found. Deploy with: make minikube-deploy"

minikube-stop:
	@echo "$(BLUE)Stopping minikube cluster...$(NC)"
	minikube stop
	@echo "$(GREEN)✓ Minikube cluster stopped$(NC)"

minikube-status:
	@echo "$(BLUE)Minikube Status:$(NC)"
	minikube status
	@echo ""
	@echo "$(BLUE)Pods:$(NC)"
	kubectl get pods -n default

# K3s targets (lightweight K8s with full Kustomize support)
k3s-start:
	@echo "$(BLUE)Starting k3s cluster in minikube...$(NC)"
	minikube start --cpus=4 --memory=4096 --container-runtime=podman
	@echo "$(GREEN)✓ Minikube started$(NC)"
	@echo "$(BLUE)Installing k3s in minikube...$(NC)"
	minikube ssh "curl -sfL https://get.k3s.io | sh -"
	@echo "$(GREEN)✓ K3s cluster running$(NC)"
	@eval $$(minikube docker-env) && echo "$(YELLOW)Docker env configured$(NC)"

k3s-build: build
	@echo "$(BLUE)Building image for k3s...$(NC)"
	eval $$(minikube docker-env) && podman build -t lornu-ai:latest .
	@echo "$(GREEN)✓ Built lornu-ai:latest for k3s$(NC)"

k3s-deploy: k3s-build
	@echo "$(BLUE)Deploying to k3s with Kustomize...$(NC)"
	kubectl apply -k k8s/overlays/dev
	@echo "$(GREEN)✓ Deployed to k3s$(NC)"
	@echo "$(YELLOW)Check status with: make k3s-check$(NC)"

k3s-logs:
	@echo "$(BLUE)Tailing logs from lornu-ai pods...$(NC)"
	kubectl logs -f deployment/lornu-ai -n default --all-containers=true 2>/dev/null || echo "No pods found. Deploy with: make k3s-deploy"

k3s-check:
	@echo "$(BLUE)K3s Cluster Status:$(NC)"
	kubectl cluster-info
	@echo ""
	@echo "$(BLUE)Nodes:$(NC)"
	kubectl get nodes
	@echo ""
	@echo "$(BLUE)Pods:$(NC)"
	kubectl get pods -n default
	@echo ""
	@echo "$(BLUE)Services:$(NC)"
	kubectl get svc -n default

k3s-stop:
	@echo "$(BLUE)Stopping k3s cluster...$(NC)"
	minikube stop
	@echo "$(GREEN)✓ K3s cluster stopped$(NC)"

k3s-dev: k3s-start k3s-deploy
	@echo ""
	@echo "$(GREEN)✓ K3s + Kustomize environment ready$(NC)"
	@echo "$(YELLOW)View logs:$(NC)"
	@echo "  $(BLUE)make k3s-logs$(NC)"
	@echo "$(YELLOW)Check status:$(NC)"
	@echo "  $(BLUE)make k3s-check$(NC)"
	@echo "$(YELLOW)Stop cluster:$(NC)"
	@echo "  $(BLUE)make k3s-stop$(NC)"

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
.PHONY: dev-setup dev-start minikube-dev
dev-setup: clean setup
	@echo "$(GREEN)✓ Full development environment ready$(NC)"

dev-start:
	@echo "$(BLUE)Starting development environment...$(NC)"
	@echo "$(YELLOW)Frontend will start on http://localhost:5174$(NC)"
	@echo "$(YELLOW)API will run on http://localhost:8080$(NC)"
	@echo "$(YELLOW)Open two terminals and run:$(NC)"
	@echo "  Terminal 1: $(BLUE)make dev$(NC)"
	@echo "  Terminal 2: $(BLUE)make api-run$(NC)"

# Minikube development workflow

minikube-dev: minikube-start minikube-deploy
	@echo ""
	@echo "$(GREEN)✓ Minikube environment ready$(NC)"
	@echo "$(YELLOW)Access your app:$(NC)"
	@echo "  API: $(BLUE)minikube service lornu-ai -n default$(NC)"
	@echo "$(YELLOW)View logs:$(NC)"
	@echo "  $(BLUE)make minikube-logs$(NC)"
	@echo "$(YELLOW)Stop cluster:$(NC)"
	@echo "  $(BLUE)make minikube-stop$(NC)"
