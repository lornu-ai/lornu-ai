# Secrets Management Quick Start Guide

**After PR #443 merge** - Unified workflow for AWS and GCP secrets

## Quick Reference

### Manual Secret Sync

```bash
# Sync AWS secrets
gh workflow run manage-workspaces.yml -f action=sync-secrets-aws

# Sync GCP secrets
gh workflow run manage-workspaces.yml -f action=sync-secrets-gcp

# Sync everything (config + secrets for both)
gh workflow run manage-workspaces.yml -f action=all
```

### Adding a New Secret

1. **Add to GitHub Secrets** (Repository Settings → Secrets and variables → Actions)
   ```
   MY_NEW_SECRET = <value>
   ```

2. **Add Terraform Variable** (AWS: `terraform/aws/secrets-variables.tf`, GCP: `terraform/gcp/variables.tf`)

3. **Add Terraform Resource** (AWS: `terraform/aws/secrets-manager.tf`, GCP: `terraform/gcp/secrets.tf`)

4. **Update Workflow** (`.github/workflows/manage-workspaces.yml`)
   - Add `TF_VAR_my_new_secret: ${{ secrets.MY_NEW_SECRET }}` to the `env` section

5. **Push to main** - Workflow auto-triggers, or run manually

## Workflow Details

**File**: `.github/workflows/manage-workspaces.yml`

**Jobs**:
- `sync-config` - Syncs Terraform configuration to TFC workspaces
- `sync-secrets-aws` - Syncs secrets from GitHub → AWS Secrets Manager
- `sync-secrets-gcp` - Syncs secrets from GitHub → GCP Secret Manager

**Authentication**:
- **AWS**: OIDC via `AWS_ACTIONS_ROLE_ARN` (no static keys)
- **GCP**: OIDC via `GCP_WIF_PROVIDER` + `GCP_SA_EMAIL` (no static keys)

**Schedule**: Daily at 2 AM UTC (automatic sync)

## Current Secrets

### AWS Secrets Manager
- `lornu-ai/resend-api-key` - Resend API key for contact form

### GCP Secret Manager
- `resend-api-key` - Resend API key for contact form

## Access in Kubernetes

### AWS (via External Secrets Operator)
```yaml
env:
- name: RESEND_API_KEY
  valueFrom:
    secretKeyRef:
      name: lornu-ai-secrets  # Auto-created by ESO
      key: RESEND_API_KEY
```

### GCP (via Workload Identity)
```yaml
env:
- name: RESEND_API_KEY
  valueFrom:
    secretKeyRef:
      name: lornu-ai-secrets
      key: RESEND_API_KEY
```

## See Also

- Full documentation: `docs/SECRETS_MANAGEMENT.md`
- Workflow details: `.github/workflows/manage-workspaces.yml`
- OIDC setup: `docs/OIDC_MIGRATION_PLAN.md`

