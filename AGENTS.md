# Plan A — AGENTS.md

This repo is AI-native and optimized for **Plan A (MVI)**. Agents should generate code that respects the single-cluster, multi-namespace Kubernetes model.

## Quick Start (Required Reading)

1. `.ai/MISSION.md` for product goals.
2. `.ai/ARCHITECTURE.md` for system design context.
3. `.ai/RULES.md` for coding standards and workflow.

If there is any conflict between docs, follow `.ai/RULES.md`.

## Repo Layout

- `apps/web`: Frontend (React + Vite).
- `packages/api`: Backend (Python 3.11+).
- `terraform/`: Infrastructure (Terraform Cloud).
- `kubernetes/`: Kustomize manifests.
- `docs/`: Project documentation.

## Plan A Kubernetes Model

- **Single EKS cluster**, namespaces:
  - `lornu-dev`
  - `lornu-staging`
  - `lornu-prod`
- **DRY manifests**: `kubernetes/base/` is source of truth; overlays live in `kubernetes/overlays/`.
- **Helm is deprecated**; use `kubectl apply -k` or `kustomize build`.
- **Protective Metadata** on all resources:
  - `lornu.ai/environment`: `development` | `staging` | `production`
  - `lornu.ai/managed-by`: `terraform-cloud`
  - `lornu.ai/asset-id`: `lornu-ai-final-clear-bg`

## Multi-Cloud Support

Plan A supports both AWS and GCP:

- **AWS Overlays**: `kubernetes/overlays/aws-prod/` - EKS with ALB Ingress
- **GCP Overlays**: `kubernetes/overlays/gcp-prod/`, `kubernetes/overlays/gcp-staging/` - GKE with Global Load Balancer
- **Base manifests**: Cloud-agnostic in `kubernetes/base/`

## Tooling

- JS/TS package manager: **Bun** only (`bun install`, `bun run`, `bunx`).
- Python package manager: **uv** only (`uv sync`, `uv run`, `uv pip install`).

## Git Workflow

- `main`: Production (single source of truth)
- `develop`: (deprecated) Staging integration branch
- Feature branches: `feat/` or `feature/`
- Always use PRs; never push directly to `main` or `develop`.
- Always open PRs against `develop`.

## Dependabot
- Dependabot PRs target `main` as the only exception to the `develop` base rule.
- Dependabot PRs must keep the `dependencies` label.
- Review automated updates for lockfile changes and CI impact; avoid manual version bumps unless necessary.

## PR Labeling (Required)

- Apply a label for the **worker/agent** (e.g., `codex`, `vs-code-with-github-copilot`, `antigravity`, `claude`) to every PR. If the label doesn't exist, create it first.
- Example commands: `gh label create <agent-name>` (if needed), `gh pr edit <pr-number> --add-label <agent-name>`.

## PR Base Branch (Required)

- Always open PRs against `main`.

## Testing & Linting

- Frontend tests: `bun run test`, `bun run test:e2e`
- Backend tests: `uv run pytest`
- Backend lint: `uv run ruff check .`

## GitHub Actions Workflows (Plan A Unified Architecture)

The `main` branch uses **five consolidated workflows** (Issue #440):

1. **orchestrator.yml** - The Brain: Intelligent TFC dispatch for AWS/GCP infrastructure
2. **ci-unified.yml** - The Gate: Unified lint/test (uv for backend, bun for frontend)
3. **synthetic-monitors.yml** - The Watcher: Playwright health checks
4. **manage-workspaces.yml** - The Meta: TFC workspace variable lifecycle
5. **security-scan.yml** - The Shield: tfsec & CodeQL scanning

**Key Standards:**
- All workflows use **OIDC authentication** (no static keys
- TFC workspaces: `aws-kustomize` (AWS), `gcp-lornu-ai` (GCP)
- Standardized permissions: `id-token: write`, `contents: read`

See `.github/workflows/README.md` for details.

## Terraform Hygiene (Required)

**Pre-push requirements** - Run these locally before pushing any Terraform changes:

```bash
# Format all Terraform files
terraform fmt -recursive terraform/

# Validate each directory
cd terraform/aws && terraform init -backend=false && terraform validate
cd terraform/gcp && terraform init -backend=false && terraform validate
cd terraform/tfc-management && terraform init -backend=false && terraform validate
```

**CI Enforcement**: The `validate.yml` workflow automatically checks:
- `terraform fmt -check -recursive` on all directories
- `terraform validate` with backend-less init
- `actionlint` for GitHub Actions workflow syntax

PRs with formatting or validation errors will be **blocked** until fixed.

## Kubernetes Deployment

### Local Development

```bash
# Deploy to local minikube cluster
kubectl apply -k kubernetes/overlays/lornu-dev
```

### Staging

```bash
# Build and apply staging overlay
kustomize build kubernetes/overlays/gcp-staging | kubectl apply -f -
```

### Production

```bash
# AWS Production
kustomize build kubernetes/overlays/aws-prod | kubectl apply -f -

# GCP Production
kustomize build kubernetes/overlays/gcp-prod | kubectl apply -f -
```

## Contributing Infrastructure

### Zero-Secret OIDC Architecture

Lornu AI uses **OIDC-based Dynamic Provider Credentials** for all cloud authentication:

- **AWS**: TFC assumes `terraform-cloud-oidc-role` via OIDC
- **GCP**: TFC uses Workload Identity Federation with `lornu-tfc-pool`

### Meta-Terraform Management

The `terraform/tfc-management/` workspace automates:
- TFC variable injection for OIDC configuration
- GitHub Actions secret rotation (`TF_API_TOKEN`)

### Infrastructure Security Rules

1. **NEVER create static IAM credentials** (AWS Access Keys or GCP JSON keys)
2. **ALWAYS use OIDC/Workload Identity** for cloud authentication
3. **Scope trust policies** to specific TFC organizations and workspaces
4. **Reference existing OIDC roles** instead of creating new static credentials

See `docs/OIDC_MIGRATION_RUNBOOK.md` for credential management procedures.

## Prohibited References

- Do not introduce AWS ECS or Cloudflare Workers references.
- Do not add non-DRY manifest duplication across overlays.
- Do not introduce Helm charts, templates, or values files.

## Infrastructure Drift Detection & Remediation

Lornu AI uses **Drift-Sentinel** to automatically detect infrastructure drift across Terraform Cloud workspaces. Drift occurs when the actual cloud infrastructure state diverges from the Terraform code (e.g., manual console changes, failed deployments).

### How to Remediate Infrastructure Drift

When drift is detected (via scheduled hourly checks or manual workflow dispatch):

1. **Review the Drift Report**
   - Check the GitHub Actions workflow run summary for the affected workspace
   - Download the drift plan artifact to see detailed changes
   - Identify whether drift is expected (intentional manual change) or unexpected (security risk)

2. **Determine Remediation Strategy**
   - **Expected Drift**: Update Terraform code to match the manual change, then commit and push
   - **Unexpected Drift**: Remediate immediately to restore state consistency

3. **Trigger Remediation**
   - **Via GitHub Actions UI**: Go to Actions → "Drift-Sentinel" → "Run workflow" → Select workspace → Enable "remediation: true"
   - **Via CLI**: `gh workflow run drift-sentinel.yml -f workspace=lornu-ai-kustomize -f remediation=true`
   - **Manual**: Run `terraform apply` in the affected `terraform/aws/{environment}` directory

4. **Verify Remediation**
   - Check the workflow run output to confirm successful apply
   - Verify the drift detection run shows no drift after remediation
   - Monitor Better Stack alerts (when integrated) for infrastructure health

### Workspaces Monitored

- **Production**: `lornu-ai-kustomize` (organization: `lornu-ai`)
- **Staging**: `lornu-ai-staging-aws` (organization: `lornu-ai`)

### Drift Detection Schedule

- **Automatic**: Runs every hour via cron schedule
- **Manual**: Can be triggered via `workflow_dispatch` for on-demand checks

### Security Considerations

- **Production Remediation**: Requires manual approval (workflow_dispatch with `remediation: true`)
- **Drift Alerts**: Should be integrated with Better Stack for on-call rotation
- **Audit Trail**: All drift detections and remediations are logged in GitHub Actions
