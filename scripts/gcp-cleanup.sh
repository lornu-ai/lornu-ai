#!/bin/bash

# GCP Infrastructure Cleanup Script
# Addresses GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import
# https://github.com/lornu-ai/lornu-ai/issues/444
#
# This script implements safe cleanup of legacy resources not managed by Terraform
# Following the principle: Import valuable resources, delete unused ones
#
# GitHub CLI Integration:
#   gh issue comment 444 --body "Starting GCP cleanup process"
#   ./scripts/gcp-cleanup.sh
#   gh issue comment 444 --body "Cleanup completed successfully"

set -e

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
DRY_RUN="${DRY_RUN:-true}"  # Set to false to actually delete resources

echo "🧹 GCP Infrastructure Cleanup for project: $PROJECT_ID"
echo "Dry run mode: $DRY_RUN"
echo "=================================================================="

# Function to safely delete with confirmation
safe_delete() {
    local resource_type="$1"
    local resource_name="$2"
    local delete_command="$3"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "🔍 [DRY RUN] Would delete $resource_type: $resource_name"
        echo "   Command: $delete_command"
    else
        echo "❓ Delete $resource_type: $resource_name? (y/N)"
        read -r confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            echo "🗑️  Deleting $resource_type: $resource_name"
            eval "$delete_command"
        else
            echo "⏭️  Skipping $resource_type: $resource_name"
        fi
    fi
}

# Function to clean up old VM instances (not part of GKE)
cleanup_orphaned_vms() {
    echo ""
    echo "🖥️  Checking for orphaned VM instances..."
    
    # Get all VMs that are not part of a managed instance group (GKE nodes are in MIGs)
    local orphaned_vms
    orphaned_vms=$(gcloud compute instances list --filter="NOT tags.items:gke-*" --format="value(name,zone)" 2>/dev/null || true)
    
    if [ -n "$orphaned_vms" ]; then
        while IFS=$'\t' read -r name zone; do
            if [ -n "$name" ] && [ -n "$zone" ]; then
                safe_delete "VM Instance" "$name" "gcloud compute instances delete $name --zone=$zone --quiet"
            fi
        done <<< "$orphaned_vms"
    else
        echo "✅ No orphaned VM instances found"
    fi
}

# Function to clean up unused storage buckets
cleanup_unused_buckets() {
    echo ""
    echo "🪣 Checking for unused storage buckets..."
    
    # List buckets and exclude the ones managed by Terraform
    local managed_buckets=("$PROJECT_ID-assets")
    local all_buckets
    all_buckets=$(gcloud storage buckets list --format="value(name)" 2>/dev/null || true)
    
    if [ -n "$all_buckets" ]; then
        while read -r bucket; do
            if [ -n "$bucket" ]; then
                # Check if bucket is managed by Terraform
                local is_managed=false
                for managed in "${managed_buckets[@]}"; do
                    if [ "$bucket" = "$managed" ]; then
                        is_managed=true
                        break
                    fi
                done
                
                if [ "$is_managed" = "false" ]; then
                    # Check if bucket is empty
                    local object_count
                    object_count=$(gcloud storage ls "gs://$bucket/**" 2>/dev/null | wc -l || echo "0")
                    
                    if [ "$object_count" -eq 0 ]; then
                        safe_delete "Empty Storage Bucket" "$bucket" "gcloud storage buckets delete gs://$bucket --quiet"
                    else
                        echo "⚠️  Bucket $bucket has $object_count objects - skipping (review manually)"
                    fi
                else
                    echo "✅ Bucket $bucket is managed by Terraform - keeping"
                fi
            fi
        done <<< "$all_buckets"
    else
        echo "✅ No storage buckets found"
    fi
}

# Function to clean up old service accounts
cleanup_old_service_accounts() {
    echo ""
    echo "👤 Checking for old service accounts..."
    
    # List service accounts and exclude the ones managed by Terraform
    local managed_accounts=(
        "lornu-backend@$PROJECT_ID.iam.gserviceaccount.com"
        "lornu-github-actions@$PROJECT_ID.iam.gserviceaccount.com"
    )
    
    local all_accounts
    all_accounts=$(gcloud iam service-accounts list --filter="email:*@$PROJECT_ID.iam.gserviceaccount.com" --format="value(email)" 2>/dev/null || true)
    
    if [ -n "$all_accounts" ]; then
        while read -r account; do
            if [ -n "$account" ]; then
                # Check if account is managed by Terraform
                local is_managed=false
                for managed in "${managed_accounts[@]}"; do
                    if [ "$account" = "$managed" ]; then
                        is_managed=true
                        break
                    fi
                done
                
                if [ "$is_managed" = "false" ]; then
                    # Check when the account was created (if very recent, might be in use)
                    local created_time
                    created_time=$(gcloud iam service-accounts describe "$account" --format="value(metadata.creationTime)" 2>/dev/null || echo "unknown")
                    
                    safe_delete "Service Account" "$account (created: $created_time)" "gcloud iam service-accounts delete $account --quiet"
                else
                    echo "✅ Service Account $account is managed by Terraform - keeping"
                fi
            fi
        done <<< "$all_accounts"
    else
        echo "✅ No custom service accounts found"
    fi
}

# Function to clean up orphaned load balancer components
cleanup_orphaned_lb_components() {
    echo ""
    echo "⚖️  Checking for orphaned load balancer components..."
    
    # Clean up backend services not associated with any URL map
    local backend_services
    backend_services=$(gcloud compute backend-services list --format="value(name)" 2>/dev/null || true)
    
    if [ -n "$backend_services" ]; then
        while read -r backend; do
            if [ -n "$backend" ]; then
                # Check if backend service is referenced by any URL map
                local referenced
                referenced=$(gcloud compute url-maps list --format="value(defaultService,pathMatchers[].defaultService)" 2>/dev/null | grep -c "$backend" || echo "0")
                
                if [ "$referenced" -eq 0 ]; then
                    safe_delete "Orphaned Backend Service" "$backend" "gcloud compute backend-services delete $backend --global --quiet"
                fi
            fi
        done <<< "$backend_services"
    fi
}

# Function to clean up unused secrets
cleanup_unused_secrets() {
    echo ""
    echo "🔐 Checking for unused secrets..."
    
    local secrets
    secrets=$(gcloud secrets list --format="value(name)" 2>/dev/null || true)
    
    if [ -n "$secrets" ]; then
        echo "📋 Found secrets (review manually):"
        while read -r secret; do
            if [ -n "$secret" ]; then
                local created
                created=$(gcloud secrets describe "$secret" --format="value(createTime)" 2>/dev/null || echo "unknown")
                echo "   - $secret (created: $created)"
            fi
        done <<< "$secrets"
        echo ""
        echo "💡 To delete a secret: gcloud secrets delete SECRET_NAME"
    else
        echo "✅ No secrets found"
    fi
}

# Function to show terraform state check
show_terraform_state_check() {
    echo ""
    echo "🔧 TERRAFORM STATE VERIFICATION:"
    echo "================================"
    echo ""
    echo "After cleanup, verify your Terraform state:"
    echo ""
    echo "cd terraform/gcp"
    echo "terraform plan"
    echo ""
    echo "If you see resources that Terraform wants to create but already exist,"
    echo "you may need to import them:"
    echo ""
    echo "# Example import commands:"
    echo "# terraform import google_dns_managed_zone.public_zone projects/$PROJECT_ID/managedZones/lornu-ai-zone"
    echo "# terraform import google_compute_global_address.ingress_ip projects/$PROJECT_ID/global/addresses/lornu-ai-ingress-ip"
    echo "# terraform import google_storage_bucket.assets $PROJECT_ID-assets"
}

# Main cleanup function
main() {
    echo "Starting GCP cleanup assessment..."
    
    # Check if gcloud is available and configured
    if ! command -v gcloud &> /dev/null; then
        echo "❌ gcloud CLI not found. Please install the Google Cloud SDK."
        exit 1
    fi
    
    gcloud config set project "$PROJECT_ID" 2>/dev/null || {
        echo "❌ Failed to set project $PROJECT_ID. Please check if it exists and you have access."
        exit 1
    }
    
    # Run cleanup functions
    cleanup_orphaned_vms
    cleanup_unused_buckets  
    cleanup_old_service_accounts
    cleanup_orphaned_lb_components
    cleanup_unused_secrets
    
    show_terraform_state_check
    
    echo ""
    echo "✅ Cleanup assessment complete!"
    echo ""
    if [ "$DRY_RUN" = "true" ]; then
        echo "💡 To actually delete resources, run with: DRY_RUN=false $0"
    fi
    echo ""
    echo "⚠️  Always review changes carefully and ensure you have backups!"
}

main "$@"