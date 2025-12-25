# Lornu AI - Development & Operations Makefile

# Colors for output
BLUE         := $(shell printf "\033[34m")
GREEN        := $(shell printf "\033[32m")
YELLOW       := $(shell printf "\033[33m")
RED          := $(shell printf "\033[31m")
NC           := $(shell printf "\033[0m") # No Color

.PHONY: help setup deploy test dev clean tf-plan tf-apply logs check web-run api-run install fmt

# Default target
help:
	@echo "$(BLUE)Lornu AI Management Commands:$(NC)"
	@echo ""
	@echo "$(YELLOW)Local (Minikube + Podman):$(NC)"
	@echo "  $(BLUE)make setup$(NC)      - Initialize Minikube and build the local container image"
	@echo "  $(BLUE)make deploy$(NC)     - Deploy to local 'lornu-dev' namespace using Kustomize"
	@echo "  $(BLUE)make test$(NC)       - Run smoke tests against the local deployment"
	@echo "  $(BLUE)make dev$(NC)        - Full local cycle: setup -> deploy -> test"
	@echo "  $(BLUE)make clean$(NC)      - Remove local Kubernetes resources"
	@echo "  $(BLUE)make logs$(NC)       - Tail logs from the local lornu-ai pods"
	@echo "  $(BLUE)make check$(NC)      - Check status of local pods and services"
	@echo ""
	@echo "$(YELLOW)Infrastructure (Terraform):$(NC)"
	@echo "  $(BLUE)make tf-plan$(NC)    - Show Terraform plan for GCP infrastructure"
	@echo "  $(BLUE)make tf-apply$(NC)   - Apply Terraform changes to GCP infrastructure"
	@echo ""
	@echo "$(YELLOW)Application Development:$(NC)"
	@echo "  $(BLUE)make install$(NC)     - Install all dependencies (Web + API)"
	@echo "  $(BLUE)make web-run$(NC)     - Start Vite development server"
	@echo "  $(BLUE)make api-run$(NC)     - Start Python API backend locally"
	@echo ""
	@echo "$(YELLOW)Utility:$(NC)"
	@echo "  $(BLUE)make fmt$(NC)         - Format code (Terraform)"

# Local Kubernetes Targets
setup:
	@echo "$(BLUE)🚀 Setting up local Kubernetes environment...$(NC)"
	@chmod +x scripts/local-k8s-setup.sh
	./scripts/local-k8s-setup.sh
	@echo "$(GREEN)✓ Local setup complete!$(NC)"

deploy:
	@echo "$(BLUE)📦 Deploying application to lornu-dev...$(NC)"
	@chmod +x scripts/local-k8s-deploy.sh
	./scripts/local-k8s-deploy.sh
	@echo "$(GREEN)✓ Deployment complete!$(NC)"

test:
	@echo "$(BLUE)🔍 Running smoke tests...$(NC)"
	@chmod +x scripts/local-k8s-test.sh
	./scripts/local-k8s-test.sh

dev: setup deploy test
	@echo "$(GREEN)✨ Local development environment is ready!$(NC)"

clean:
	@echo "$(YELLOW)🗑 Cleaning local Kubernetes resources...$(NC)"
	kubectl delete namespace lornu-dev --ignore-not-found
	@echo "$(GREEN)✓ Cleaned$(NC)"

logs:
	@echo "$(BLUE)📋 Tailing logs from lornu-ai pods...$(NC)"
	kubectl logs -f -l app=lornu-ai -n lornu-dev

check:
	@echo "$(BLUE)📊 Current Cluster Status (lornu-dev):$(NC)"
	kubectl get pods,svc,ingress -n lornu-dev

# Application Development Targets
install:
	@echo "$(BLUE)Installing dependencies...$(NC)"
	cd apps/web && npm install
	cd packages/api && pip install -r requirements.txt

web-run:
	@echo "$(BLUE)Starting Web frontend (Vite)...$(NC)"
	cd apps/web && npm run dev

api-run:
	@echo "$(BLUE)Starting API backend (Python)...$(NC)"
	cd packages/api && python main.py

# Infrastructure Targets
tf-plan:
	@echo "$(BLUE)📖 Planning GCP infrastructure...$(NC)"
	@cd terraform/gcp && terraform plan

tf-apply:
	@echo "$(BLUE)🚀 Applying GCP infrastructure changes...$(NC)"
	@cd terraform/gcp && terraform apply -auto-approve

# Utility Targets
fmt:
	@echo "$(BLUE)🖌 Formatting code...$(NC)"
	terraform -chdir=terraform/gcp fmt
