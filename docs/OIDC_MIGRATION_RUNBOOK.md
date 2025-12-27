# Zero-Secret OIDC Migration Runbook

This runbook documents the process for transitioning from static credentials to OIDC-based Dynamic Provider Credentials for Terraform Cloud.

## Prerequisites

Ensure the following PRs are merged and applied before proceeding:

| Phase | PR | Description | Required Outputs |
|-------|-----|-------------|------------------|
| 1 | #436 | AWS TFC OIDC Provider | `tfc_oidc_role_arn` |
| 2 | #437 | GCP TFC Workload Identity | `tfc_workload_identity_provider_name`, `tfc_service_account_email` |
| 3 | #438 | Meta-Terraform Management | Variable injection automation |

## Phase 4A: Variable Injection Verification

### Option A: Manual Variable Setup (Before Phase 3 is applied)

If the `tfc-management` workspace is not yet operational, manually configure variables in TFC:

#### AWS Workspace (`aws-kustomize`)

1. Navigate to **Terraform Cloud → Workspaces → aws-kustomize → Variables**
2. Add the following **Environment Variables**:

| Key | Value | Category | Sensitive |
|-----|-------|----------|-----------|
| `TFC_AWS_PROVIDER_AUTH` | `true` | env | No |
| `TFC_AWS_RUN_ROLE_ARN` | `<output from Phase 1>` | env | Yes |

#### GCP Workspace (`gcp-lornu-ai`)

1. Navigate to **Terraform Cloud → Workspaces → gcp-lornu-ai → Variables**
2. Add the following **Environment Variables**:

| Key | Value | Category | Sensitive |
|-----|-------|----------|-----------|
| `TFC_GCP_PROVIDER_AUTH` | `true` | env | No |
| `TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL` | `<output from Phase 2>` | env | Yes |
| `TFC_GCP_WORKLOAD_PROVIDER_NAME` | `<output from Phase 2>` | env | Yes |

### Option B: Automated Variable Injection (After Phase 3)

1. Create the `tfc-management` workspace in TFC
2. Set the required input variables from Phase 1 & 2 outputs
3. Run `terraform apply` to inject variables automatically

## Phase 4B: OIDC Connectivity Verification

### AWS Verification

1. Go to **aws-kustomize** workspace in TFC
2. Click **Actions → Start new run → Plan only**
3. Monitor the run output for:
   ```
   Initializing provider plugins...
   - Using previously-installed hashicorp/aws vX.X.X

   OpenID Connect credentials configured through workload identity.
   ```
4. Verify the plan completes without authentication errors

### GCP Verification

1. Go to **gcp-lornu-ai** workspace in TFC
2. Click **Actions → Start new run → Plan only**
3. Monitor the run output for:
   ```
   Initializing provider plugins...
   - Using previously-installed hashicorp/google vX.X.X

   Workload identity federation credentials configured.
   ```
4. Verify the plan completes without authentication errors

## Phase 4C: Legacy Credential Purge

> **WARNING**: Only proceed after successful OIDC verification in Phase 4B.

### Pre-Purge Checklist

- [ ] AWS speculative plan succeeded with OIDC
- [ ] GCP speculative plan succeeded with WIF
- [ ] Both workspaces show "OpenID Connect" or "Workload Identity" in run logs
- [ ] No active runs using legacy credentials

### AWS Credential Removal

1. Navigate to **aws-kustomize → Variables**
2. Locate and delete the following variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
3. Document deletion timestamp: `__________`

### GCP Credential Removal

1. Navigate to **gcp-lornu-ai → Variables**
2. Locate and delete the following variables:
   - `GOOGLE_CREDENTIALS` (JSON key)
   - Any other static GCP credentials
3. Document deletion timestamp: `__________`

### Post-Purge Verification

1. Trigger a new plan in **aws-kustomize**
   - [ ] Plan succeeds
   - [ ] No credential-related errors
2. Trigger a new plan in **gcp-lornu-ai**
   - [ ] Plan succeeds
   - [ ] No credential-related errors

## Rollback Procedure

If OIDC authentication fails after purging legacy credentials:

### AWS Rollback

1. Generate new AWS Access Keys in IAM Console
2. Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to TFC workspace
3. Set `TFC_AWS_PROVIDER_AUTH` to `false` or delete it
4. Verify authentication works with static credentials

### GCP Rollback

1. Generate new Service Account JSON key in GCP Console
2. Add `GOOGLE_CREDENTIALS` variable with the JSON content
3. Set `TFC_GCP_PROVIDER_AUTH` to `false` or delete it
4. Verify authentication works with static credentials

## Troubleshooting

### AWS OIDC Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `AssumeRoleWithWebIdentity error` | Role trust policy mismatch | Verify `app.terraform.io:sub` claim matches workspace |
| `AccessDenied` | Insufficient IAM permissions | Check attached policy grants required permissions |
| `InvalidIdentityToken` | OIDC thumbprint issue | Verify TLS certificate thumbprint is current |

### GCP WIF Issues

| Error | Cause | Solution |
|-------|-------|----------|
| `Permission denied` | WIF binding missing | Verify `workloadIdentityUser` role on service account |
| `Invalid audience` | Issuer mismatch | Verify OIDC issuer is `https://app.terraform.io` |
| `Token exchange failed` | Attribute condition failed | Check `attribute.terraform_organization` condition |

## Completion Checklist

- [ ] Phase 4A: Variables configured in TFC
- [ ] Phase 4B: OIDC verification passed for AWS
- [ ] Phase 4B: WIF verification passed for GCP
- [ ] Phase 4C: Legacy AWS credentials purged
- [ ] Phase 4C: Legacy GCP credentials purged
- [ ] Post-purge verification passed
- [ ] Issue #431 closed

## Related Issues

- Epic: #426 (Zero-Secret OIDC Identity)
- Phase 1: #428 (AWS TFC OIDC Provider)
- Phase 2: #429 (GCP TFC WIF)
- Phase 3: #430 (Meta-Terraform)
- Phase 4: #431 (This runbook)
- Phase 5: #432 (Documentation)
