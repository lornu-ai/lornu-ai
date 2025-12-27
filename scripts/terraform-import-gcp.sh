#!/bin/bash

# Terraform Import Script for GCP Resources
# Addresses GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import
# https://github.com/lornu-ai/lornu-ai/issues/444
#
# This script implements Phase 2 requirements: The Import Workflow
# - Uses Terraform 1.5+ import block syntax for idempotent imports
# - Generates HCL with terraform plan -generate-config-out
# - Ensures zero-diff verification (requirement 3.5)
#
# GitHub CLI Integration:
#   gh issue view 444  # Review requirements
#   ./scripts/terraform-import-gcp.sh
#   gh pr create --assignee @me --label "infrastructure" --title "feat: import GCP resources to Terraform"

set -e

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
REGION="${GCP_REGION:-us-central1}"
CLUSTER_NAME="${GKE_CLUSTER_NAME:-lornu-ai-gke}"

echo "🔄 Terraform Import Assistant for GCP"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "====================================="

# Function to check if resource exists in Terraform state
check_terraform_state() {
    local resource="$1"
    if terraform state show "$resource" &>/dev/null; then
        echo "✅ $resource already in Terraform state"
        return 0
    else
        echo "❌ $resource not in Terraform state"
        return 1
    fi
}

# Function to check if resource exists in GCP
check_gcp_resource() {
    local check_command="$1"
    if eval "$check_command" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to import resource using modern import blocks (Terraform 1.5+)
import_resource_modern() {
    local resource="$1"
    local resource_id="$2"
    local description="$3"
    
    echo ""
    echo "📥 Importing $description using modern import blocks..."
    echo "   Resource: $resource"
    echo "   ID: $resource_id"
    
    if check_terraform_state "$resource"; then
        return 0
    fi
    
    # Generate import block in a temporary file
    local import_file="import_${resource//\./_}.tf"
    cat > "$import_file" << EOF
# Import block for $description
import {
  to = $resource
  id = "$resource_id"
}
EOF
    
    echo "📝 Generated import block in $import_file"
    
    # Use terraform plan with generate-config-out (Terraform 1.5+ feature)
    echo "🔄 Running terraform plan with config generation..."
    if terraform plan -generate-config-out="generated_${resource//\./_}.tf"; then
        echo "✅ Successfully planned import for $description"
        echo "📄 Generated configuration in generated_${resource//\./_}.tf"
        
        # Apply the import
        if terraform apply -auto-approve; then
            echo "✅ Successfully imported $description"
            # Clean up temporary import file after successful import
            rm -f "$import_file"
        else
            echo "❌ Failed to apply import for $description"
            return 1
        fi
    else
        echo "❌ Failed to plan import for $description"
        rm -f "$import_file"
        return 1
    fi
}

# Legacy import function for compatibility
import_resource() {
    local resource="$1"
    local resource_id="$2"
    local description="$3"
    
    # Try modern import first, fall back to legacy
    if ! import_resource_modern "$resource" "$resource_id" "$description"; then
        echo "⚠️  Modern import failed, trying legacy method..."
        
        if check_terraform_state "$resource"; then
            return 0
        fi
        
        if terraform import "$resource" "$resource_id"; then
            echo "✅ Successfully imported $description (legacy method)"
        else
            echo "❌ Failed to import $description"
            return 1
        fi
    fi
}

# Change to terraform directory
if [ ! -d "terraform/gcp" ]; then
    echo "❌ terraform/gcp directory not found. Run this script from the project root."
    exit 1
fi

cd terraform/gcp

echo ""
echo "🔧 Initializing Terraform..."
terraform init

echo ""
echo "📋 Checking existing resources for import..."

# Import DNS Zone (already has import block in dns.tf)
echo ""
echo "🌐 DNS Zone:"
if check_gcp_resource "gcloud dns managed-zones describe lornu-ai-zone --project=$PROJECT_ID"; then
    echo "✅ DNS zone 'lornu-ai-zone' exists in GCP"
    echo "ℹ️  DNS zone import is handled by import block in dns.tf"
else
    echo "❌ DNS zone 'lornu-ai-zone' not found in GCP"
fi

# Import Global Address
echo ""
echo "🌍 Global IP Address:"
if check_gcp_resource "gcloud compute addresses describe lornu-ai-ingress-ip --global --project=$PROJECT_ID"; then
    import_resource \
        "google_compute_global_address.ingress_ip" \
        "projects/$PROJECT_ID/global/addresses/lornu-ai-ingress-ip" \
        "Global IP Address (lornu-ai-ingress-ip)"
else
    echo "❌ Global address 'lornu-ai-ingress-ip' not found in GCP"
fi

# Import Storage Bucket
echo ""
echo "🪣 Storage Bucket:"
if check_gcp_resource "gcloud storage buckets describe gs://$PROJECT_ID-assets"; then
    import_resource \
        "google_storage_bucket.assets" \
        "$PROJECT_ID-assets" \
        "Assets Storage Bucket"
else
    echo "❌ Storage bucket '$PROJECT_ID-assets' not found in GCP"
fi

# Import Service Accounts
echo ""
echo "👤 Service Accounts:"
if check_gcp_resource "gcloud iam service-accounts describe lornu-backend@$PROJECT_ID.iam.gserviceaccount.com --project=$PROJECT_ID"; then
    import_resource \
        "google_service_account.backend" \
        "projects/$PROJECT_ID/serviceAccounts/lornu-backend@$PROJECT_ID.iam.gserviceaccount.com" \
        "Backend Service Account"
else
    echo "❌ Service account 'lornu-backend@$PROJECT_ID.iam.gserviceaccount.com' not found in GCP"
fi

if check_gcp_resource "gcloud iam service-accounts describe lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com --project=$PROJECT_ID"; then
    import_resource \
        "google_service_account.github_actions" \
        "projects/$PROJECT_ID/serviceAccounts/lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com" \
        "GitHub Actions Service Account"
else
    echo "❌ Service account 'lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com' not found in GCP"
fi

# Import GKE Cluster (if it exists)
echo ""
echo "🚢 GKE Cluster:"
if check_gcp_resource "gcloud container clusters describe $CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"; then
    import_resource \
        "google_container_cluster.primary" \
        "projects/$PROJECT_ID/locations/$REGION/clusters/$CLUSTER_NAME" \
        "GKE Cluster ($CLUSTER_NAME)"
    
    # Import node pool (assuming default node pool name)
    local node_pool_name="${CLUSTER_NAME}-nodes"
    if check_gcp_resource "gcloud container node-pools describe $node_pool_name --cluster=$CLUSTER_NAME --region=$REGION --project=$PROJECT_ID"; then
        import_resource \
            "google_container_node_pool.primary_nodes" \
            "projects/$PROJECT_ID/locations/$REGION/clusters/$CLUSTER_NAME/nodePools/$node_pool_name" \
            "GKE Node Pool ($node_pool_name)"
    else
        echo "❌ Node pool '$node_pool_name' not found in GKE cluster"
    fi
else
    echo "❌ GKE cluster '$CLUSTER_NAME' not found in GCP"
fi

# Import Artifact Registry Repository (if it exists)
echo ""
echo "📦 Artifact Registry:"
if check_gcp_resource "gcloud artifacts repositories describe lornu-ai --location=$REGION --project=$PROJECT_ID"; then
    import_resource \
        "google_artifact_registry_repository.docker_repo" \
        "projects/$PROJECT_ID/locations/$REGION/repositories/lornu-ai" \
        "Docker Repository (lornu-ai)"
else
    echo "❌ Artifact Registry repository 'lornu-ai' not found in GCP"
fi

# Import Workload Identity Pool
echo ""
echo "🆔 Workload Identity Pool:"
if check_gcp_resource "gcloud iam workload-identity-pools describe lornu-github-actions --location=global --project=$PROJECT_ID"; then
    import_resource \
        "google_iam_workload_identity_pool.github_pool" \
        "projects/$PROJECT_ID/locations/global/workloadIdentityPools/lornu-github-actions" \
        "Workload Identity Pool"
    
    # Import Workload Identity Provider
    if check_gcp_resource "gcloud iam workload-identity-pools providers describe lornu-github-actions-oidc --location=global --workload-identity-pool=lornu-github-actions --project=$PROJECT_ID"; then
        import_resource \
            "google_iam_workload_identity_pool_provider.github_provider" \
            "projects/$PROJECT_ID/locations/global/workloadIdentityPools/lornu-github-actions/providers/lornu-github-actions-oidc" \
            "Workload Identity Provider"
    fi
else
    echo "❌ Workload Identity Pool 'lornu-github-actions' not found in GCP"
fi

# Final Terraform plan
echo ""
echo "🎯 Running terraform plan to verify imports..."
if terraform plan -detailed-exitcode; then
    echo "✅ All resources are properly imported and configured!"
else
    echo "⚠️  Terraform plan shows differences. Review the output above."
    echo "    This might indicate:"
    echo "    - Resources need additional configuration"
    echo "    - Some resources weren't imported successfully"
    echo "    - Configuration drift from manual changes"
fi

echo ""
echo "📊 Summary:"
echo "=========="
terraform state list | sort

echo ""
echo "✅ Import process complete!"
echo ""
echo "💡 Next steps:"
echo "   1. Review terraform plan output above"
echo "   2. Fix any configuration drift"
echo "   3. Run terraform apply to ensure consistency"
echo "   4. Delete any unused resources with the cleanup script"