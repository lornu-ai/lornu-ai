# Plan A — Lornu AI

[![Bun](https://img.shields.io/badge/Bun-1.3+-black?logo=bun&logoColor=white)](https://bun.sh)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Terraform](https://img.shields.io/badge/Terraform-Cloud-623CE4?logo=terraform&logoColor=white)](https://terraform.io)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-EKS%20%2F%20GKE-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io)
[![Kustomize](https://img.shields.io/badge/Kustomize-v5+-1ABC9C?logo=kubernetes&logoColor=white)](https://kustomize.io)

## Mission

**Deliver a 50–70% reduction in engineering time and operational overhead** through a hardened, metadata-driven **Minimum Viable Infrastructure (MVI)**. Plan A consolidates delivery onto **one EKS cluster** with **Kustomize-based multi-namespace isolation**.

## Plan A Snapshot

- **Single EKS cluster** with three namespaces:
  - `lornu-dev`
  - `lornu-staging`
  - `lornu-prod`
- **Kustomize overlays** per environment (Helm is deprecated).
- **Terraform Cloud** as infrastructure control plane.
- **Modern runtimes**: Bun (frontend), uv (backend).

## Directory Structure (DRY)

```
apps/web/              # React frontend (Bun)
packages/api/          # Python backend (uv)
terraform/             # Infrastructure (Terraform Cloud)
kubernetes/base/       # Source of truth manifests
kubernetes/overlays/   # dev, staging, prod overlays
```

## Protective Metadata Standard

Every Kubernetes resource must include:
- `lornu.ai/environment`: `development` | `staging` | `production`
- `lornu.ai/managed-by`: `terraform-cloud`
- `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Quick Start

1. Read `AGENTS.md` for contributor guidelines.
2. Read `.ai/RULES.md` for coding standards and workflow.
3. Read `.ai/ARCHITECTURE.md` for system design context.

## Runtime Standards

- **Frontend**: Bun (`bun install`, `bun run`, `bunx`)
- **Backend**: uv (`uv sync`, `uv run`, `uv pip install`)

## Branding

- Brand asset: `apps/web/src/assets/brand/lornu-ai-final-clear-bg.png`

## Kubernetes Apply (Examples)

```bash
kubectl apply -k kubernetes/overlays/lornu-dev
kustomize build kubernetes/overlays/lornu-staging | kubectl apply -f -
kustomize build kubernetes/overlays/aws-prod | kubectl apply -f -
```

## Multi-Cloud Architecture

Plan A supports both AWS and GCP deployments:

- **AWS**: EKS cluster with ALB Ingress Controller
- **GCP**: GKE cluster with Global Load Balancer
- **Overlays**: `aws-prod/`, `gcp-prod/`, `gcp-staging/` for cloud-specific configurations

See `kubernetes/README.md` for detailed Kustomize usage.

## Local Development

Fast local testing with minikube:

```bash
# Setup local Kubernetes cluster
./scripts/local-k8s-setup.sh

# Deploy to local cluster
./scripts/local-k8s-deploy.sh

# Test deployment
./scripts/local-k8s-test.sh

# Access the app
kubectl port-forward svc/lornu-ai 8080:8080
```

See `docs/LOCAL_TESTING.md` for detailed local development guide.

## Deployment

Deployment follows a staged approach:

1. **Stage 1 (ACM)**: Provision/validate CloudFront certificates
2. **Stage 2 (CDN)**: Create/update CloudFront distribution and DNS records
3. **Application (Kustomize)**: Deploy namespace-scoped Kubernetes resources

Workflows:
- `.github/workflows/terraform-aws-stage1-acm.yml` - Certificate provisioning
- `.github/workflows/terraform-aws-stage2-cdn.yml` - CDN and DNS
- `.github/workflows/kustomize-deploy.yml` - Application deployment

## Testing & Linting

- **Frontend tests**: `bun run test`, `bun run test:e2e`
- **Backend tests**: `uv run pytest`
- **Backend lint**: `uv run ruff check .`

## Git Workflow

- `main`: Production
- `develop`: Staging/Integration
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main` or `develop`.
- Always open PRs against `develop`.

## PR Requirements

- **Labeling**: Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR.
- **Base Branch**: Open PRs against `develop` (or `kustomize-develop` for kustomize docs updates).

## Terraform Hygiene

Before pushing, run `terraform fmt` and `terraform validate` for any Terraform changes.

## Terraform Cloud (TFC) Manual Runs

Lornu AI uses CLI-driven TFC workflows. Before running manual infrastructure updates via the TFC UI:

1. Ensure the `tfc-sync.yml` workflow has completed (runs automatically on push to `main` or `kustomize`)
2. Verify the Configuration Version in TFC matches your latest commit
3. Then create a new run in the TFC UI

See `docs/TFC_MANUAL_RUNS.md` for detailed instructions.

## Notes

Plan A documentation is authoritative for this repo. Legacy references to ECS or Cloudflare Workers are deprecated.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.
