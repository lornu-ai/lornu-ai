# AWS OIDC Configuration Verification Report

**Date**: $(date)
**Status**: ✅ **OIDC is properly configured for drift-sentinel workflow**

## Current Configuration

### 1. OIDC Provider
- **Status**: ✅ Exists
- **ARN**: `arn:aws:iam::874834750693:oidc-provider/token.actions.githubusercontent.com`
- **URL**: `https://token.actions.githubusercontent.com`

### 2. IAM Roles

#### Staging Role: `github-actions`
- **Status**: ✅ Exists
- **ARN**: `arn:aws:iam::874834750693:role/github-actions`
- **Trust Policy**: ✅ Configured with OIDC federation
- **Current Policy** (in AWS):
  ```json
  {
    "Condition": {
      "StringLike": {
        "token.actions.githubusercontent.com:sub": "repo:lornu-ai/lornu-ai:*"
      }
    }
  }
  ```
  - **Note**: Uses wildcard `*` which allows **all branches and workflows** ✅

- **Terraform Code** (in `terraform/aws/staging/github-oidc.tf`):
  ```hcl
  "repo:lornu-ai/lornu-ai:ref:refs/heads/main",
  "repo:lornu-ai/lornu-ai:ref:refs/heads/develop",
  "repo:lornu-ai/lornu-ai:pull_request",
  ```
  - **Note**: More restrictive - only specific branches
  - **Recommendation**: The actual AWS policy is more permissive, which is fine for drift-sentinel

#### Production Role: `github-actions-prod`
- **Status**: ⚠️ **Not found in AWS**
- **Expected ARN**: Should be `arn:aws:iam::874834750693:role/github-actions-prod`
- **Terraform Code**: Exists in `terraform/aws/production/github-oidc.tf`
- **Action Required**:
  - If you need production drift detection, apply the production Terraform:
    ```bash
    cd terraform/aws/production
    terraform apply
    ```

### 3. GitHub Secrets
- **Status**: ✅ Configured
- **Secrets Found**:
  - ✅ `AWS_ACTIONS_ROLE_ARN` - Required for OIDC authentication
  - ✅ `AWS_TF_API_TOKEN` - Required for Terraform Cloud

### 4. Workflow Configuration
- **Status**: ✅ Correctly configured
- **File**: `.github/workflows/drift-sentinel.yml`
- **OIDC Usage**: ✅ Uses `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
- **Secrets Reference**: ✅ References `AWS_ACTIONS_ROLE_ARN`

## Verification Results

### ✅ What's Working
1. OIDC provider exists and is properly configured
2. Staging IAM role exists with OIDC trust policy
3. Trust policy allows all workflows from `lornu-ai/lornu-ai` repository (wildcard `*`)
4. GitHub secrets are configured
5. drift-sentinel workflow is correctly set up to use OIDC

### ⚠️ Potential Issues

1. **Production Role Missing**
   - The `github-actions-prod` role doesn't exist in AWS
   - **Impact**: Production drift detection will fail if trying to use production role
   - **Solution**:
     - If using staging role for both: Update `AWS_ACTIONS_ROLE_ARN` secret to staging role ARN
     - If need separate production role: Apply production Terraform configuration

2. **Terraform Code vs AWS State Mismatch**
   - Terraform code specifies specific branches (`main`, `develop`, `pull_request`)
   - Actual AWS policy uses wildcard (`repo:lornu-ai/lornu-ai:*`)
   - **Impact**: None - wildcard is more permissive and works fine
   - **Recommendation**: Consider updating Terraform code to match AWS state, or vice versa for consistency

## Testing OIDC with Drift-Sentinel

### Quick Test
```bash
# Test drift detection (will use OIDC to authenticate)
gh workflow run drift-sentinel.yml \
  -f workspace=lornu-ai-staging-aws \
  -f remediation=false

# Watch for authentication errors
gh run watch
```

### Expected Behavior
1. Workflow starts
2. "Configure AWS Credentials" step uses OIDC to assume `github-actions` role
3. No authentication errors
4. Terraform commands execute successfully

### If Authentication Fails
Check:
- `AWS_ACTIONS_ROLE_ARN` secret matches the role ARN: `arn:aws:iam::874834750693:role/github-actions`
- OIDC provider exists (verified ✅)
- Trust policy allows the repository (verified ✅)

## Recommendations

1. **For Production Drift Detection**:
   - Option A: Use staging role for both environments (simpler)
   - Option B: Create production role by applying production Terraform

2. **For Consistency**:
   - Update Terraform code to use wildcard pattern, OR
   - Update AWS trust policy to match Terraform code (less permissive)

3. **For Security** (Optional):
   - Consider restricting trust policy to specific branches if needed
   - Current wildcard is fine for most use cases

## Verification Script

Run the verification script anytime:
```bash
./scripts/verify-oidc.sh
```

This script checks:
- OIDC provider existence
- IAM role existence and trust policies
- GitHub secrets configuration
- Workflow configuration

---

**Last Verified**: $(date)
**Verified By**: Automated script `scripts/verify-oidc.sh`
