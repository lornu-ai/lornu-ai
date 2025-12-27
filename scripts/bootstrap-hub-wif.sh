#!/bin/bash
# Bootstrap script for Hub WIF - Run this ONCE to enable TFC authentication
# After this, TFC can manage the resources via Terraform

set -e

# Configuration - UPDATE THESE
PROJECT_ID="${GCP_HUB_PROJECT_ID:-gcp-lornu-ai}"
SA_NAME="tf-cloud-sa"
POOL_ID="tfc-pool"
PROVIDER_ID="tfc-provider"
TFC_WORKSPACE="lornu-ai-hub"

echo "=== Hub WIF Bootstrap Script ==="
echo "Project: $PROJECT_ID"
echo "Service Account: $SA_NAME"
echo "WIF Pool: $POOL_ID"
echo ""

# Get project number
PROJECT_NUM=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
echo "Project Number: $PROJECT_NUM"

# 1. Create Service Account (if not exists)
echo ""
echo ">>> Step 1: Creating Service Account..."
if gcloud iam service-accounts describe "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" --project="$PROJECT_ID" &>/dev/null; then
    echo "Service Account already exists"
else
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="Lornu-AI Hub Orchestrator" \
        --project="$PROJECT_ID"
    echo "Service Account created"
fi

# 2. Create Workload Identity Pool (if not exists)
echo ""
echo ">>> Step 2: Creating Workload Identity Pool..."
if gcloud iam workload-identity-pools describe "$POOL_ID" --location=global --project="$PROJECT_ID" &>/dev/null; then
    echo "WIF Pool already exists"
else
    gcloud iam workload-identity-pools create "$POOL_ID" \
        --location=global \
        --display-name="TFC Pool" \
        --project="$PROJECT_ID"
    echo "WIF Pool created"
fi

# 3. Create OIDC Provider (if not exists)
echo ""
echo ">>> Step 3: Creating OIDC Provider for TFC..."
if gcloud iam workload-identity-pools providers describe "$PROVIDER_ID" --location=global --workload-identity-pool="$POOL_ID" --project="$PROJECT_ID" &>/dev/null; then
    echo "OIDC Provider already exists"
else
    gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_ID" \
        --location=global \
        --workload-identity-pool="$POOL_ID" \
        --issuer-uri="https://app.terraform.io" \
        --attribute-mapping="google.subject=assertion.sub,attribute.terraform_workspace_name=assertion.terraform_workspace_name,attribute.terraform_organization_name=assertion.terraform_organization_name" \
        --attribute-condition="assertion.sub != 'foo'" \
        --project="$PROJECT_ID"
    echo "OIDC Provider created"
fi

# 4. Grant Workload Identity User role
echo ""
echo ">>> Step 4: Granting workloadIdentityUser role..."
MEMBER="principalSet://iam.googleapis.com/projects/${PROJECT_NUM}/locations/global/workloadIdentityPools/${POOL_ID}/attribute.terraform_workspace_name/${TFC_WORKSPACE}"

gcloud iam service-accounts add-iam-policy-binding \
    "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --member="$MEMBER" \
    --role="roles/iam.workloadIdentityUser" \
    --project="$PROJECT_ID" \
    --condition=None

echo "workloadIdentityUser granted"

# 5. Grant Service Account Token Creator role (THIS IS THE FIX)
echo ""
echo ">>> Step 5: Granting serviceAccountTokenCreator role..."
gcloud iam service-accounts add-iam-policy-binding \
    "${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --member="$MEMBER" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --project="$PROJECT_ID" \
    --condition=None

echo "serviceAccountTokenCreator granted"

# 6. Grant SA Admin role at project level
echo ""
echo ">>> Step 6: Granting serviceAccountAdmin role at project level..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

echo "serviceAccountAdmin granted"

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "TFC Workspace Variables to set:"
echo "  TFC_GCP_PROVIDER_AUTH = true"
echo "  TFC_GCP_RUN_SERVICE_ACCOUNT_EMAIL = ${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
echo "  TFC_GCP_WORKLOAD_PROVIDER_NAME = projects/${PROJECT_NUM}/locations/global/workloadIdentityPools/${POOL_ID}/providers/${PROVIDER_ID}"
echo ""
echo "Now run: terraform destroy (or plan/apply) in the lornu-ai-hub workspace"
