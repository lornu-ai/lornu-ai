# Terraform Cloud Workspace Setup for GCP

The `gcp-lornu-ai` workspace in Terraform Cloud needs the following environment variables configured.

## Required Environment Variables in Terraform Cloud

Go to: https://app.terraform.io/app/lornu-ai/workspaces/gcp-lornu-ai/variables

### 1. **GOOGLE_CREDENTIALS** (Sensitive)
- **Category**: Environment variable
- **Value**: The entire JSON content of your service account key
- **Sensitive**: ✅ Yes (check the box)
- **Description**: GCP service account credentials for authentication

```bash
# Copy the content of your service account JSON key
cat ~/path/to/service-account-key.json
# Paste the entire JSON into TFC
```

### 2. **TF_VAR_project_id**
- **Category**: Terraform variable
- **Value**: Your GCP project ID (e.g., `lornu-ai-prod-12345`)
- **Sensitive**: ❌ No
- **Description**: GCP Project ID

### 3. **GOOGLE_PROJECT** (Optional but recommended)
- **Category**: Environment variable
- **Value**: Your GCP project ID (same as above)
- **Sensitive**: ❌ No
- **Description**: Default GCP project for provider

---

## How to Add Variables

### Via Terraform Cloud Web UI:
1. Go to https://app.terraform.io/app/lornu-ai/workspaces/gcp-lornu-ai/variables
2. Click **"+ Add variable"**
3. Select **"Environment variable"** for `GOOGLE_CREDENTIALS`
4. Paste the JSON key content
5. Check **"Sensitive"**
6. Click **"Save variable"**
7. Repeat for `TF_VAR_project_id` (select "Terraform variable")

### Via Terraform Cloud API (using `tfe` CLI):
```bash
# Install tfe CLI
brew install hashicorp/tap/tfe

# Set workspace
export TFE_ORG="lornu-ai"
export TFE_WORKSPACE="gcp-lornu-ai"

# Add GOOGLE_CREDENTIALS
tfe variable create \
  --name "GOOGLE_CREDENTIALS" \
  --value "$(cat ~/path/to/sa-key.json)" \
  --category env \
  --sensitive

# Add TF_VAR_project_id
tfe variable create \
  --name "TF_VAR_project_id" \
  --value "your-project-id" \
  --category terraform
```

---

## Verification

After adding the variables, trigger a new Terraform run and verify the provider authentication works:

```bash
# Trigger a new workflow run
git commit --allow-empty -m "test: verify TFC credentials" && git push origin gcp-develop
```

Check the Terraform Cloud run at:
https://app.terraform.io/app/lornu-ai/workspaces/gcp-lornu-ai/runs

---

## Important Notes

- ✅ `GOOGLE_CREDENTIALS` must be **Environment variable**, not Terraform variable
- ✅ Make sure to mark it as **Sensitive**
- ✅ The JSON must be on a single line, or you can paste it as-is (TFC handles multiline)
- ⚠️ **Never commit** the service account key to Git
