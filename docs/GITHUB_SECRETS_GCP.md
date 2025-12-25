# GitHub Secrets Configuration for GCP Infrastructure

## Simplified Setup (Using Service Account Key)

This setup uses the default Compute Engine service account with a JSON key file.
**Note**: Workload Identity Federation (OIDC) can be added later for enhanced security.

---

## Required Secrets (3 total)

### 1. **GCP_PROJECT_ID**
- **Description**: Your Google Cloud Project ID
- **Example**: `lornu-ai-prod-12345`
- **How to get**:
  ```bash
  gcloud projects list
  ```
  Or from GCP Console: https://console.cloud.google.com/home/dashboard

---

### 2. **GCP_CREDENTIALS_JSON**
- **Description**: Service account JSON key for authentication
- **Used in**: `google-github-actions/auth@v2` action
- **How to get**:

  **Option A: Use Default Compute Engine Service Account** (Recommended for quick start)
  ```bash
  # Get the default compute service account email
  PROJECT_ID="your-project-id"
  DEFAULT_SA="${PROJECT_ID/./-}-compute@developer.gserviceaccount.com"

  # Create a key for the default service account
  gcloud iam service-accounts keys create ~/gcp-key.json \
    --iam-account="${DEFAULT_SA}"

  # Display the key (copy this entire JSON)
  cat ~/gcp-key.json

  # IMPORTANT: Delete the local key file after copying to GitHub
  rm ~/gcp-key.json
  ```

  **Option B: Create Custom Service Account**
  ```bash
  # Create service account
  gcloud iam service-accounts create github-actions \
    --display-name="GitHub Actions" \
    --description="Service account for GitHub Actions CI/CD"

  # Grant necessary roles
  PROJECT_ID="your-project-id"
  SA_EMAIL="github-actions@${PROJECT_ID}.iam.gserviceaccount.com"

  gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/editor"

  # Create key
  gcloud iam service-accounts keys create ~/gcp-key.json \
    --iam-account="${SA_EMAIL}"

  # Display and copy the JSON
  cat ~/gcp-key.json

  # Delete local key
  rm ~/gcp-key.json
  ```

- **Security Note**: The JSON key should be treated as a password. Never commit it to Git!

---

### 3. **GCP_TF_API_TOKEN**
- **Description**: Terraform Cloud API token for remote state management
- **Used in**: `hashicorp/setup-terraform@v3` action
- **How to get**:
  1. Go to https://app.terraform.io/app/settings/tokens
  2. Click "Create an API token"
  3. Give it a name (e.g., "GitHub Actions - lornu-ai")
  4. Copy the token value
- **Permissions**: Must have access to the `lornu-ai` organization and `gcp-lornu-ai` workspace

---

## How to Add Secrets to GitHub

### Via GitHub Web UI:
1. Go to: https://github.com/lornu-ai/lornu-ai/settings/secrets/actions
2. Click "New repository secret"
3. Enter the name (exactly as listed above)
4. Paste the value
5. Click "Add secret"

### Via GitHub CLI:
```bash
# Set GCP Project ID
gh secret set GCP_PROJECT_ID --body "your-project-id"

# Set GCP Credentials (paste the entire JSON)
gh secret set GCP_CREDENTIALS_JSON < ~/path/to/gcp-key.json

# Set Terraform Cloud token
gh secret set GCP_TF_API_TOKEN --body "your-tfc-api-token"
```

---

## Verification

Check that all secrets are set:
```bash
gh secret list
```

Expected output:
```
GCP_CREDENTIALS_JSON    Updated 2025-12-25
GCP_PROJECT_ID          Updated 2025-12-25
GCP_TF_API_TOKEN            Updated 2025-12-25
```

---

## Testing the Setup

Once secrets are configured, test by pushing to `gcp-develop`:

```bash
git push origin gcp-develop
```

Monitor the workflow at:
https://github.com/lornu-ai/lornu-ai/actions

---

## Security Best Practices

- ✅ **Delete local key files** after uploading to GitHub Secrets
- ✅ **Rotate service account keys** every 90 days
- ✅ **Use least-privilege permissions** (currently using `roles/editor`)
- ⏱️ **Upgrade to Workload Identity Federation (OIDC)** later for keyless authentication

---

## Future Enhancement: Workload Identity Federation

Once the infrastructure is stable, we can migrate to OIDC for enhanced security:
- No static credentials (keys)
- Automatic token rotation
- Scoped to specific branch (`gcp-develop`)

The WIF configuration is already prepared in `terraform/gcp/wif.tf.disabled` and can be enabled when ready.
