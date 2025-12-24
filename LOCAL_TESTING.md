# Local Development & Testing Guide

Fast workflow for testing before deploying to AWS EKS.

## Quick Start (5 minutes)

```bash
# 1. Setup local Kubernetes with k3s (k3d)
chmod +x scripts/local-k8s-*.sh
./scripts/local-k8s-setup.sh

# 2. Deploy to local cluster
./scripts/local-k8s-deploy.sh

# 3. Test the deployment
./scripts/local-k8s-test.sh

# 4. Access the app
kubectl port-forward svc/dev-lornu-ai 8080:80
# Visit http://localhost:8080
```

## What This Does

1. **local-k8s-setup.sh**: 
   - Creates a k3d k3s cluster (`lornu-dev`)
   - Auto-detects podman or docker as container runtime
   - Creates a local registry (`lornu-registry.localhost:5000`)
   - Builds and pushes the local image

2. **local-k8s-deploy.sh**:
   - Applies Kustomize manifests from `k8s/overlays/dev`
   - Waits for deployment to be ready
   - Shows pod status

3. **local-k8s-test.sh**:
   - Tests health endpoint (`/api/health`)
   - Tests frontend serving
   - Validates deployment is working

4. **local-k8s-cleanup.sh**:
   - Removes all k8s resources
   - Optionally removes local images
   - Optionally deletes k3d cluster and registry

## Development Workflow

```bash
# Make code changes
vim apps/web/src/App.tsx

# Rebuild and redeploy
podman build -t lornu-registry.localhost:5000/lornu-ai:local .
podman push lornu-registry.localhost:5000/lornu-ai:local
kubectl rollout restart deployment -l app.kubernetes.io/name=lornu-ai

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
podman images | grep lornu-registry.localhost:5000/lornu-ai
# If missing, rebuild:
podman build -t lornu-registry.localhost:5000/lornu-ai:local .
podman push lornu-registry.localhost:5000/lornu-ai:local
```

### Pod CrashLoopBackOff
```bash
kubectl logs -l app.kubernetes.io/name=lornu-ai
kubectl describe pod -l app.kubernetes.io/name=lornu-ai
```

### Port forward not working
```bash
# Check service exists
kubectl get svc -l app=lornu-ai

# Port-forward using the dev service name
kubectl port-forward svc/dev-lornu-ai 8080:80
```

### k3d issues
```bash
# Restart k3d
k3d cluster delete lornu-dev
./scripts/local-k8s-setup.sh
```

## Resource Comparison

| Environment | CPU | Memory | Cost |
|------------|-----|--------|------|
| Local (k3d) | 250m | 256Mi | $0 |
| AWS Staging | 500m | 512Mi | ~$30/mo |
| AWS Production | 1000m | 1Gi | ~$60/mo |

**Save time & money**: Test locally first! ✨
