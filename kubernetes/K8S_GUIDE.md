# Kubernetes Configuration (Kustomize)

Deploy Lornu AI to AWS EKS and local Kubernetes clusters (minikube, K3s) using Kustomize.

## Directory Structure

```
kubernetes/
├── base/                 # Base manifests (platform-agnostic)
│   ├── serviceaccount.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── ingress.yaml
│   └── kustomization.yaml
└── overlays/             # Environment-specific patches
    ├── dev/              # Local development (minikube/K3s)
    ├── staging/          # AWS EKS Staging
    └── production/       # AWS EKS Production
```

## Base Manifests

The `base/` directory defines the core Kubernetes resources:

- **Deployment**: FastAPI backend with health probes and security context
- **Service**: ClusterIP service exposing port 8080
- **ConfigMap**: Non-sensitive configuration (environment, contact email)
- **Ingress**: ALB Ingress Controller annotations for AWS Load Balancer
- **ServiceAccount**: IRSA (IAM Roles for Service Accounts) support

### Environment Variables

The deployment injects secrets and config via:

```yaml
env:
  - name: RESEND_API_KEY         # From secret
  - name: CONTACT_EMAIL          # From configmap
  - name: RATE_LIMIT_BYPASS_SECRET  # From secret
```

Secrets must be created separately in the cluster:
```bash
kubectl create secret generic lornu-ai-secrets \
  --from-literal=resend-api-key="..." \
  --from-literal=rate-limit-bypass-secret="..."
```

## Overlays

### Development (`kubernetes/overlays/dev`)

Local minikube or K3s setup with:
- 1 replica (minimal resource usage)
- Local image (`lornu-ai:local`)
- Debug logging

### Staging (`kubernetes/overlays/staging`)

AWS EKS staging cluster with:
- 2 replicas
- ECR image: `148080843892.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging`
- Standard resources (256Mi / 250m CPU requests, 512Mi / 500m limits)
- Debug logging

Apply:
```bash
kustomize build kubernetes/overlays/staging | kubectl apply -f -
```

### Production (`kubernetes/overlays/production`)

AWS EKS production cluster with:
- 3 replicas
- ECR image: `148080843892.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-production`
- Higher resources (512Mi / 500m CPU requests, 1Gi / 1000m limits)
- Pod anti-affinity to spread across nodes
- Production logging

Apply:
```bash
kustomize build kubernetes/overlays/production | kubectl apply -f -
```

## Local Development

### Quick Start with Minikube

1. Start the local cluster and build the image:
   ```bash
   ./scripts/local-k8s-setup.sh
   ```

2. Deploy to minikube:
   ```bash
   ./scripts/local-k8s-deploy.sh
   ```

3. Run smoke tests:
   ```bash
   ./scripts/local-k8s-test.sh
   ```

4. Access the app:
   ```bash
   kubectl port-forward svc/lornu-ai 8080:8080
   open http://localhost:8080
   ```

## AWS EKS Deployment

### Prerequisites

- EKS cluster running (provisioned via `terraform/aws/staging/eks.tf`)
- kubectl configured with EKS cluster credentials
- kustomize installed

### Staging Deployment

1. Build and push the Docker image:
   ```bash
   docker build -t 148080843892.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:$(git rev-parse --short HEAD) .
   docker push 148080843892.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:$(git rev-parse --short HEAD)
   ```

2. Update kubeconfig:
   ```bash
   aws eks update-kubeconfig --name lornu-ai-staging --region us-east-1
   ```

3. Deploy with Kustomize:
   ```bash
   kustomize build kubernetes/overlays/staging | kubectl apply -f -
   ```

4. Check deployment status:
   ```bash
   kubectl get deployments -l environment=staging
   kubectl logs -l app.kubernetes.io/name=lornu-ai
   ```

## Customization

### Updating the Image Tag

Modify `kubernetes/overlays/staging/kustomization.yaml`:
```yaml
images:
- name: lornu-ai
  newTag: v1.2.3  # Change to your desired tag
```

### Adding Environment Variables

Add to the overlay's `kustomization.yaml`:
```yaml
configMapGenerator:
- name: lornu-ai-config
  behavior: merge
  literals:
  - my-env-var=value
```

### Resource Scaling

Modify the overlay's `kustomization.yaml`:
```yaml
replicas:
- name: staging-lornu-ai
  count: 5  # Scale to 5 replicas
```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod -l app.kubernetes.io/name=lornu-ai
kubectl logs -l app.kubernetes.io/name=lornu-ai --all-containers=true
```

### Image pull errors

Ensure ECR credentials are configured:
```bash
kubectl create secret docker-registry ecr-creds \
  --docker-server=148080843892.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)
```

Then reference in deployment patch:
```yaml
imagePullSecrets:
- name: ecr-creds
```

## Security

- Pods run as non-root user (UID 1000)
- Read-only root filesystem
- No privilege escalation
- Dropped all Linux capabilities
- Network policies recommended for production

See [kubernetes/base/deployment.yaml](base/deployment.yaml) for full security context.
