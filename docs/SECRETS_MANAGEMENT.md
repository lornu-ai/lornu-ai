# Secrets Management Workflow

This document explains how secrets are managed in Lornu AI infrastructure using GitHub Secrets, AWS Secrets Manager, and GCP Secret Manager.

## Architecture

### AWS Secrets Flow
```
GitHub Secrets
     ↓
GitHub Actions Workflow (manage-workspaces.yml)
     ↓
Terraform (terraform/aws/secrets-manager.tf)
     ↓
AWS Secrets Manager
     ↓
Kubernetes External Secrets Operator (ESO)
     ↓
Kubernetes Secrets (auto-synced)
     ↓
Application Pods
```

### GCP Secrets Flow
```
GitHub Secrets
     ↓
GitHub Actions Workflow (manage-workspaces.yml)
     ↓
Terraform (terraform/gcp/secrets.tf)
     ↓
GCP Secret Manager
     ↓
Kubernetes Secrets (via Workload Identity)
     ↓
Application Pods
```

## Workflow: Unified Secrets Management

**File:** `.github/workflows/manage-workspaces.yml` (consolidated workflow)

**Triggers:**
- Manual: `workflow_dispatch` with action `sync-secrets-aws` or `sync-secrets-gcp` or `all`
- Scheduled: Daily at 2 AM UTC (automatic sync)
- Push: When secrets Terraform files change on `main` branch

**Process (AWS):**
1. Checkout `main` branch
2. Configure AWS credentials via OIDC (`AWS_ACTIONS_ROLE_ARN`)
3. Terraform init (download providers)
4. Terraform plan (read GitHub Secrets via `TF_VAR_*` env vars, generate plan)
5. Terraform apply (create/update secrets in AWS Secrets Manager)
6. External Secrets Operator automatically syncs to Kubernetes

**Process (GCP):**
1. Checkout `main` branch
2. Authenticate to GCP via OIDC (Workload Identity Federation)
3. Terraform init (download providers)
4. Terraform plan (read GitHub Secrets via `TF_VAR_*` env vars, generate plan)
5. Terraform apply (create/update secrets in GCP Secret Manager)
6. Add secret version via `gcloud` CLI
7. Kubernetes pods access via Workload Identity

## Adding New Secrets

### Step 1: Add GitHub Secret

Add to GitHub repository settings → Secrets and variables → Actions secrets:

```
Repository Secret Name: MY_NEW_SECRET
Value: <actual-secret-value>
```

### Step 2: Add Terraform Variable

**For AWS:** Update `terraform/aws/secrets-variables.tf`:

```hcl
variable "my_new_secret" {
  description = "Description of the secret"
  type        = string
  sensitive   = true
  default     = ""
}
```

### Step 3: Add Terraform Resource

**For AWS:** Update `terraform/aws/secrets-manager.tf`:

```hcl
resource "aws_secretsmanager_secret" "my_new_secret" {
  name                    = "lornu-ai/my-new-secret"
  description             = "Description"
  recovery_window_in_days = 7

  tags = {
    Name        = "lornu-ai-my-new-secret"
    Environment = "production"
    ManagedBy   = "Terraform"
    Source      = "GitHub-Secrets"
  }
}

resource "aws_secretsmanager_secret_version" "my_new_secret" {
  secret_id = aws_secretsmanager_secret.my_new_secret.id
  secret_string = jsonencode({
    MY_NEW_SECRET = var.my_new_secret
  })
}
```

**For GCP:** Update `terraform/gcp/secrets.tf`:

```hcl
resource "google_secret_manager_secret" "my_new_secret" {
  secret_id = "my-new-secret"
  replication {
    auto {}
  }

  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}

resource "google_secret_manager_secret_iam_member" "my_new_secret_access" {
  secret_id = google_secret_manager_secret.my_new_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:lornu-backend@${var.project_id}.iam.gserviceaccount.com"
}
```

### Step 4: Update Workflow Environment Variables

Add the secret to the workflow's `env` section in `manage-workspaces.yml`:

**For AWS:**
```yaml
- name: Terraform Plan (Secrets)
  env:
    TF_VAR_resend_api_key: ${{ secrets.RESEND_API_KEY }}
    TF_VAR_my_new_secret: ${{ secrets.MY_NEW_SECRET }}  # Add this
```

**For GCP:**
```yaml
- name: Terraform Plan (Secrets)
  env:
    TF_VAR_resend_api_key: ${{ secrets.RESEND_API_KEY }}
    TF_VAR_my_new_secret: ${{ secrets.MY_NEW_SECRET }}  # Add this
```

### Step 5: Push to main

Workflow automatically triggers and syncs the secret to AWS Secrets Manager or GCP Secret Manager.

## Accessing Secrets in Kubernetes

Secrets are synced to Kubernetes via External Secrets Operator (ESO).

ESO configuration in `terraform/aws/production/external_secrets.tf` automatically:
1. Watches AWS Secrets Manager
2. Creates Kubernetes Secrets
3. Updates when secrets change in AWS

Application pods access via environment variables:
```yaml
env:
- name: RESEND_API_KEY
  valueFrom:
    secretKeyRef:
      name: lornu-ai-secrets
      key: RESEND_API_KEY
```

## Security Principles

✅ **GitHub Secrets** - Source of truth for actual secret values
✅ **Terraform** - Version-controlled infrastructure-as-code
✅ **AWS Secrets Manager** - Encrypted storage with audit logging
✅ **External Secrets Operator** - Automatic sync to Kubernetes
✅ **Never commit secrets** - Only infrastructure code is in git

## Workflow Permissions

Required GitHub Actions settings:
- `contents: read` - Read repository code
- `id-token: write` - Generate OIDC tokens for AWS

## Terraform Requirements

- AWS role with Secrets Manager permissions
- OIDC provider configured in AWS
- Terraform backend (TFC workspace)

## Manual Secret Sync

### Via GitHub Actions UI

1. Go to **Actions** tab
2. Select **"Manage Workspaces - The Meta"** workflow
3. Click **"Run workflow"**
4. Select action:
   - `sync-secrets-aws` - Sync AWS Secrets Manager only
   - `sync-secrets-gcp` - Sync GCP Secret Manager only
   - `all` - Sync both AWS and GCP
5. Monitor output for secret ARNs/names

### Via GitHub CLI

```bash
# Sync AWS secrets only
gh workflow run manage-workspaces.yml -f action=sync-secrets-aws

# Sync GCP secrets only
gh workflow run manage-workspaces.yml -f action=sync-secrets-gcp

# Sync all (config + secrets for both clouds)
gh workflow run manage-workspaces.yml -f action=all

# Watch the workflow run
gh run watch
```

## Troubleshooting

### AWS Secrets

**Workflow fails with permission error:**
- Check `AWS_ACTIONS_ROLE_ARN` is set in GitHub Secrets
- Verify IAM role has `secretsmanager:*` permissions
- Ensure OIDC is configured correctly (see `terraform/aws/github-oidc.tf`)

**Secret not updated in Kubernetes:**
- Check External Secrets Operator logs: `kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets`
- Verify ESO SecretStore is configured correctly in `terraform/aws/external_secrets.tf`
- Check ESO sync status: `kubectl get externalsecret -n <namespace>`

**GitHub Secret not found:**
- Confirm secret exists in Repository Settings → Secrets and variables → Actions
- Use `TF_VAR_` prefix pattern: `TF_VAR_resend_api_key`
- Verify the secret name matches the Terraform variable name

### GCP Secrets

**Workflow fails with authentication error:**
- Check `GCP_WIF_PROVIDER` and `GCP_SA_EMAIL` are set in GitHub Secrets
- Verify Workload Identity Federation is configured (see `terraform/gcp/github-wif.tf`)
- Ensure service account has `roles/secretmanager.admin` permission

**Secret not accessible in Kubernetes:**
- Verify Workload Identity binding is configured for the service account
- Check service account has `roles/secretmanager.secretAccessor` on the secret
- Verify pod service account annotation matches WIF configuration

**gcloud command fails:**
- Check `GCP_PROJECT_ID` secret is set
- Verify service account has `roles/secretmanager.admin` permission
- Ensure secret exists before adding versions

## Related Files

- **Workflow**: `.github/workflows/manage-workspaces.yml` (unified workflow)
- **AWS Terraform**: `terraform/aws/secrets-manager.tf`
- **AWS Variables**: `terraform/aws/secrets-variables.tf`
- **AWS ESO Config**: `terraform/aws/external_secrets.tf`
- **GCP Terraform**: `terraform/gcp/secrets.tf`
- **GCP WIF Config**: `terraform/gcp/github-wif.tf`

## Security Best Practices

✅ **OIDC Authentication** - All workflows use OIDC (no static keys)  
✅ **GitHub Secrets** - Source of truth for actual secret values  
✅ **Terraform** - Version-controlled infrastructure-as-code  
✅ **Cloud Secret Managers** - Encrypted storage with audit logging  
✅ **Never commit secrets** - Only infrastructure code is in git  
✅ **Least Privilege** - Service accounts have minimal required permissions
