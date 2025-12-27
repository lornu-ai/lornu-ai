# Plan A — Unified Workflow Architecture

**Status**: Consolidated (Issue #440)  
**Branch**: `main` only

## The Five Pillars

This repository uses **five consolidated workflows** on the `main` branch, aligned with **Plan A (MVI)** principles:

| Workflow | Purpose | Consolidates |
|----------|---------|--------------|
| **orchestrator.yml** | **The Brain** - Intelligent TFC dispatch for multi-cloud infrastructure | terraform-aws.yml, terraform-gcp.yml, infra-orchestrator.yml, deploy-gke.yml, multi-cloud-deploy.yml |
| **ci-unified.yml** | **The Gate** - Unified lint/test for backend (uv) and frontend (bun) | web-ci.yml, backend CI |
| **synthetic-monitors.yml** | **The Watcher** - Playwright-based health checks targeting lornu-prod namespace | synthetic-monitoring.yml |
| **manage-workspaces.yml** | **The Meta** - TFC workspace variable lifecycle management | tfc-sync.yml, secrets-manager.yml, gcp-secrets-manager.yml |
| **security-scan.yml** | **The Shield** - tfsec & CodeQL security scanning | Security scanning logic |

## Key Principles

### OIDC Authentication
All workflows use **OIDC-based authentication** (no static keys):
- **AWS**: `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
- **GCP**: `google-github-actions/auth@v2` with `workload_identity_provider`

### Standardized Permissions
All workflows include:
```yaml
permissions:
  id-token: write  # Required for OIDC
  contents: read
```

### Terraform Cloud Workspaces
- **AWS**: `aws-kustomize` (organization: `lornu-ai`)
- **GCP**: `gcp-lornu-ai` (organization: `lornu-ai`)

### Tooling Standards
- **Backend**: `uv` for Python dependency management
- **Frontend**: `bun` for TypeScript/React dependency management
- **Infrastructure**: Kustomize for Kubernetes manifests

## Decommissioned Workflows

The following legacy workflows have been **removed** from `main`:
- ❌ `terraform-aws.yml` → `orchestrator.yml`
- ❌ `terraform-gcp.yml` → `orchestrator.yml`
- ❌ `terraform-aws-part1-acm.yml` → `orchestrator.yml`
- ❌ `terraform-aws-part2-cdn.yml` → `orchestrator.yml`
- ❌ `infra-orchestrator.yml` → `orchestrator.yml`
- ❌ `deploy-gke.yml` → `orchestrator.yml`
- ❌ `multi-cloud-deploy.yml` → `orchestrator.yml`
- ❌ `web-ci.yml` → `ci-unified.yml`
- ❌ `synthetic-monitoring.yml` → `synthetic-monitors.yml`
- ❌ `tfc-sync.yml` → `manage-workspaces.yml`
- ❌ `secrets-manager.yml` → `manage-workspaces.yml`
- ❌ `gcp-secrets-manager.yml` → `manage-workspaces.yml`

## Legacy Artifacts Removed

- ❌ ECS Fargate deployment workflows
- ❌ Cloudflare Wrangler/Workers workflows
- ❌ Fragmented test runners

## Usage

### Manual Orchestration
```bash
gh workflow run orchestrator.yml -f cloud=aws -f action=plan
gh workflow run orchestrator.yml -f cloud=gcp -f action=apply
gh workflow run orchestrator.yml -f cloud=both -f action=plan
```

### Workspace Management
```bash
gh workflow run manage-workspaces.yml -f action=sync-config
gh workflow run manage-workspaces.yml -f action=sync-secrets-aws
gh workflow run manage-workspaces.yml -f action=all
```

## References

- Issue #440: [Feature request - Streamline and unify GitHub Actions workflows](https://github.com/lornu-ai/lornu-ai/issues/440)
- Plan A Architecture: `.ai/ARCHITECTURE.md`
- OIDC Migration: `docs/OIDC_MIGRATION_PLAN.md`
