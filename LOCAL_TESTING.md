# Local Development & Testing Guide

Fast workflow using **Podman**, **Minikube**, and **Kustomize**.

## Prerequisites

```bash
brew install podman minikube kubectl kustomize
podman machine init
podman machine start
```

## Quick Start (The Makefile Way)

The easiest way to get started is using the `Makefile`:

```bash
# 1. Setup, Deploy, and Test everything in one command
make dev

# 2. Or run steps individually
make setup   # Initialize Minikube & Build image
make deploy  # Deploy to 'lornu-dev' namespace
make test    # Run smoke tests
```

## Accessing the App

Once deployed, you can access the app locally:

```bash
kubectl port-forward svc/lornu-ai 8080:80 -n lornu-dev
# Visit http://localhost:8080
```

## What This Does (Under the Hood)

The `Makefile` targets call the following scripts:

1. **`make setup`** (`local-k8s-setup.sh`):
   - Starts minikube using the `podman` driver (fallback to docker)
   - Auto-configures the environment (`minikube podman-env`)
   - Builds the container image locally within minikube's runtime

2. **`make deploy`** (`local-k8s-deploy.sh`):
   - Applies Kustomize manifests from `k8s/overlays/lornu-dev`
   - Resources are deployed in the `lornu-dev` namespace
   - Waits for the deployment to be healthy

3. **`make test`** (`local-k8s-test.sh`):
   - Tests availability of the service in the `lornu-dev` namespace
   - Checks pod logs for bootstrap errors
   - Validates service response via temporary port-forward

4. **`make clean`**:
   - Removes the `lornu-dev` namespace and all its resources

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
