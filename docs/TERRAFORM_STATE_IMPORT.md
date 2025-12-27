# Importing Terraform State to Terraform Cloud

This guide explains how to import existing Terraform state into Terraform Cloud workspace `aws-kustomize` in organization `lornu-ai`.

## Prerequisites

1. **Terraform Cloud Account**: Access to `lornu-ai` organization
2. **Workspace Created**: `aws-kustomize` workspace exists in Terraform Cloud
3. **Terraform CLI**: Version 1.0+ installed locally
4. **Terraform Cloud Token**: API token for authentication
5. **Existing State**: Local state file or remote state to import

## Step 1: Authenticate with Terraform Cloud

```bash
# Set your Terraform Cloud API token
export TF_TOKEN_app_terraform_io="your-terraform-cloud-token"

# Or configure via credentials file
terraform login
```

## Step 2: Verify Workspace Configuration

Check that your `backend.tf` or `terraform {}` block is configured correctly:

```hcl
terraform {
  cloud {
    organization = "lornu-ai"

    workspaces {
      name = "aws-kustomize"
    }
  }
}
```

## Step 3: Check Current State Location

Determine where your current state is stored:

### Option A: Local State File
```bash
cd terraform/aws/production
ls -la terraform.tfstate terraform.tfstate.backup
```

### Option B: Remote State (S3, etc.)
```bash
# Check backend configuration
cat backend.tf
# Or check terraform.tfstate for backend info
```

### Option C: No State File (New Workspace)
If you're starting fresh, you can skip import and just run `terraform init`.

## Step 4: Import State to Terraform Cloud

### Method 1: Using `terraform init` (Recommended)

If you have a local state file:

```bash
cd terraform/aws/production

# 1. Backup your current state
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)

# 2. Update backend configuration to use Terraform Cloud
# (Ensure backend.tf or terraform {} block points to TFC)

# 3. Initialize and migrate state
terraform init -migrate-state

# Terraform will prompt:
# Do you want to copy existing state to the new backend?
# Enter: yes
```

### Method 2: Using Terraform Cloud API

If you need to import state manually:

```bash
# 1. Export state to JSON
cd terraform/aws/production
terraform show -json > state-export.json

# 2. Use Terraform Cloud API to upload state
curl \
  --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
  --header "Content-Type: application/json" \
  --request POST \
  --data @state-export.json \
  https://app.terraform.io/api/v2/workspaces/lornu-ai/aws-kustomize/state-versions
```

### Method 3: Using `terraform state push` (Deprecated)

```bash
# Note: This method is deprecated but may still work
terraform state push terraform.tfstate
```

## Step 5: Verify Import

```bash
# 1. Initialize Terraform
terraform init

# 2. Verify state is in Terraform Cloud
terraform state list

# 3. Check workspace in Terraform Cloud UI
# Go to: https://app.terraform.io/app/lornu-ai/workspaces/aws-kustomize
```

## Step 6: Test State Access

```bash
# Run a plan to verify state is accessible
terraform plan

# Should show: "No changes. Your infrastructure matches the configuration."
# Or show actual differences if state differs from code
```

## Troubleshooting

### Error: Workspace Not Found

**Issue**: `Error: workspace "aws-kustomize" not found`

**Solution**:
1. Verify workspace name in Terraform Cloud UI
2. Check organization name is correct: `lornu-ai`
3. Ensure you have access to the workspace

### Error: State Locked

**Issue**: `Error: Error acquiring the state lock`

**Solution**:
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# Or unlock via Terraform Cloud UI
# Go to: Workspace → States → Current State → Unlock
```

### Error: State Version Conflict

**Issue**: State version mismatch

**Solution**:
1. Check current state version in Terraform Cloud
2. Use `terraform state pull` to download current state
3. Compare with local state
4. Resolve conflicts manually if needed

### Error: Authentication Failed

**Issue**: `Error: Invalid token`

**Solution**:
```bash
# Re-authenticate
terraform login

# Or set token explicitly
export TF_TOKEN_app_terraform_io="your-token"
```

## Migration Checklist

- [ ] Terraform Cloud workspace `aws-kustomize` exists
- [ ] Backend configuration updated to point to TFC
- [ ] Local state file backed up
- [ ] Terraform Cloud API token configured
- [ ] State imported successfully
- [ ] `terraform plan` runs without errors
- [ ] State visible in Terraform Cloud UI
- [ ] Team members have workspace access

## Post-Migration Steps

1. **Update CI/CD**: Ensure GitHub Actions uses Terraform Cloud backend
2. **Remove Local State**: After verification, remove local state files:
   ```bash
   rm terraform.tfstate terraform.tfstate.backup
   ```
3. **Update Documentation**: Document the new state location
4. **Team Notification**: Inform team about state migration

## Workspace Configuration

Ensure the workspace has:

- **Execution Mode**: Remote (default) or Local
- **Terraform Version**: 1.8.0+ (as per project requirements)
- **Variables**: All required variables set in workspace
- **Team Access**: Appropriate permissions for team members

## References

- [Terraform Cloud State Migration](https://developer.hashicorp.com/terraform/cloud-docs/migrate)
- [Terraform Cloud API](https://www.terraform.io/cloud-docs/api-docs)
- [Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/remote)

---

**Note**: Always backup your state before migration. State loss can be catastrophic.
