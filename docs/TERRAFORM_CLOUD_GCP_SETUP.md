# Terraform Cloud GCP Service Account Setup

This document describes how to configure Terraform Cloud to use a GCP service account for authentication.

## Service Account Details

- **Service Account Name**: `tf-cloud-sa`
- **Service Account ID**: `111392155535129873654`
- **Email**: `tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com`
- **Terraform Cloud Variable**: `GOOGLE_CREDENTIALS` (sensitive)

## Setup Steps

### 1. Get Service Account Key

You need to download the service account key JSON file:

```bash
# Using gcloud CLI
gcloud iam service-accounts keys create tf-cloud-sa-key.json \
  --iam-account=tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com

# Or download from GCP Console:
# 1. Go to: https://console.cloud.google.com/iam-admin/serviceaccounts
# 2. Select: tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com
# 3. Click "Keys" tab → "Add Key" → "Create new key" → JSON
```

### 2. Add to Terraform Cloud Workspace

#### Option A: Via Terraform Cloud UI

1. Go to your Terraform Cloud workspace (e.g., `gcp-lornu-ai`)
2. Navigate to: **Variables** → **Workspace Variables**
3. Click **+ Add variable**
4. Set:
   - **Key**: `GOOGLE_CREDENTIALS`
   - **Value**: Paste the entire JSON content from the service account key file
   - **Type**: `HCL` or `String`
   - **Sensitive**: ✅ Check this box
   - **Category**: `Terraform variable`
5. Click **Save variable**

#### Option B: Via Terraform Cloud API

```bash
# Set your Terraform Cloud token
export TF_TOKEN_app_terraform_io="your-token"

# Get workspace ID
WORKSPACE_ID=$(curl -s \
  --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/organizations/lornu-ai/workspaces/gcp-lornu-ai" \
  | jq -r '.data.id')

# Create variable
curl -s \
  --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data "{
    \"data\": {
      \"type\": \"vars\",
      \"attributes\": {
        \"key\": \"GOOGLE_CREDENTIALS\",
        \"value\": $(cat tf-cloud-sa-key.json | jq -c .),
        \"category\": \"terraform\",
        \"sensitive\": true
      },
      \"relationships\": {
        \"workspace\": {
          \"data\": {
            \"type\": \"workspaces\",
            \"id\": \"$WORKSPACE_ID\"
          }
        }
      }
    }
  }" \
  "https://app.terraform.io/api/v2/vars"
```

### 3. Verify in Terraform Configuration

Your Terraform code should reference this variable:

```hcl
provider "google" {
  credentials = var.GOOGLE_CREDENTIALS
  project     = var.gcp_project_id
  region      = var.gcp_region
}

variable "GOOGLE_CREDENTIALS" {
  description = "GCP service account credentials JSON"
  type        = string
  sensitive   = true
}
```

Or if using as a file path:

```hcl
provider "google" {
  credentials = jsondecode(var.GOOGLE_CREDENTIALS)
  project     = var.gcp_project_id
  region      = var.gcp_region
}
```

## Service Account Permissions

Ensure the service account has the necessary permissions:

```bash
# Common required roles for Terraform
gcloud projects add-iam-policy-binding gcp-lornu-ai \
  --member="serviceAccount:tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com" \
  --role="roles/editor"

# Or more granular permissions:
# - roles/compute.admin
# - roles/iam.serviceAccountUser
# - roles/storage.admin
# - roles/resourcemanager.projectIamAdmin
```

## Security Best Practices

1. **Never commit the key file** to git
2. **Mark as sensitive** in Terraform Cloud
3. **Rotate keys regularly** (every 90 days recommended)
4. **Use least privilege** - only grant necessary permissions
5. **Monitor usage** via GCP audit logs

## Troubleshooting

### Error: Invalid Credentials

```bash
# Test credentials locally
export GOOGLE_APPLICATION_CREDENTIALS="tf-cloud-sa-key.json"
gcloud auth activate-service-account tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com \
  --key-file=tf-cloud-sa-key.json
gcloud projects list
```

### Error: Permission Denied

Check service account has required roles:
```bash
gcloud projects get-iam-policy gcp-lornu-ai \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com"
```

### Variable Not Found in Terraform

Ensure:
1. Variable is set in the correct workspace
2. Variable name matches exactly (case-sensitive)
3. Variable category is "Terraform variable" not "Environment variable"

## Workspace Configuration

For GCP workspaces, ensure these variables are also set:

- `GOOGLE_CREDENTIALS` (sensitive) - Service account JSON
- `gcp_project_id` - GCP project ID (e.g., `gcp-lornu-ai`)
- `gcp_region` - Default region (e.g., `us-central1`)
- `gcp_zone` - Default zone (e.g., `us-central1-a`)

---

**Last Updated**: $(date)
**Service Account**: tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com
