# Local Development & Testing Guide

Fast workflow for testing before deploying to AWS Fargate.

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
kubectl port-forward svc/lornu-ai 8080:8080
# Visit http://localhost:8080
```

## What This Does

1. **local-k8s-setup.sh**: 
   - Starts minikube with minimal resources (2 CPU, 4GB RAM)
   - Auto-detects podman or docker as container runtime
   - Enables registry, ingress, and metrics
   - Builds container image in minikube's environment

2. **local-k8s-deploy.sh**:
   - Applies Kustomize manifests from `kubernetes/overlays/dev`
   - Waits for deployment to be ready
   - Shows pod status

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

# Rebuild and redeploy
eval $(minikube docker-env)
docker build -t lornu-ai:local .
kubectl rollout restart deployment/lornu-ai

# Watch logs
kubectl logs -f -l app.kubernetes.io/name=lornu-ai

# Debug
kubectl describe pod -l app.kubernetes.io/name=lornu-ai
kubectl get events --sort-by=.metadata.creationTimestamp
```

## Deploy to AWS Fargate (Production)

Once local testing passes:

```bash
# 1. Ensure PR #146 is merged
# 2. Push to remote
git push origin develop

# 3. Trigger AWS deployment
gh workflow run terraform-aws.yml

# Or use GitHub UI:
# Actions → Terraform AWS → Run workflow
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

| Environment | CPU | Memory | Cost |
|------------|-----|--------|------|
| Local (minikube) | 250m | 256Mi | $0 |
| AWS Staging | 500m | 512Mi | ~$30/mo |
| AWS Production | 1000m | 1Gi | ~$60/mo |

**Save time & money**: Test locally first! ✨
