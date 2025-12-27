# Unified Multi-Cloud OIDC Authentication Migration Plan

**Issue**: [#435](https://github.com/lornu-ai/lornu-ai/issues/435)  
**Status**: In Progress  
**Target**: 100% OIDC-based authentication for AWS and GCP

## Executive Summary

This migration plan implements unified OIDC-based authentication for GitHub Actions across AWS and GCP, eliminating the need for static service account keys and access keys. This improves security, reduces credential sprawl, and enables centralized access management.

## Current State

### AWS OIDC ✅
- **Status**: Fully implemented
- **Terraform**: `terraform/aws/github-oidc.tf`
- **Workflows**: All AWS workflows use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
- **Secrets Required**: `AWS_ACTIONS_ROLE_ARN` (IAM Role ARN only)

### GCP OIDC ❌
- **Status**: Not implemented (using static keys)
- **Terraform**: `terraform/gcp/github-wif.tf` (newly created)
- **Workflows**: Using `credentials_json: ${{ secrets.GCP_CREDENTIALS_JSON }}`
- **Secrets Required**: `GCP_CREDENTIALS_JSON` (static service account key - **TO BE REMOVED**)

## Target State

### Unified OIDC Architecture

Both AWS and GCP will use OIDC-based authentication:

| Provider | Identity Link | Trust Policy | GHA Action | Auth Output |
|----------|--------------|--------------|------------|-------------|
| **AWS** | IAM OIDC Provider | IAM Role Trust | `aws-actions/configure-aws-credentials@v4` | Temporary AWS credentials |
| **GCP** | Workload Identity Pool + Provider | WIF IAM Binding | `google-github-actions/auth@v2` | Temporary GCP credentials |

### Standardized Workflow Configuration

All workflows will use this standardized permissions block:

```yaml
permissions:
  id-token: write  # Required for OIDC token exchange
  contents: read   # Required for actions/checkout
```

### Unified Authentication Steps

**AWS:**
```yaml
- name: Configure AWS Credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ACTIONS_ROLE_ARN }}
    aws-region: us-east-1
```

**GCP:**
```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
    service_account: ${{ secrets.GCP_SA_EMAIL }}
```

## Implementation Steps

### Phase 1: GCP WIF Infrastructure ✅

**Status**: Completed

1. ✅ Created `terraform/gcp/github-wif.tf` with:
   - Workload Identity Pool (`github-actions-pool`)
   - Workload Identity Provider (OIDC)
   - Service Account (`github-actions@gcp-lornu-ai.iam.gserviceaccount.com`)
   - IAM permissions (Editor, Secret Manager Admin, Artifact Registry Writer, GKE Developer, Storage Admin)
   - WIF binding for `lornu-ai/lornu-ai` repository

2. **Next**: Apply Terraform to create infrastructure
   ```bash
   cd terraform/gcp
   terraform plan
   terraform apply
   ```

3. **Outputs to capture**:
   - `github_actions_wif_provider` → Set as `GCP_WIF_PROVIDER` secret
   - `github_actions_service_account_email` → Set as `GCP_SA_EMAIL` secret

### Phase 2: Update Workflows ✅

**Status**: Completed

1. ✅ Updated `.github/workflows/gcp-secrets-manager.yml`
   - Changed from `credentials_json` to `workload_identity_provider` + `service_account`
   - Updated action version from `v3` to `v2` (WIF support)

2. ✅ Updated `.github/workflows/deploy-gke.yml`
   - Changed both authentication steps (build-and-push and deploy jobs)
   - Updated action version from `v3` to `v2`

3. ✅ Verified permissions blocks:
   - Both workflows already have `id-token: write` ✅

### Phase 3: GitHub Secrets Configuration

**Status**: Pending

1. **Add new secrets** (after Terraform apply):
   ```bash
   gh secret set GCP_WIF_PROVIDER --body "projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider"
   gh secret set GCP_SA_EMAIL --body "github-actions@gcp-lornu-ai.iam.gserviceaccount.com"
   ```

2. **Verify existing secrets**:
   - ✅ `AWS_ACTIONS_ROLE_ARN` (already exists)
   - ✅ `AWS_TF_API_TOKEN` (for Terraform Cloud - not related to OIDC)
   - ✅ `GCP_TF_API_TOKEN` (for Terraform Cloud - not related to OIDC)

3. **Remove deprecated secret** (after migration verification):
   - ❌ `GCP_CREDENTIALS_JSON` (to be removed after successful migration)

### Phase 4: Testing & Verification

**Status**: Pending

1. **Test GCP Secrets Manager workflow**:
   ```bash
   gh workflow run gcp-secrets-manager.yml
   gh run watch
   ```
   - Verify authentication succeeds
   - Verify secrets sync works
   - Check Cloud Audit Logs for GitHub Actor attribution

2. **Test GKE Deploy workflow**:
   ```bash
   gh workflow run deploy-gke.yml -f environment=lornu-dev
   gh run watch
   ```
   - Verify authentication succeeds
   - Verify image push to Artifact Registry works
   - Verify GKE deployment works

3. **Verify audit logs**:
   - Check GCP Cloud Audit Logs for `principalEmail: github-actions@gcp-lornu-ai.iam.gserviceaccount.com`
   - Verify `callerIp` shows GitHub Actions IP ranges
   - Verify `requestMetadata.callerSuppliedUserAgent` contains GitHub Actions info

### Phase 5: Documentation & Cleanup

**Status**: Pending

1. ✅ Update this migration plan with results
2. Update `docs/SECRETS_MANAGEMENT.md` with OIDC instructions
3. Update `.github/system-instruction.md` with OIDC best practices
4. Remove `GCP_CREDENTIALS_JSON` secret after 30-day verification period
5. Archive this migration plan

## Security Benefits

### Before (Static Keys)
- ❌ Keys never expire (90-day manual rotation required)
- ❌ Keys persist if GitHub Org is compromised
- ❌ No granular audit trail (can't see which workflow/actor)
- ❌ Credential sprawl (one key per repo/environment)

### After (OIDC)
- ✅ Tokens expire automatically (1-hour default)
- ✅ No persistent keys stored in GitHub
- ✅ Full audit trail (Cloud Audit Logs show GitHub Actor, workflow, run ID)
- ✅ Centralized management (IAM policies control access)
- ✅ Least privilege (roles scoped to specific repositories/branches)

## Rollback Plan

If issues occur during migration:

1. **Immediate rollback**: Revert workflow changes to use `credentials_json`
2. **Keep WIF infrastructure**: Leave Terraform resources in place (no cost)
3. **Gradual migration**: Migrate workflows one at a time

## Success Criteria

- [x] GCP WIF Terraform configuration created
- [x] Workflows updated to use WIF
- [ ] Terraform applied and infrastructure created
- [ ] GitHub secrets configured (`GCP_WIF_PROVIDER`, `GCP_SA_EMAIL`)
- [ ] All GCP workflows tested and verified
- [ ] Cloud Audit Logs show GitHub Actor attribution
- [ ] `GCP_CREDENTIALS_JSON` secret removed
- [ ] Documentation updated

## References

- [Issue #435](https://github.com/lornu-ai/lornu-ai/issues/435) - Original requirement
- [AWS OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [GCP WIF Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [google-github-actions/auth](https://github.com/google-github-actions/auth)

## Timeline

- **Phase 1**: ✅ Completed (Terraform configuration)
- **Phase 2**: ✅ Completed (Workflow updates)
- **Phase 3**: Pending (Terraform apply + secrets configuration)
- **Phase 4**: Pending (Testing)
- **Phase 5**: Pending (Documentation)

**Estimated completion**: 1-2 weeks (including testing and verification period)

