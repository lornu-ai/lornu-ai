#!/bin/bash
# Bootstrap Workload Identity Federation for GitHub Actions using gcloud CLI
# This can be run before Terraform to bootstrap WIF resources
# Requires: gcloud CLI authenticated with org-level permissions

set -e

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")

echo "🚀 Bootstrapping Workload Identity Federation for GitHub Actions"
echo "Project: $PROJECT_ID (Number: $PROJECT_NUMBER)"
echo ""

# Step 1: Create Workload Identity Pool
echo "📦 Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe github-actions-pool \
  --project="$PROJECT_ID" \
  --location="global" >/dev/null 2>&1; then
  echo "✅ Pool 'github-actions-pool' already exists"
else
  gcloud iam workload-identity-pools create github-actions-pool \
    --project="$PROJECT_ID" \
    --location="global" \
    --display-name="GitHub Actions Pool" \
    --description="Workload Identity Pool for GitHub Actions OIDC authentication"
  echo "✅ Pool created"
fi

# Step 2: Create Workload Identity Provider
echo "🔐 Creating Workload Identity Provider..."
if gcloud iam workload-identity-pools providers describe github-actions-provider \
  --project="$PROJECT_ID" \
  --location="global" \
  --workload-identity-pool="github-actions-pool" >/dev/null 2>&1; then
  echo "✅ Provider 'github-actions-provider' already exists"
  echo "⚠️  If you need to recreate it, delete first with:"
  echo "   gcloud iam workload-identity-pools providers delete github-actions-provider \\"
  echo "     --project=$PROJECT_ID --location=global --workload-identity-pool=github-actions-pool"
else
  gcloud iam workload-identity-pools providers create-oidc github-actions-provider \
    --project="$PROJECT_ID" \
    --location="global" \
    --workload-identity-pool="github-actions-pool" \
    --display-name="GitHub Actions Provider" \
    --description="OIDC provider for GitHub Actions" \
    --issuer-uri="https://token.actions.githubusercontent.com" \
    --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref,attribute.workflow=assertion.workflow"
  echo "✅ Provider created"
fi

# Get the provider resource name for reference
PROVIDER_NAME="projects/$PROJECT_NUMBER/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider"

echo ""
echo "✅ WIF Bootstrap Complete!"
echo ""
echo "Provider Resource Name: $PROVIDER_NAME"
echo ""
echo "Next steps:"
echo "1. Run Terraform to create service account and IAM bindings"
echo "2. Terraform will manage the pool/provider going forward"
echo "3. Get outputs for GitHub secrets:"
echo "   - terraform output github_actions_wif_provider"
echo "   - terraform output github_actions_service_account_email"

