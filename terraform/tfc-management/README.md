# TFC Management Workspace

Meta-Terraform workspace for managing Terraform Cloud configuration, OIDC variable injection, and GitHub Actions secret rotation.

## Purpose

This workspace automates:
- TFC variable injection for OIDC/Dynamic Provider Credentials
- GitHub Actions secret management (`TF_API_TOKEN`)
- Least-privileged team creation for CI/CD

## Prerequisites

Before applying this workspace:

1. **Phase 1 Complete**: AWS TFC OIDC Provider applied (`terraform/aws/tfc-oidc.tf`)
   - Output needed: `tfc_oidc_role_arn`

2. **Phase 2 Complete**: GCP TFC Workload Identity Federation applied (`terraform/gcp/tfc-oidc.tf`)
   - Outputs needed: `tfc_workload_identity_provider_name`, `tfc_service_account_email`

3. **TFC Workspace Created**: Create `tfc-management` workspace in Terraform Cloud UI

## Required Environment Variables

| Variable | Description |
|----------|-------------|
| `TFE_TOKEN` | Terraform Cloud API token with org admin access |
| `GITHUB_TOKEN` | GitHub PAT with `repo` and `admin:org` scopes |

## Required Input Variables

Set these in the TFC workspace:

| Variable | Description | Sensitive |
|----------|-------------|-----------|
| `aws_oidc_role_arn` | ARN from Phase 1 output | Yes |
| `gcp_workload_provider_name` | Provider name from Phase 2 output | Yes |
| `gcp_service_account_email` | SA email from Phase 2 output | Yes |

## What This Creates

### TFC Resources
- `github-actions-ci` team with minimal permissions
- Team access to `aws-kustomize` and `gcp-lornu-ai` workspaces
- OIDC variables injected into target workspaces

### GitHub Resources
- `TF_API_TOKEN` secret (rotated team token)
- `TFC_ORGANIZATION` variable

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply
```

## Security Notes

- Uses least-privileged team instead of `owners` team
- Team token scoped only to required workspaces
- OIDC variables marked as sensitive

## Related Documentation

- [OIDC Migration Runbook](../../docs/OIDC_MIGRATION_RUNBOOK.md)
- [TFC Manual Runs](../../docs/TFC_MANUAL_RUNS.md)
