#!/bin/bash
# Script to set up GCP service account credentials in Terraform Cloud
# Service Account: tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com

set -e

echo "🔧 Terraform Cloud GCP Service Account Setup"
echo "============================================"
echo ""
echo "Service Account: tf-cloud-sa@gcp-lornu-ai.iam.gserviceaccount.com"
echo ""

# Check for required tools
if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    echo "   Install with: brew install jq"
    exit 1
fi

# Check for Terraform Cloud token
if [ -z "$TF_TOKEN_app_terraform_io" ]; then
    TOKEN_FILE="$HOME/.terraform.d/credentials.tfrc.json"
    if [ -f "$TOKEN_FILE" ]; then
        export TF_TOKEN_app_terraform_io=$(cat "$TOKEN_FILE" | jq -r '.credentials."app.terraform.io".token')
    else
        echo "❌ Terraform Cloud token not found"
        echo "   Set: export TF_TOKEN_app_terraform_io='your-token'"
        echo "   Or run: terraform login"
        exit 1
    fi
fi

echo "✅ Terraform Cloud token found"
echo ""

# Get organization and workspace
read -p "Terraform Cloud Organization [lornu-ai]: " ORG
ORG=${ORG:-lornu-ai}

read -p "Terraform Cloud Workspace [gcp-lornu-ai]: " WORKSPACE
WORKSPACE=${WORKSPACE:-gcp-lornu-ai}

echo ""
echo "Organization: $ORG"
echo "Workspace: $WORKSPACE"
echo ""

# Get service account key file
read -p "Path to service account key JSON file: " KEY_FILE

if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Key file not found: $KEY_FILE"
    exit 1
fi

echo "✅ Key file found"
echo ""

# Get workspace ID
echo "🔍 Looking up workspace..."
WORKSPACE_ID=$(curl -s \
  --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/organizations/$ORG/workspaces/$WORKSPACE" \
  | jq -r '.data.id // empty')

if [ -z "$WORKSPACE_ID" ]; then
    echo "❌ Workspace not found: $ORG/$WORKSPACE"
    echo "   Please create it first in Terraform Cloud UI"
    exit 1
fi

echo "✅ Workspace found: $WORKSPACE_ID"
echo ""

# Read and encode the key file
KEY_CONTENT=$(cat "$KEY_FILE" | jq -c .)

# Check if variable already exists
echo "🔍 Checking for existing variable..."
EXISTING_VAR=$(curl -s \
  --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/vars" \
  | jq -r ".data[] | select(.attributes.key == \"GOOGLE_CREDENTIALS\") | .id")

if [ -n "$EXISTING_VAR" ]; then
    echo "⚠️  Variable GOOGLE_CREDENTIALS already exists"
    read -p "Update existing variable? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔄 Updating variable..."
        curl -s \
          --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
          --header "Content-Type: application/vnd.api+json" \
          --request PATCH \
          --data "{
            \"data\": {
              \"type\": \"vars\",
              \"id\": \"$EXISTING_VAR\",
              \"attributes\": {
                \"value\": $KEY_CONTENT,
                \"sensitive\": true
              }
            }
          }" \
          "https://app.terraform.io/api/v2/vars/$EXISTING_VAR" > /dev/null

        echo "✅ Variable updated successfully"
    else
        echo "Skipping update"
        exit 0
    fi
else
    echo "➕ Creating new variable..."
    curl -s \
      --header "Authorization: Bearer $TF_TOKEN_app_terraform_io" \
      --header "Content-Type: application/vnd.api+json" \
      --request POST \
      --data "{
        \"data\": {
          \"type\": \"vars\",
          \"attributes\": {
            \"key\": \"GOOGLE_CREDENTIALS\",
            \"value\": $KEY_CONTENT,
            \"category\": \"terraform\",
            \"sensitive\": true,
            \"description\": \"GCP service account credentials for tf-cloud-sa\"
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
      "https://app.terraform.io/api/v2/vars" > /dev/null

    echo "✅ Variable created successfully"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Verify in Terraform Cloud UI:"
echo "   https://app.terraform.io/app/$ORG/workspaces/$WORKSPACE/variables"
echo ""
echo "2. Test the configuration:"
echo "   cd terraform/gcp"
echo "   terraform init"
echo "   terraform plan"
echo ""
