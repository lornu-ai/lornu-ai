# Quick Guide: Import State to Terraform Cloud

**Target**: `lornu-ai` organization, `aws-kustomize` workspace

## Quick Steps

### 1. Authenticate with Terraform Cloud

```bash
# Option A: Login interactively
terraform login

# Option B: Set token directly
export TF_TOKEN_app_terraform_io="your-terraform-cloud-token"
```

### 2. Navigate to Terraform Directory

```bash
cd terraform/aws
```

### 3. Backup Current State (if exists)

```bash
# If you have local state
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
```

### 4. Initialize and Migrate State

```bash
terraform init -migrate-state
```

When prompted: **Enter "yes"** to copy existing state to Terraform Cloud.

### 5. Verify Import

```bash
# List resources in state
terraform state list

# Run a plan to verify
terraform plan
```

## Using the Helper Script

```bash
# From repo root
cd terraform/aws
export TF_TOKEN_app_terraform_io="your-token"
../../scripts/import-tf-state-to-tfc.sh
```

## Verify in Terraform Cloud UI

1. Go to: https://app.terraform.io/app/lornu-ai/workspaces/aws-kustomize
2. Click on **"States"** tab
3. Verify your state is listed

## Troubleshooting

### No Local State File

If you don't have a local state file, you can:
1. Create the workspace in Terraform Cloud first
2. Run `terraform init` (without `-migrate-state`)
3. Import resources manually using `terraform import`

### Workspace Doesn't Exist

Create it first:
1. Go to: https://app.terraform.io/app/lornu-ai/workspaces
2. Click **"New workspace"**
3. Name it: `aws-kustomize`
4. Choose **"CLI-driven workflow"**
5. Then run the import steps above

### State Already Exists in TFC

If state already exists in Terraform Cloud:
1. Download current state: `terraform state pull > current-state.json`
2. Compare with local state
3. Merge if needed, or force push (use with caution)

---

**See Also**: [Full Import Guide](./TERRAFORM_STATE_IMPORT.md)
