# Lornu AI - Development & Operations Makefile

.PHONY: help setup deploy test dev clean tf-plan tf-apply

# Default target
help:
	@echo "Lornu AI Management Commands:"
	@echo "  Local (Minikube + Podman):"
	@echo "    setup      - Initialize Minikube and build the local container image"
	@echo "    deploy     - Deploy the application to the local 'lornu-dev' namespace"
	@echo "    test       - Run smoke tests against the local deployment"
	@echo "    dev        - Full local cycle: setup -> deploy -> test"
	@echo "    clean      - Remove local Kubernetes resources"
	@echo ""
	@echo "  Infrastructure (Terraform):"
	@echo "    tf-plan    - Show Terraform plan for GCP infrastructure"
	@echo "    tf-apply   - Apply Terraform changes to GCP infrastructure"
	@echo ""
	@echo "  Utility:"
	@echo "    fmt        - Format all code (Python, Terraform, etc.)"

# Local Kubernetes Targets
setup:
	@chmod +x scripts/local-k8s-setup.sh
	./scripts/local-k8s-setup.sh

deploy:
	@chmod +x scripts/local-k8s-deploy.sh
	./scripts/local-k8s-deploy.sh

test:
	@chmod +x scripts/local-k8s-test.sh
	./scripts/local-k8s-test.sh

dev: setup deploy test

clean:
	@echo "🗑 Cleaning local Kubernetes resources..."
	kubectl delete namespace lornu-dev --ignore-not-found

# Infrastructure Targets
tf-plan:
	@cd terraform/gcp && terraform plan

tf-apply:
	@cd terraform/gcp && terraform apply -auto-approve

# Utility Targets
fmt:
	@echo "🖌 Formatting code..."
	terraform -chdir=terraform/gcp fmt
	# Add other formatters (ruff, prettier, etc.) as needed
