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

# Note: We use explicit error handling instead of 'set -e' to allow
# graceful handling of expected failures during resource checks.

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
    # Execute gcloud command directly with proper quoting to avoid command injection
    # All arguments are properly quoted and validated
    local resource_type="$1"
    local resource_name="$2" 
    local extra_args="$3"
    
    case "$resource_type" in
        "dns")
            gcloud dns managed-zones describe "$resource_name" --project="$PROJECT_ID" &>/dev/null
            ;;
        "address")
            gcloud compute addresses describe "$resource_name" --global --project="$PROJECT_ID" &>/dev/null
            ;;
        "bucket")
            gcloud storage buckets describe "gs://$resource_name" &>/dev/null
            ;;
        "service-account")
            gcloud iam service-accounts describe "$resource_name" --project="$PROJECT_ID" &>/dev/null
            ;;
        "gke-cluster")
            gcloud container clusters describe "$resource_name" --region="$REGION" --project="$PROJECT_ID" &>/dev/null
            ;;
        "gke-nodepool")
            local cluster_name="$extra_args"
            gcloud container node-pools describe "$resource_name" --cluster="$cluster_name" --region="$REGION" --project="$PROJECT_ID" &>/dev/null
            ;;
        "artifact-registry")
            gcloud artifacts repositories describe "$resource_name" --location="$REGION" --project="$PROJECT_ID" &>/dev/null
            ;;
        "workload-identity-pool")
            gcloud iam workload-identity-pools describe "$resource_name" --location=global --project="$PROJECT_ID" &>/dev/null
            ;;
        "workload-identity-provider")
            local pool_name="$extra_args"
            gcloud iam workload-identity-pools providers describe "$resource_name" --location=global --workload-identity-pool="$pool_name" --project="$PROJECT_ID" &>/dev/null
            ;;
        *)
            echo "❌ Unknown resource type: $resource_type"
            return 1
            ;;
    esac
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
        
        # Respect DRY_RUN mode to avoid unintended applies
        if [ "${DRY_RUN:-false}" = "true" ]; then
            echo "ℹ️ DRY_RUN=true — skipping terraform apply for $description."
            echo "   Review the plan output and generated configuration, then run 'terraform apply' manually if desired."
        else
            # Apply the import with interactive confirmation
            echo "❓ Apply the import for $description? (y/N)"
            read -r confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                if terraform apply; then
                    echo "✅ Successfully imported $description"
                    # Clean up temporary import file after successful import
                    rm -f "$import_file"
                else
                    echo "❌ Failed to apply import for $description"
                    return 1
                fi
            else
                echo "⏭️  Skipping import for $description"
            fi
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
if check_gcp_resource "dns" "lornu-ai-zone"; then
    echo "✅ DNS zone 'lornu-ai-zone' exists in GCP"
    echo "ℹ️  DNS zone import is handled by import block in dns.tf"
else
    echo "❌ DNS zone 'lornu-ai-zone' not found in GCP"
fi

# Import Global Address
echo ""
echo "🌍 Global IP Address:"
if check_gcp_resource "address" "lornu-ai-ingress-ip"; then
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
if check_gcp_resource "bucket" "$PROJECT_ID-assets"; then
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
if check_gcp_resource "service-account" "lornu-backend@$PROJECT_ID.iam.gserviceaccount.com"; then
    import_resource \
        "google_service_account.backend" \
        "projects/$PROJECT_ID/serviceAccounts/lornu-backend@$PROJECT_ID.iam.gserviceaccount.com" \
        "Backend Service Account"
else
    echo "❌ Service account 'lornu-backend@$PROJECT_ID.iam.gserviceaccount.com' not found in GCP"
fi

if check_gcp_resource "service-account" "lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com"; then
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
if check_gcp_resource "gke-cluster" "$CLUSTER_NAME"; then
    import_resource \
        "google_container_cluster.primary" \
        "projects/$PROJECT_ID/locations/$REGION/clusters/$CLUSTER_NAME" \
        "GKE Cluster ($CLUSTER_NAME)"
    
    # Import node pool (assuming default node pool name)
    local node_pool_name="${CLUSTER_NAME}-nodes"
    if check_gcp_resource "gke-nodepool" "$node_pool_name" "$CLUSTER_NAME"; then
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
if check_gcp_resource "artifact-registry" "lornu-ai"; then
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
if check_gcp_resource "workload-identity-pool" "lornu-github-actions"; then
    import_resource \
        "google_iam_workload_identity_pool.github_pool" \
        "projects/$PROJECT_ID/locations/global/workloadIdentityPools/lornu-github-actions" \
        "Workload Identity Pool"
    
    # Import Workload Identity Provider
    if check_gcp_resource "workload-identity-provider" "lornu-github-actions-oidc" "lornu-github-actions"; then
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