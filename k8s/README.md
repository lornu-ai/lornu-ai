# Kubernetes Deployment with Kustomize

This directory contains Kubernetes manifests organized using Kustomize for multi-environment deployments.

## Directory Structure

```
k8s/
├── base/                       # Base, environment-agnostic manifests
│   ├── deployment.yaml         # Core Deployment configuration
│   ├── service.yaml            # Service configuration
│   ├── configmap.yaml          # Base ConfigMap
│   └── kustomization.yaml      # Kustomize base configuration
└── overlays/                   # Environment-specific overlays
    ├── dev/                    # Local development
    │   └── kustomization.yaml  # Dev-specific patches and configs
    └── staging/                # AWS staging environment
        └── kustomization.yaml  # Staging-specific patches and configs
```

## Base Manifests

The `base/` directory contains environment-agnostic Kubernetes resources:
- **Deployment**: Defines the Lornu AI application deployment with 2 replicas
- **Service**: Exposes the application on port 80, routing to container port 8080
- **ConfigMap**: Contains base configuration (LOG_LEVEL, ENVIRONMENT)

## Environment Overlays

### Development (`overlays/dev`)

Local development overlay with:
- **Image**: `localhost:5000/lornu-ai:dev` (local registry)
- **Replicas**: 1
- **Resources**: Lower limits (128Mi/100m CPU)
- **Config**: Debug logging, development environment
- **Name prefix**: `dev-`

**Usage:**
```bash
# Build and view manifests
kustomize build k8s/overlays/dev

# Apply to local Kubernetes cluster
kustomize build k8s/overlays/dev | kubectl apply -f -

# Or use the npm script (from apps/web):
bun run dev:k8s
```

### Staging (`overlays/staging`)

AWS staging environment overlay with:
- **Image**: `<AWS_ECR_REGISTRY>/lornu-ai:staging-latest`
- **Replicas**: 3
- **Resources**: Higher limits (1Gi/1000m CPU)
- **Config**: Info logging, staging environment, staging URL
- **Name prefix**: `staging-`

**Usage:**
```bash
# Build and view manifests
kustomize build k8s/overlays/staging

# Apply to staging cluster (via CI/CD)
kustomize build k8s/overlays/staging | kubectl apply -f -
```

## CI/CD Integration

The GitHub Actions workflow (`.github/workflows/terraform.yml`) automatically:
1. Runs Terraform to provision infrastructure
2. Builds Kustomize manifests for staging
3. Substitutes the `<AWS_ECR_REGISTRY>` placeholder with the actual ECR registry URL
   - Format: `<account-id>.dkr.ecr.<region>.amazonaws.com`
   - Uses `AWS_ACCOUNT_ID` and `AWS_DEFAULT_REGION` secrets
4. (Future) Applies manifests to EKS cluster

**Registry Placeholder Substitution:**

The staging overlay uses `<AWS_ECR_REGISTRY>` as a placeholder that gets replaced during CI/CD:
```yaml
images:
  - name: lornu-ai
    newName: <AWS_ECR_REGISTRY>/lornu-ai  # Replaced at build time
    newTag: staging-latest
```

This is automatically substituted by the CI/CD pipeline using:
```bash
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
sed "s|<AWS_ECR_REGISTRY>|${ECR_REGISTRY}|g" staging-manifests-template.yaml > staging-manifests.yaml
```

## Adding a New Environment

To add a new environment (e.g., production):

1. Create a new overlay directory:
   ```bash
   mkdir -p k8s/overlays/production
   ```

2. Create `kustomization.yaml`:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   resources:
     - ../../base
   
   namePrefix: prod-
   namespace: production
   
   images:
     - name: lornu-ai
       newName: <REGISTRY>/lornu-ai
       newTag: production-latest
   
   configMapGenerator:
     - name: lornu-ai-config
       behavior: merge
       literals:
         - LOG_LEVEL=warn
         - ENVIRONMENT=production
   ```

3. Add environment-specific patches as needed

## Best Practices

1. **Never modify base manifests** for environment-specific values
2. **Use overlays** to customize resources for each environment
3. **Use configMapGenerator** for environment-specific configuration
4. **Use images** field to manage container image tags
5. **Test locally** before deploying to staging/production:
   ```bash
   kustomize build k8s/overlays/dev | kubectl diff -f -
   ```

## Prerequisites

- **Kustomize**: v5.0.0+ (`brew install kustomize` or download from releases)
- **kubectl**: v1.24+ for local testing
- **Docker**: For building and pushing images
- **Local registry** (optional for dev): `docker run -d -p 5000:5000 registry:2`

## Troubleshooting

**Issue**: `error: no matches for kind "Deployment"`
- **Solution**: Ensure kubectl is connected to a Kubernetes cluster

**Issue**: Image pull failures in dev
- **Solution**: Build and push image to local registry:
  ```bash
  docker build -t localhost:5000/lornu-ai:dev .
  docker push localhost:5000/lornu-ai:dev
  ```

**Issue**: ConfigMap changes not applying
- **Solution**: Kustomize generates unique ConfigMap names. Delete old deployment:
  ```bash
  kubectl delete deployment <deployment-name>
  kustomize build k8s/overlays/dev | kubectl apply -f -
  ```

## References

- [Kustomize Documentation](https://kustomize.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
