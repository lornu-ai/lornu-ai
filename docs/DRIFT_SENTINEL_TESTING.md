# Drift-Sentinel Testing Guide

This guide explains how to test the **Drift-Sentinel** infrastructure drift detection workflow.

## Quick Test (Manual Trigger)

### Option 1: GitHub Actions UI (Easiest)

1. **Navigate to Actions**
   - Go to: `https://github.com/lornu-ai/lornu-ai/actions`
   - Find: **"Drift-Sentinel: Infrastructure Drift Detection & Remediation"**

2. **Trigger Manual Run**
   - Click **"Run workflow"** dropdown
   - Select:
     - **Workspace**: `all` (to test both) or a specific workspace
     - **Remediation**: `false` (just detect, don't apply)
   - Click **"Run workflow"**

3. **Monitor Execution**
   - Watch the workflow run in real-time
   - Check each job's logs for:
     - ✅ "No drift detected" (expected if infrastructure matches code)
     - ⚠️ "DRIFT DETECTED" (if there are changes)
     - ❌ Error messages (if something is misconfigured)

### Option 2: GitHub CLI

```bash
# Test drift detection for all workspaces
gh workflow run drift-sentinel.yml \
  -f workspace=all \
  -f remediation=false

# Test specific workspace (staging)
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-staging-aws \
  -f remediation=false

# Test specific workspace (production)
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-kustomize \
  -f remediation=false

# View workflow runs
gh run list --workflow=drift-sentinel.yml

# Watch a specific run
gh run watch <run-id>
```

## What to Expect

### ✅ Success Case (No Drift)

When infrastructure matches Terraform code:

```
✅ No drift detected in workspace: lornu-ai-kustomize
✅ No drift detected in workspace: lornu-ai-staging-aws
```

**Workflow Summary:**
- Both jobs complete successfully
- Exit code: `0` (no changes)
- No artifacts uploaded
- No alerts triggered

### ⚠️ Drift Detected Case

When infrastructure has diverged:

```
⚠️ DRIFT DETECTED in workspace: lornu-ai-kustomize
```

**Workflow Summary:**
- Job completes with drift detected
- Exit code: `2` (changes detected)
- Artifact uploaded: `drift-plan-{workspace}-{run-id}`
- Drift report generated in step summary
- Alert message displayed (Better Stack integration pending)

**Check the Artifact:**
1. Go to workflow run summary
2. Download `drift-plan-{workspace}-{run-id}` artifact
3. Extract and review:
   - `drift-plan.json` - JSON format plan
   - `tfplan.binary` - Binary Terraform plan

### ❌ Error Case

If Terraform plan fails:

```
❌ ERROR during plan execution
```

**Common Causes:**
- Missing secrets (check GitHub repository secrets)
- Terraform Cloud authentication issues
- AWS credentials not configured
- Terraform code syntax errors

## Testing Remediation Flow

⚠️ **Warning**: Remediation applies Terraform changes. Only test in non-production first!

### Step 1: Detect Drift

```bash
# First, detect drift
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-staging-aws \
  -f remediation=false
```

### Step 2: Review Drift Plan

1. Wait for workflow to complete
2. Download drift plan artifact
3. Review changes in `drift-plan.json`
4. Verify changes are expected

### Step 3: Trigger Remediation

```bash
# Only if drift is confirmed and expected
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-staging-aws \
  -f remediation=true
```

**What Happens:**
- Downloads the drift plan artifact
- Runs `terraform apply` with the plan
- Applies changes to restore state consistency
- Generates remediation summary

## Simulating Drift (For Testing)

To test drift detection, you can manually create drift:

### Method 1: Manual AWS Console Change

1. **Create Drift in Staging** (safer for testing):
   ```bash
   # Example: Add a tag to an EKS cluster manually
   aws eks tag-resource \
     --resource-arn arn:aws:eks:us-east-1:ACCOUNT:cluster/lornu-ai-staging \
     --tags Key=TestDrift,Value=ManualChange
   ```

2. **Run Drift Detection**:
   ```bash
   gh workflow run drift-sentinel.yml \
     -f workspace=lornu-ai-staging-aws \
     -f remediation=false
   ```

3. **Verify Detection**:
   - Check workflow logs for drift detection
   - Review drift plan artifact
   - Confirm the manual tag change is detected

4. **Remediate** (optional):
   ```bash
   # Remove the tag via Terraform or manual removal
   aws eks untag-resource \
     --resource-arn arn:aws:eks:us-east-1:ACCOUNT:cluster/lornu-ai-staging \
     --tag-keys TestDrift
   ```

### Method 2: Modify Terraform Code Temporarily

1. **Temporarily change a resource**:
   ```hcl
   # In terraform/aws/staging/main.tf
   resource "aws_eks_cluster" "example" {
     # ... existing config ...
     tags = {
       TestDrift = "TemporaryChange"
     }
   }
   ```

2. **Commit and push** (to a test branch):
   ```bash
   git checkout -b test/drift-detection
   # Make change
   git commit -am "Test: Simulate drift"
   git push origin test/drift-detection
   ```

3. **Run drift detection** (on main/develop branch):
   - The drift will be detected because code doesn't match state
   - This tests the detection mechanism

4. **Revert change**:
   ```bash
   git checkout develop
   # Delete test branch
   ```

## Verification Checklist

After running drift detection, verify:

- [ ] **Workflow Completes Successfully**
  - Both jobs (detect-drift) run without errors
  - Check: `gh run view <run-id>`

- [ ] **Terraform Plans Execute**
  - No authentication errors
  - No missing variable errors
  - Plans complete with exit code 0 or 2

- [ ] **Artifacts Generated** (if drift detected)
  - Artifact name: `drift-plan-{workspace}-{run-id}`
  - Contains: `drift-plan.json` and `tfplan.binary`

- [ ] **Reports Generated** (if drift detected)
  - Step summary shows drift report
  - Report includes workspace, environment, timestamp
  - Plan summary is readable

- [ ] **Filtering Works** (manual dispatch)
  - Selecting specific workspace only runs that workspace
  - Selecting "all" runs both workspaces

## Troubleshooting

### Workflow Not Appearing

**Issue**: Can't find "Drift-Sentinel" in Actions tab

**Solution**:
- Ensure workflow file is committed: `.github/workflows/drift-sentinel.yml`
- Check file is on the correct branch (usually `main` or `develop`)
- Refresh GitHub Actions page

### Authentication Errors

**Issue**: `Error: Failed to configure AWS credentials`

**Solution**:
- Verify `AWS_ACTIONS_ROLE_ARN` secret exists
- Check OIDC trust relationship is configured
- Ensure role has necessary permissions

### Terraform Cloud Errors

**Issue**: `Error: Failed to initialize Terraform`

**Solution**:
- Verify `AWS_TF_API_TOKEN` secret is set
- Check Terraform Cloud workspace exists
- Ensure backend configuration matches workspace name

### Missing Secrets

**Issue**: `Error: Required secret not found`

**Solution**:
- Check all required secrets are set in repository settings
- For production: `PROD_DOMAIN`, `PROD_DB_USERNAME`, etc.
- For staging: `ACM_CERTIFICATE_ARN`, `SECRETS_MANAGER_ARN_PATTERN`

## Scheduled Runs

The workflow runs automatically **every hour** via cron schedule.

To verify scheduled runs:

```bash
# List recent runs
gh run list --workflow=drift-sentinel.yml --limit 10

# Check if scheduled runs are happening
gh run list --workflow=drift-sentinel.yml --event schedule
```

**Note**: Scheduled runs may take a few hours to appear after first commit.

## Next Steps

After successful testing:

1. **Monitor First Scheduled Run**
   - Wait for next hour (cron: `0 * * * *`)
   - Verify automatic execution works

2. **Set Up Better Stack Integration** (Optional)
   - Add `BETTER_STACK_API_TOKEN` secret
   - Configure heartbeat ID
   - Uncomment alerting code in workflow

3. **Document Any Issues**
   - Update this guide with findings
   - Report bugs or improvements

## Example Test Session

```bash
# 1. Test detection for staging
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-staging-aws \
  -f remediation=false

# 2. Wait for completion (check status)
gh run watch

# 3. View results
gh run view --log

# 4. If drift detected, review artifact
# (Download from GitHub UI or use gh CLI)

# 5. Test production (if needed)
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-kustomize \
  -f remediation=false
```

---

**See Also:**
- [AGENTS.md](../AGENTS.md) - Drift remediation instructions
- [Issue #420](https://github.com/lornu-ai/lornu-ai/issues/420) - Feature request details

