#!/bin/bash
# Bootstrap Workload Identity Federation for Terraform Cloud using gcloud CLI
# This can be run before Terraform to bootstrap TFC WIF resources
# Requires: gcloud CLI authenticated with org-level permissions

set -e

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

echo "🚀 Bootstrapping Workload Identity Federation for Terraform Cloud"
echo "Project: $PROJECT_ID (Number: $PROJECT_NUMBER)"
echo ""

# Step 1: Create Workload Identity Pool for TFC
echo "📦 Creating Terraform Cloud Workload Identity Pool..."
if gcloud iam workload-identity-pools describe lornu-tfc-pool \
  --project="$PROJECT_ID" \
  --location="global" >/dev/null 2>&1; then
  echo "✅ Pool 'lornu-tfc-pool' already exists"
else
  gcloud iam workload-identity-pools create lornu-tfc-pool \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="Terraform Cloud Pool" \
    --description="Identity pool for Terraform Cloud Dynamic Provider Credentials"
  echo "✅ Pool created"
fi

# Step 2: Create Workload Identity Provider for TFC
echo "🔐 Creating Terraform Cloud Workload Identity Provider..."
if gcloud iam workload-identity-pools providers describe lornu-tfc-oidc \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="lornu-tfc-pool" >/dev/null 2>&1; then
  echo "✅ Provider 'lornu-tfc-oidc' already exists"
  echo "⚠️  If you need to recreate it, delete first with:"
  echo "   gcloud iam workload-identity-pools providers delete lornu-tfc-oidc \\"
  echo "     --project=$PROJECT_ID --location=global --workload-identity-pool=lornu-tfc-pool"
else
  gcloud iam workload-identity-pools providers create-oidc lornu-tfc-oidc \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="lornu-tfc-pool" \
    --display-name="Terraform Cloud OIDC Provider" \
    --description="OIDC Identity Provider for Terraform Cloud runs" \
    --issuer-uri="https://app.terraform.io" \
    --attribute-mapping="google.subject=assertion.sub,attribute.terraform_organization=assertion.terraform_organization_name,attribute.terraform_workspace=assertion.terraform_workspace_name,attribute.terraform_run_phase=assertion.terraform_run_phase" \
    --attribute-condition="attribute.terraform_organization == \"lornu-ai\""
  echo "✅ Provider created"
fi

# Get the provider resource name for reference
PROVIDER_NAME="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/lornu-tfc-pool/providers/lornu-tfc-oidc"
POOL_NAME="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/lornu-tfc-pool"

echo ""
echo "✅ TFC WIF Bootstrap Complete!"
echo ""
echo "Pool Resource Name: $POOL_NAME"
echo "Provider Resource Name: $PROVIDER_NAME"
echo ""
echo "Next steps:"
echo "1. Configure these in Terraform Cloud workspace settings"
echo "2. Run Terraform to create service account and IAM bindings"
echo "3. Terraform will manage the pool/provider going forward"

