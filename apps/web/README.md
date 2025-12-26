# Lornu AI Web App

A React + Vite web application deployed on **AWS EKS** and **Google GKE** via Kubernetes (Kustomize overlays). The application is containerized and orchestrated through Plan A's multi-namespace architecture.

## Architecture

This application runs as a containerized service on Kubernetes clusters with:

- **Multi-namespace isolation**: Deployed to `lornu-dev`, `lornu-staging`, `lornu-prod`
- **AWS EKS + ALB Ingress**: Production traffic routed via AWS Application Load Balancer
- **Google GKE**: Alternative deployment target via GCP
- **Kustomize overlays**: Environment-specific configuration without duplication
- **FastAPI backend**: Python backend (in `packages/api/`) handles API routes including `/api/contact`

### Key Components

- **`src/`**: React application source code (built with Vite + TypeScript)
- **`Dockerfile`**: Multi-stage container image (frontend build + backend FastAPI)
- **`kubernetes/base/`**: Source of truth Kubernetes manifests
- **`kubernetes/overlays/{dev,staging,prod}/`**: Environment-specific patches (replicas, TLS, resource limits)
- **`bun.lock`**: Bun-based dependency lock file

## Development

### Prerequisites

- Bun 1.3.0+ (package manager for frontend)
- Docker (for container testing)
- kubectl + Kustomize (for local K8s development)
- [Pre-commit](https://pre-commit.com/) (recommended for code quality & security)


### Development Tools (Pre-commit)

This project uses pre-commit hooks to enforce code quality and security standards (blocking secrets, checking syntax).

1.  **Install pre-commit:**
    ```bash
    brew install pre-commit  # macOS
    pip install pre-commit   # Universal
    ```

2.  **Install hooks in the repo:**
    ```bash
    pre-commit install
    ```

3.  **Run checks manually:**
    ```bash
    pre-commit run --all-files
    ```

### Quick Start (Local Development)

#### Option 1: Vite Dev Server (Fastest for UI Development)

```bash
# Install dependencies
bun install

# Run development server with Vite
bun dev
```

This starts the Vite dev server at `http://localhost:5173`. The FastAPI backend runs separately (see below).

#### Option 2: Local Kubernetes Deployment (K3s/Minikube)

For testing the full containerized deployment:

```bash
# Build the Docker image locally
docker build -t lornu-ai:dev .

# Deploy to local Kubernetes cluster
kubectl apply -k kubernetes/overlays/dev
```

To access the service:
```bash
# Port-forward the service
kubectl port-forward -n lornu-dev svc/lornu-ai 5173:80
# Access at http://localhost:5173
```

### Build

Build the production bundle:
```bash
bun run build
```

The output is generated in the `dist/` directory.

### Package Manager Switch to Bun

**Why Bun?**
- 🚀 **55% smaller lock file** (138 KB vs 308 KB with npm)
- ⚡ **80-85% faster installs** (subsequent runs after first install)
- ✅ **100% compatible** with all dependencies
- 🔒 **Production-ready** (verified in Phase 1 evaluation)

**Migration Details:**
- `bun.lock` replaces `package-lock.json` for Bun dependency resolution
- `package.json` remains the same (Bun uses it as source of truth)
- All npm scripts work with `bun run <script>`
- All dev tools (TypeScript, Vite, Wrangler) fully compatible

## Deployment

### Kubernetes Deployment (Source of Truth)

Deployment is orchestrated via **Terraform Cloud** and **Kustomize**:

#### Development (`lornu-dev`)
```bash
kubectl apply -k kubernetes/overlays/dev
```

#### Staging (`lornu-staging`)
```bash
kustomize build kubernetes/overlays/staging | kubectl apply -f -
```

#### Production (`lornu-prod`)
```bash
kustomize build kubernetes/overlays/prod | kubectl apply -f -
```

**Automatic CI/CD**: GitHub Actions workflows in `.github/workflows/` automatically:
1. Build Docker image when code is pushed
2. Push to AWS ECR/GCP Artifact Registry
3. Apply Kustomize manifests to appropriate cluster/namespace
4. Verify deployment health via Kubernetes liveness/readiness probes

### Configuration

#### Environment-Specific Variables

Kustomize patches inject environment variables via ConfigMaps in each overlay:

- **Dev**: 3 replicas, verbose logging
- **Staging**: 3 replicas, TLS enabled via AWS ACM + cert-manager
- **Production**: 3 replicas, TLS enabled, CloudFront CDN cache

See `kubernetes/overlays/{dev,staging,prod}/configmap-patch.yaml` for current values.

#### Secrets Management

Sensitive values (API keys, database credentials) are stored in:
- **AWS Secrets Manager** (production)
- **Kubernetes Secrets** (all clusters, injected via IRSA)
- **GitHub Secrets** (for CI/CD workflows)

Example: To set the contact form API key in staging:
```bash
kubectl create secret generic contact-api-secrets \
  --from-literal=RESEND_API_KEY=sk_test_xxxx \
  -n lornu-staging
```

See `CONTACT_FORM_SETUP.md` for detailed contact form configuration.

## Branding

The Lornu AI branding asset is served consistently across all environments:
- **File**: `src/assets/brand/lornu-ai-final-clear-bg.png`
- **CDN**: Served via CloudFront (prod) or ALB directly (dev/staging)
- **Labeling**: Every K8s resource includes `lornu.ai/asset-id: lornu-ai-final-clear-bg`

## Troubleshooting

### Build Issues

If the Docker build fails:

```bash
# Check Docker is running
docker ps

# Build with verbose output
docker build -t lornu-ai:dev --no-cache .

# Verify Bun lock file is up to date
bun install
bun.lock  # Commit if changed
```

### Kubernetes Deployment Issues

If the deployment fails to start:

```bash
# Check pod status
kubectl get pods -n lornu-dev
kubectl describe pod <pod-name> -n lornu-dev

# View logs
kubectl logs <pod-name> -n lornu-dev

# Check if image exists in registry
aws ecr describe-images --repository-name lornu-ai --region us-east-2
```

### Contact Form / Email Issues

If the contact form isn't sending emails:

1. **Verify secrets exist**:
   ```bash
   kubectl get secret contact-api-secrets -n lornu-dev
   kubectl describe secret contact-api-secrets -n lornu-dev
   ```

2. **Check FastAPI backend logs**:
   ```bash
   kubectl logs -n lornu-dev -l app=lornu-ai --tail=100 | grep -i "resend\|email"
   ```

3. **Verify API endpoint**:
   ```bash
   # From a pod or port-forward
   curl -X POST http://localhost:8000/api/contact \
     -H "Content-Type: application/json" \
     -d '{"name":"Test","email":"test@example.com","message":"Hello"}'
   ```

4. **See `CONTACT_FORM_SETUP.md` for detailed troubleshooting**

## License

The Spark Template files and resources from GitHub are licensed under the terms of the MIT license, Copyright GitHub, Inc.
