# Local Development & Testing Guide

Fast workflow using **Podman**, **Minikube**, and **Kustomize**.

## Prerequisites

```bash
brew install podman minikube kubectl kustomize
podman machine init
podman machine start
```

## Quick Start (5 minutes)

```bash
# 1. Setup local Kubernetes with minikube
chmod +x scripts/local-k8s-*.sh
./scripts/local-k8s-setup.sh

# 2. Deploy to local cluster
./scripts/local-k8s-deploy.sh

# 3. Test the deployment
./scripts/local-k8s-test.sh

# 4. Access the app
kubectl port-forward svc/dev-lornu-ai 8080:8080
# Visit http://localhost:8080
```

## Using Make Targets (Recommended)

The Makefile provides convenient shortcuts:

```bash
# K3s + Kustomize (lightweight, recommended)
make k3s-dev          # Start cluster and deploy
make k3s-logs         # View application logs
make k3s-check        # Check cluster status
make k3s-stop         # Clean up

# Or standard Minikube
make minikube-start
make minikube-deploy
make minikube-logs
make minikube-stop
```

## What The Setup Scripts Do

### 1. `local-k8s-setup.sh`
- Starts minikube using the `podman` driver (fallback to docker)
- Auto-configures the environment (`minikube podman-env`)
- Builds the container image locally within minikube's runtime

### 2. `local-k8s-deploy.sh`
- Applies Kustomize manifests from `k8s/overlays/dev`
- Resources are prefixed with `dev-` (e.g., `dev-lornu-ai`)
- Waits for the deployment to be healthy

### 3. `local-k8s-test.sh`
- Tests health endpoint (`/api/health`)
- Tests frontend serving
- Validates deployment is working

### 4. `local-k8s-cleanup.sh`
- Removes all k8s resources
- Optionally removes container images
- Optionally stops minikube

## Development Workflow

### Local Testing

```bash
# Make code changes
vim apps/web/src/App.tsx

# Rebuild image
eval $(minikube podman-env)
podman build -t lornu-ai:local .

# Redeploy
kubectl rollout restart deployment/dev-lornu-ai

# Watch logs
kubectl logs -f -l app.kubernetes.io/name=lornu-ai

# Debug
kubectl describe pod -l app.kubernetes.io/name=lornu-ai
```

### Frontend/Backend Development

```bash
# Terminal 1: Frontend
make dev

# Terminal 2: Backend
make api-run

# Terminal 3: Monitor local K8s (optional)
make k3s-logs
```

## Deploy to AWS (Production)

Once local testing passes:

```bash
# 1. Ensure your PR is merged to develop
# 2. Create PR: develop → main
# 3. Once approved and merged to main, the CI will auto-deploy

# Or manually trigger:
gh workflow run terraform-aws-prod.yml

# Monitor via GitHub Actions:
# https://github.com/lornu-ai/lornu-ai/actions
```

## Troubleshooting

### Image not found in minikube

```bash
eval $(minikube podman-env)
podman images | grep lornu-ai

# If missing, rebuild:
podman build -t lornu-ai:local .
```

### Pod CrashLoopBackOff

```bash
# Check logs
kubectl logs -l app.kubernetes.io/name=lornu-ai

# Describe the pod
kubectl describe pod -l app.kubernetes.io/name=lornu-ai

# Common issues:
# 1. Image not found → rebuild with podman
# 2. Port already in use → change port in kustomize patch
# 3. Config error → check configmap with: kubectl get configmap
```

### Port forward not working

```bash
# Check service exists
kubectl get svc lornu-ai

# Use minikube service instead
minikube service lornu-ai

# Or use kubectl port-forward
kubectl port-forward svc/dev-lornu-ai 8080:8080
```

### Minikube cluster issues

```bash
# Check cluster status
minikube status

# Restart minikube
minikube stop
minikube delete
make k3s-start  # or ./scripts/local-k8s-setup.sh

# Check logs
minikube logs
```

### Kustomize validation errors

```bash
# Validate manifests before applying
kubectl kustomize k8s/overlays/dev

# Check what resources will be created
kubectl apply -k k8s/overlays/dev --dry-run=client -o yaml

# View specific resource
kubectl get deployment dev-lornu-ai -o yaml
```

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│         Local Development Environment           │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐                              │
│  │ Podman       │  Container runtime           │
│  │ (or Docker)  │                              │
│  └──────────────┘                              │
│         │                                      │
│         ▼                                      │
│  ┌──────────────┐                              │
│  │  Minikube    │  Local K8s cluster          │
│  │  + K3s       │  (lightweight or standard)  │
│  └──────────────┘                              │
│         │                                      │
│         ▼                                      │
│  ┌──────────────────────────────────────────┐  │
│  │        Kustomize Overlays                │  │
│  │  k8s/overlays/dev                        │  │
│  │  - Deployments (dev-lornu-ai)            │  │
│  │  - Services (dev-lornu-ai)               │  │
│  │  - ConfigMaps                            │  │
│  │  - Secrets                               │  │
│  └──────────────────────────────────────────┘  │
│                                                 │
└─────────────────────────────────────────────────┘
         │
         │ Code changes pushed
         ▼
┌─────────────────────────────────────────────────┐
│      GitHub Actions CI/CD Pipeline              │
├─────────────────────────────────────────────────┤
│  1. Build & push image to ECR                  │
│  2. Run Terraform (infrastructure)             │
│  3. Deploy via Kustomize to EKS                │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│        AWS Production Environment               │
├─────────────────────────────────────────────────┤
│  - EKS Cluster                                 │
│  - CloudFront Distribution                    │
│  - Route53 DNS                                 │
│  - RDS Database                               │
│  - Secrets Manager                            │
└─────────────────────────────────────────────────┘
```

## Resource Comparison

| Environment | CPU | Memory | Storage | Cost |
|------------|-----|--------|---------|------|
| Local (minikube + K3s) | 4 cores | 4GB | Local disk | $0 |
| AWS Staging (EKS) | 500m | 512Mi | EBS | ~$30/mo |
| AWS Production (EKS) | 1000m | 1Gi | EBS | ~$60/mo |

**Save time & money**: Test locally first! ✨

## Make Targets Reference

### Container Building
```bash
make podman-build   # Build with Podman
make podman-run     # Run container
```

### Frontend Development
```bash
make install        # Install dependencies
make dev            # Start dev server
make build          # Build for production
make test           # Run tests
make lint           # Lint code
make format         # Format code
```

### Backend Development
```bash
make api-install    # Install API dependencies
make api-run        # Run API server
make api-lint       # Lint Python
make api-test       # Run API tests
```

### K8s Deployment (K3s - Lightweight)
```bash
make k3s-dev        # Start cluster + deploy
make k3s-start      # Start cluster
make k3s-build      # Build image for k3s
make k3s-deploy     # Deploy with Kustomize
make k3s-logs       # Tail pod logs
make k3s-check      # Check cluster status
make k3s-stop       # Stop cluster
```

### K8s Deployment (Minikube - Standard)
```bash
make minikube-start     # Start cluster
make minikube-build     # Build image
make minikube-deploy    # Deploy
make minikube-logs      # View logs
make minikube-stop      # Stop cluster
```

### Utilities
```bash
make help           # Show all targets
make setup          # Full local setup
make clean          # Clean artifacts
make health-check   # Test API health
```

## Common Development Scenarios

### Scenario 1: Test a new API endpoint

```bash
# 1. Make changes to packages/api/main.py
# 2. Build image (includes running api-test)
podman build -t lornu-ai:local .

# 3. Load into minikube
eval $(minikube podman-env)
podman build -t lornu-ai:local .

# 4. Restart deployment to pick up new image
kubectl rollout restart deployment/dev-lornu-ai

# 5. Test the endpoint
curl -X GET http://localhost:8080/api/your-new-endpoint

# 6. View logs if there are errors
kubectl logs -f -l app.kubernetes.io/name=lornu-ai
```

### Scenario 2: Test frontend changes

```bash
# 1. Make changes to apps/web/src
# 2. Run frontend dev server (separate from K8s)
make dev

# 3. Frontend rebuilds hot-reloads on http://localhost:5174
# 4. When satisfied, commit and push to develop
```

### Scenario 3: Test database changes

```bash
# 1. Update terraform/aws/production/rds.tf
# 2. Test locally by running API against local DB
# 3. Or use AWS RDS in staging for integration tests
# 4. Deploy to staging first, test, then to production
```

## Next Steps

- **Merge PR #284**: Makefile for all these commands
- **Run `make help`**: See all available targets
- **Try `make k3s-dev`**: Get a local K8s cluster running
- **Make code changes**: Use local K8s for rapid iteration
- **Push to develop**: Trigger automated AWS deployment

Happy coding! 🚀
