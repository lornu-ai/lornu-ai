# Terraform Cloud Manual Runs Guide

## Overview

Lornu AI uses a **CLI-driven workflow** for Terraform Cloud (TFC). This means the TFC UI shows "Not Connected" under Version Control settings, which is intentional. The "Target Branch" logic is managed within GitHub Actions workflows, not in the TFC UI.

## How Manual TFC UI Runs Work

### Configuration Version Sync

Before running a manual infrastructure update via the TFC UI, the configuration version must be "primed" by GitHub Actions:

1. **Automatic Sync**: When code is pushed to the `main` branch, the `.github/workflows/tfc-sync.yml` workflow automatically:
   - Uploads the latest Terraform configuration to TFC
   - Creates a speculative plan to verify the configuration
   - Updates the Configuration Version in the TFC workspace

2. **Manual Run**: After the sync completes, you can safely click "+ New Run" in the TFC dashboard. The run will use the code from the most recent GitHub push.

### Workspaces

Lornu AI uses two TFC workspaces in the `lornu-ai` organization:

- **AWS Production**: `aws-kustomize` (terraform/aws)
- **GCP**: `gcp-lornu-ai` (terraform/gcp)

### Verifying Configuration Version

Before running a manual TFC UI run:

1. Check the TFC workspace "Configuration Versions" tab
2. Verify the latest configuration version matches the most recent GitHub commit SHA
3. The "Last Updated" timestamp should match your last push to `main`

### Running Manual Updates

1. **Ensure Sync Completed**: Check GitHub Actions for the `tfc-sync.yml` workflow run
2. **Navigate to TFC**: Go to the appropriate workspace (`aws-kustomize` for AWS, `gcp-lornu-ai` for GCP)
3. **Create Run**: Click "+ New Run" in the TFC UI
4. **Select Configuration Version**: The latest version (from the sync) will be pre-selected
5. **Review Plan**: Review the plan output before applying
6. **Apply**: If the plan looks correct, apply the changes

### Branch Mapping

- **`main` branch**: Production infrastructure (AWS and GCP)

### Skipping Sync

To skip the automatic TFC sync (e.g., for documentation-only commits), include `[skip tfc]` in your commit message:

```bash
git commit -m "docs: update README [skip tfc]"
```

## Troubleshooting

### Configuration Version Not Updated

If the configuration version in TFC doesn't match your latest commit:

1. Check if the `tfc-sync.yml` workflow ran successfully
2. Verify the workflow has access to the required secrets:
   - `AWS_TF_API_TOKEN` (for AWS workspace)
   - `GCP_TF_API_TOKEN` (for GCP workspace)
3. Manually trigger the sync workflow:
   ```bash
   gh workflow run tfc-sync.yml
   ```

### Manual Run Using Old Code

If a manual TFC UI run appears to be using old code:

1. Check the Configuration Version ID in the run details
2. Compare it with the latest Configuration Version in the workspace
3. If they don't match, wait for the sync workflow to complete or trigger it manually

## Related Documentation

- `.github/workflows/tfc-sync.yml` - Automatic configuration version sync workflow
- `terraform/aws/backend.tf` - AWS TFC backend configuration
- `terraform/gcp/main.tf` - GCP TFC backend configuration

