#!/bin/bash

# GCP Infrastructure Discovery and Assessment Script
# Addresses GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import
# https://github.com/lornu-ai/lornu-ai/issues/444
#
# This script implements Phase 1 requirements: Inventory & Prioritization
# - Discovers existing GCP resources not managed by Terraform
# - Prioritizes mission-critical resources (networking, IAM) first
# - Generates actionable import recommendations
#
# Usage with GitHub CLI integration:
#   gh issue view 444  # View the original issue
#   ./scripts/gcp-cleanup-assessment.sh
#   gh pr create --title "feat: implement GCP infrastructure discovery" --body "Closes #444"

# Note: We intentionally do not use 'set -e' globally because many discovery
# gcloud commands are expected to fail when resources do not exist.

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
echo "🔍 Assessing GCP infrastructure for project: $PROJECT_ID"
echo "=================================================================="

# Function to check if gcloud is configured
check_gcloud() {
    if ! command -v gcloud &> /dev/null; then
        echo "❌ gcloud CLI not found. Please install the Google Cloud SDK."
        exit 1
    fi
    
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        echo "❌ No active gcloud authentication found. Please run: gcloud auth login"
        exit 1
    fi
    
    gcloud config set project "$PROJECT_ID" 2>/dev/null || {
        echo "❌ Failed to set project $PROJECT_ID. Please check if it exists and you have access."
        exit 1
    }
}

# Function to list resources with import suggestions
list_resources() {
    echo "📋 Current GCP Resources Assessment:"
    echo "===================================="
    
    # Compute Engine Resources
    echo ""
    echo "🖥️  COMPUTE ENGINE:"
    echo "   Global Addresses (managed in Terraform):"
    gcloud compute addresses list --global --format="table(name,address,status)" 2>/dev/null || echo "   No global addresses found"
    
    echo "   Regional Addresses:"
    gcloud compute addresses list --filter="region:*" --format="table(name,address,status,region)" 2>/dev/null || echo "   No regional addresses found"
    
    echo "   VM Instances (should be in GKE):"
    gcloud compute instances list --format="table(name,zone,status,machineType)" 2>/dev/null || echo "   No VM instances found"
    
    # GKE Clusters
    echo ""
    echo "🚢 KUBERNETES ENGINE:"
    gcloud container clusters list --format="table(name,location,status,currentMasterVersion)" 2>/dev/null || echo "   No GKE clusters found"
    
    # DNS
    echo ""
    echo "🌐 CLOUD DNS:"
    echo "   Managed Zones (some managed in Terraform):"
    gcloud dns managed-zones list --format="table(name,dnsName,visibility)" 2>/dev/null || echo "   No DNS zones found"
    
    # Storage
    echo ""
    echo "🪣 CLOUD STORAGE:"
    echo "   Buckets (some managed in Terraform):"
    gcloud storage buckets list --format="table(name,location,storageClass)" 2>/dev/null || echo "   No storage buckets found"
    
    # Firestore
    echo ""
    echo "🗄️  FIRESTORE:"
    echo "   Databases:"
    gcloud firestore databases list --format="table(name,type,locationId)" 2>/dev/null || echo "   No Firestore databases found"
    
    # IAM Service Accounts
    echo ""
    echo "👤 IAM SERVICE ACCOUNTS:"
    echo "   Custom Service Accounts (some managed in Terraform):"
    gcloud iam service-accounts list --filter="email:*@$PROJECT_ID.iam.gserviceaccount.com" --format="table(email,displayName)" 2>/dev/null || echo "   No custom service accounts found"
    
    # Artifact Registry
    echo ""
    echo "📦 ARTIFACT REGISTRY:"
    gcloud artifacts repositories list --format="table(name,format,location)" 2>/dev/null || echo "   No repositories found"
    
    # Load Balancers
    echo ""
    echo "⚖️  LOAD BALANCERS:"
    echo "   URL Maps:"
    gcloud compute url-maps list --format="table(name,defaultService)" 2>/dev/null || echo "   No URL maps found"
    
    echo "   Backend Services:"
    gcloud compute backend-services list --format="table(name,loadBalancingScheme,protocol)" 2>/dev/null || echo "   No backend services found"
    
    echo "   Target Proxies:"
    gcloud compute target-https-proxies list --format="table(name,urlMap)" 2>/dev/null || echo "   No HTTPS proxies found"
    gcloud compute target-http-proxies list --format="table(name,urlMap)" 2>/dev/null || echo "   No HTTP proxies found"
    
    echo "   Forwarding Rules:"
    gcloud compute forwarding-rules list --format="table(name,IPAddress,target)" 2>/dev/null || echo "   No forwarding rules found"
    
    # Secrets Manager
    echo ""
    echo "🔐 SECRET MANAGER:"
    gcloud secrets list --format="table(name,created)" 2>/dev/null || echo "   No secrets found"
    
    # Workload Identity
    echo ""
    echo "🆔 WORKLOAD IDENTITY:"
    echo "   Workload Identity Pools:"
    gcloud iam workload-identity-pools list --location=global --format="table(name,displayName)" 2>/dev/null || echo "   No workload identity pools found"
}

# Function to generate cleanup recommendations
generate_recommendations() {
    echo ""
    echo "📝 CLEANUP RECOMMENDATIONS:"
    echo "=========================="
    echo ""
    echo "🟢 RESOURCES MANAGED IN TERRAFORM (keep these):"
    echo "   - DNS Zone: lornu-ai-zone (imported in dns.tf)"
    echo "   - Global Address: lornu-ai-ingress-ip"
    echo "   - Storage Bucket: $PROJECT_ID-assets"
    echo "   - Service Account: lornu-backend@$PROJECT_ID.iam.gserviceaccount.com"
    echo "   - Service Account: lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com"
    echo "   - Workload Identity Pool: lornu-github-actions"
    echo "   - Firestore Database: (default)"
    echo ""
    echo "🔴 RESOURCES TO REVIEW FOR DELETION:"
    echo "   - Any GKE clusters not matching 'lornu-ai-gke'"
    echo "   - VM instances not part of GKE node pools"
    echo "   - Unused storage buckets"
    echo "   - Old service accounts not in Terraform"
    echo "   - Orphaned load balancer components"
    echo "   - Unused secrets"
    echo ""
    echo "🟡 RESOURCES THAT MAY NEED TERRAFORM IMPORT:"
    echo "   - Artifact Registry repositories"
    echo "   - GKE cluster (if it exists and should be managed)"
    echo "   - Additional DNS records"
    echo "   - SSL certificates"
    echo ""
}

# Function to generate import commands
generate_import_commands() {
    echo ""
    echo "📋 TERRAFORM IMPORT COMMANDS (if needed):"
    echo "========================================="
    echo ""
    echo "# Import existing GKE cluster (if it exists):"
    echo "# terraform import google_container_cluster.primary projects/$PROJECT_ID/locations/us-central1/clusters/lornu-ai-gke"
    echo ""
    echo "# Import existing Artifact Registry repository (if it exists):"
    echo "# terraform import google_artifact_registry_repository.docker_repo projects/$PROJECT_ID/locations/us-central1/repositories/lornu-ai"
    echo ""
    echo "# The DNS zone is already imported in dns.tf with the import block"
    echo ""
}

# Function to generate deletion commands
generate_deletion_commands() {
    echo ""
    echo "🗑️  SAFE DELETION COMMANDS (review carefully before running):"
    echo "============================================================"
    echo ""
    echo "# Delete unused VM instances (check if they're GKE nodes first!):"
    echo "# gcloud compute instances delete INSTANCE_NAME --zone=ZONE"
    echo ""
    echo "# Delete unused storage buckets:"
    echo "# gcloud storage rm -r gs://BUCKET_NAME"
    echo ""
    echo "# Delete unused service accounts:"
    echo "# gcloud iam service-accounts delete EMAIL"
    echo ""
    echo "# Delete unused secrets:"
    echo "# gcloud secrets delete SECRET_NAME"
    echo ""
    echo "⚠️  WARNING: Always verify resources are not in use before deletion!"
    echo "⚠️  Consider creating backups for critical data!"
}

# Main execution
main() {
    check_gcloud
    list_resources
    generate_recommendations
    generate_import_commands
    generate_deletion_commands
    
    echo ""
    echo "✅ Assessment complete!"
    echo ""
    echo "💡 Next steps:"
    echo "   1. Review the resources listed above"
    echo "   2. Import valuable resources into Terraform"
    echo "   3. Safely delete unused resources"
    echo "   4. Run 'terraform plan' to verify state"
}

main "$@"