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
kubectl port-forward svc/lornu-ai 8080:8080 -n lornu-dev
# Visit http://localhost:8080
```

## What This Does

1. **local-k8s-setup.sh**:
   - Starts minikube using the `podman` driver (fallback to docker)
   - Auto-configures the environment (`minikube podman-env`)
   - Builds the container image locally within minikube's runtime

2. **local-k8s-deploy.sh**:
   - Applies Kustomize manifests from `k8s/overlays/lornu-dev`
   - Resources are deployed in the `lornu-dev` namespace
   - Waits for the deployment to be healthy

3. **local-k8s-test.sh**:
   - Tests health endpoint (`/api/health`)
   - Tests frontend serving
   - Validates deployment is working

4. **local-k8s-cleanup.sh**:
   - Removes all k8s resources
   - Optionally removes Docker images
   - Optionally stops minikube

## Development Workflow

```bash
# Make code changes
vim apps/web/src/App.tsx

# Rebuild and redeploy (using Podman)
eval $(minikube podman-env)
podman build -t lornu-ai:local .
kubectl rollout restart deployment/lornu-ai -n lornu-dev

# Watch logs
kubectl logs -f -l app.kubernetes.io/name=lornu-ai -n lornu-dev

# Debug
kubectl describe pod -l app.kubernetes.io/name=lornu-ai -n lornu-dev
```

## Deploy to Google Cloud (GKE)

Once local testing passes:

1. **Push to remote branch**:
   ```bash
   git push origin gcp-develop
   ```

2. **Wait for Infrastructure**:
   The `GCP Terraform Deployment` workflow will verify and apply infrastructure changes.

3. **Deploy the Application**:
   The `GKE Build & Deploy` workflow will build the image, push to GAR, and update GKE.

4. **Monitor**:
   Use `kubectl` to check the cloud cluster after switching contexts:
   ```bash
   gcloud container clusters get-credentials lornu-ai-gke --region us-central1
   kubectl get pods -n lornu-dev
   ```

## Troubleshooting

### Image not found
```bash
eval $(minikube docker-env)
docker images | grep lornu-ai
# If missing, rebuild:
docker build -t lornu-ai:local .
```

### Pod CrashLoopBackOff
```bash
kubectl logs -l app.kubernetes.io/name=lornu-ai
kubectl describe pod -l app.kubernetes.io/name=lornu-ai
```

### Port forward not working
```bash
# Check service exists
kubectl get svc lornu-ai

# Use minikube service instead
minikube service lornu-ai
```

### Minikube issues
```bash
# Restart minikube
minikube stop
minikube delete
./scripts/local-k8s-setup.sh
```

## Resource Comparison

| Environment | Namespace | CPU | Memory | Replicas |
|------------|-----------|-----|--------|----------|
| Local (minikube) | `lornu-dev` | 100m | 128Mi | 1 |
| GKE Dev | `lornu-dev` | 100m | 128Mi | 1 |
| GKE Staging | `lornu-stage` | 250m | 256Mi | 2 |
| GKE Production | `lornu-prod` | 500m | 512Mi | 3 |

**Save time & money**: Test locally first! ✨
