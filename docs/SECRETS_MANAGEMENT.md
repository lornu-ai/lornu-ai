# Secrets Management Workflow

This document explains how secrets are managed in Lornu AI infrastructure using GitHub Secrets and AWS Secrets Manager.

## Architecture

```
GitHub Secrets
     ↓
GitHub Actions Workflow (secrets-manager.yml)
     ↓
Terraform (secrets-manager.tf)
     ↓
AWS Secrets Manager
     ↓
Kubernetes External Secrets Operator (ESO)
     ↓
Kubernetes Secrets (auto-synced)
     ↓
Application Pods
```

## Workflow: Secrets Manager Sync

**File:** `.github/workflows/secrets-manager.yml`

**Triggers:**
- Manual: `workflow_dispatch` (run anytime from GitHub UI)
- Scheduled: Daily at 2 AM UTC
- Push: When secrets-manager Terraform files change on kustomize branch

**Process:**
1. Checkout kustomize branch
2. Configure AWS credentials via OIDC (IAM role assumption)
3. Terraform init (download providers)
4. Terraform plan (read GitHub Secrets, generate plan)
5. Terraform apply (create/update secrets in AWS Secrets Manager)
6. Output secret ARNs and names

## Adding New Secrets

### Step 1: Add GitHub Secret

Add to GitHub repository settings → Secrets and variables → Actions secrets:

```
Repository Secret Name: MY_NEW_SECRET
Value: <actual-secret-value>
```

### Step 2: Add Terraform Variable

Update `terraform/aws/production/secrets-variables.tf`:

```hcl
variable "my_new_secret" {
  description = "Description of the secret"
  type        = string
  sensitive   = true
  default     = ""
}
```

### Step 3: Add Terraform Resource

Update `terraform/aws/production/secrets-manager.tf`:

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

### Step 4: Push to kustomize

Workflow automatically triggers and syncs the secret to AWS Secrets Manager.

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

Trigger manually from GitHub Actions UI:
1. Go to Actions
2. Select "Secrets Manager Sync"
3. Click "Run workflow"
4. Select kustomize branch
5. Monitor output for ARNs

## Troubleshooting

**Workflow fails with permission error:**
- Check AWS_ACTIONS_PROD_ROLE_ARN is set in GitHub
- Verify IAM role has secretsmanager:* permissions

**Secret not updated in Kubernetes:**
- Check External Secrets Operator logs: `kubectl logs -n external-secrets`
- Verify ESO SecretStore is configured correctly

**GitHub Secret not found:**
- Confirm secret exists in Repository Settings
- Use `TF_VAR_` prefix pattern: `TF_VAR_resend_api_key`

## Related Files

- Workflow: `.github/workflows/secrets-manager.yml`
- Terraform: `terraform/aws/production/secrets-manager.tf`
- Variables: `terraform/aws/production/secrets-variables.tf`
- ESO Config: `terraform/aws/production/external_secrets.tf`
- Kustomize Deploy: `.github/workflows/kustomize-deploy.yml` (deployment after secrets are synced)
