.PHONY: setup cluster-up build deploy-local logs clean help

# Default target
help:
	@echo "Lornu AI Local Development Tooling"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@echo "  setup         - Verify local installs of uv, bun, podman, and kubectl"
	@echo "  cluster-up    - Initialize the local cluster (Minikube or k3s)"
	@echo "  build         - Build the unified Lornu AI OCI image using podman"
	@echo "  deploy-local  - Deploy to local kubernetes cluster"
	@echo "  logs          - Stream logs from the lornu-dev namespace"
	@echo "  clean         - Tear down local cluster and clean up Podman images"
	@echo "  help          - Show this help message"
	@echo ""

# Check dependencies
setup:
	@echo "Checking dependencies..."
	@command -v uv >/dev/null 2>&1 || { echo "uv is required but not installed. Please install uv."; exit 1; }
	@command -v bun >/dev/null 2>&1 || { echo "bun is required but not installed. Please install bun."; exit 1; }
	@command -v podman >/dev/null 2>&1 || { echo "podman is required but not installed. Please install podman."; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed. Please install kubectl."; exit 1; }
	@echo "All dependencies are installed!"

# Start local cluster
cluster-up:
	@echo "Starting local cluster..."
	@if command -v minikube >/dev/null 2>&1; then \
		minikube start --driver=podman; \
	elif command -v k3s >/dev/null 2>&1; then \
		echo "k3s detected, please ensure it's running"; \
	else \
		echo "Neither minikube nor k3s found. Please install one of them."; \
		exit 1; \
	fi
	@echo "Cluster is up!"

# Build container image
build:
	@echo "Building Lornu AI container image..."
	@cd apps/web && bun install && bun run build
	@cd packages/api && uv sync
	@podman build -t lornu-ai:latest .
	@echo "Build complete!"

# Deploy to local cluster
deploy-local:
	@echo "Deploying to local cluster..."
	@if [ ! -d "kubernetes/overlays/local" ]; then \
		echo "Local overlay not found. Creating it..."; \
		mkdir -p kubernetes/overlays/local; \
	fi
	@kubectl apply -k kubernetes/overlays/local
	@echo "Deployment complete!"

# Show logs
logs:
	@echo "Streaming logs from lornu-dev namespace..."
	@kubectl logs -n lornu-dev -f deployment/lornu-ai

# Clean up
clean:
	@echo "Cleaning up..."
	@if command -v minikube >/dev/null 2>&1; then \
		minikube stop; \
		minikube delete; \
	fi
	@podman rmi -f lornu-ai:latest 2>/dev/null || true
	@echo "Cleanup complete!"
