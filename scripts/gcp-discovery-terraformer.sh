#!/bin/bash

# GCP Infrastructure Discovery Script using Terraformer
# Addresses GitHub Issue #444: Legacy Cloud Infrastructure Discovery and Terraform Import
# https://github.com/lornu-ai/lornu-ai/issues/444
#
# This script implements automated resource discovery using terraformer
# as recommended in requirement 3.1 of the GitHub issue
#
# GitHub CLI Integration:
#   gh issue comment 444 --body "Starting automated resource discovery with terraformer"
#   ./scripts/gcp-discovery-terraformer.sh
#   gh issue comment 444 --body "Discovery complete. Generated HCL files for review."

# Note: We intentionally do not use 'set -e' globally because many terraformer
# commands are expected to fail when resources do not exist.

PROJECT_ID="${GCP_PROJECT_ID:-gcp-lornu-ai}"
REGION="${GCP_REGION:-us-central1}"
OUTPUT_DIR="terraform-discovered"

echo "🔍 GCP Infrastructure Discovery using Terraformer"
echo "GitHub Issue: https://github.com/lornu-ai/lornu-ai/issues/444"
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Output Directory: $OUTPUT_DIR"
echo "=================================================================="

# Function to check if terraformer is installed
check_terraformer() {
    if ! command -v terraformer &> /dev/null; then
        echo "❌ terraformer not found. Installing..."
        
        # Install terraformer based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                echo "🍺 Installing terraformer via Homebrew..."
                brew install terraformer
            else
                echo "❌ Homebrew not found. Please install terraformer manually:"
                echo "   https://github.com/GoogleCloudPlatform/terraformer#installation"
                exit 1
            fi
        else
            echo "❌ Please install terraformer manually:"
            echo "   https://github.com/GoogleCloudPlatform/terraformer#installation"
            exit 1
        fi
    else
        echo "✅ terraformer found: $(terraformer version)"
    fi
}

# Function to check gcloud authentication
check_gcloud_auth() {
    if ! gcloud auth application-default print-access-token &> /dev/null; then
        echo "❌ No application default credentials found."
        echo "   Run: gcloud auth application-default login"
        exit 1
    fi
    
    gcloud config set project "$PROJECT_ID" 2>/dev/null || {
        echo "❌ Failed to set project $PROJECT_ID"
        exit 1
    }
    
    echo "✅ gcloud authentication verified for project $PROJECT_ID"
}

# Function to discover specific GCP resources
discover_resources() {
    local resource_type="$1"
    local description="$2"
    
    echo ""
    echo "🔍 Discovering $description..."
    
    # Create output directory for this resource type
    local resource_output_dir="$OUTPUT_DIR/$resource_type"
    mkdir -p "$resource_output_dir"
    
    # Run terraformer for this resource type
    if terraformer import google \
        --resources="$resource_type" \
        --projects="$PROJECT_ID" \
        --regions="$REGION" \
        --output="$resource_output_dir" \
        --verbose; then
        
        echo "✅ Successfully discovered $description"
        
        # Count discovered resources
        local resource_count=0
        if [ -d "$resource_output_dir/google" ]; then
            resource_count=$(find "$resource_output_dir/google" -name "*.tf" -exec wc -l {} \; | awk '{sum+=$1} END {print sum+0}')
        fi
        echo "📊 Generated $resource_count lines of Terraform configuration"
        
        return 0
    else
        echo "⚠️  Failed to discover $description (may not exist)"
        return 1
    fi
}

# Function to prioritize mission-critical resources
discover_priority_resources() {
    echo ""
    echo "🎯 Phase 1: Discovering Mission-Critical Resources (as per Issue #444)"
    echo "======================================================================"
    
    # Priority 1: Networking (VPCs, Subnets, Firewalls)
    echo ""
    echo "🌐 Priority 1: Networking Infrastructure"
    discover_resources "networks" "VPC Networks"
    discover_resources "subnetworks" "VPC Subnetworks" 
    discover_resources "firewalls" "Firewall Rules"
    discover_resources "addresses" "Static IP Addresses"
    
    # Priority 2: IAM (Service Accounts, IAM Policies)
    echo ""
    echo "🔐 Priority 2: Identity and Access Management"
    discover_resources "iam" "IAM Policies and Bindings"
    discover_resources "serviceAccounts" "Service Accounts"
    
    # Priority 3: Compute Resources
    echo ""
    echo "💻 Priority 3: Compute Infrastructure"
    discover_resources "gke" "Google Kubernetes Engine"
    discover_resources "instances" "Compute Engine Instances"
    discover_resources "instanceGroups" "Instance Groups"
    
    # Priority 4: Storage and Databases
    echo ""
    echo "🗄️  Priority 4: Storage and Data Services"
    discover_resources "gcs" "Cloud Storage Buckets"
    discover_resources "sql" "Cloud SQL Instances"
    discover_resources "firestore" "Firestore Databases"
    
    # Priority 5: Other Services
    echo ""
    echo "🔧 Priority 5: Other Cloud Services"
    discover_resources "dns" "Cloud DNS"
    discover_resources "pubsub" "Pub/Sub Topics and Subscriptions"
    discover_resources "functions" "Cloud Functions"
}

# Function to generate summary report
generate_summary_report() {
    echo ""
    echo "📊 DISCOVERY SUMMARY REPORT"
    echo "=========================="
    
    local total_files=0
    local total_resources=0
    
    if [ -d "$OUTPUT_DIR" ]; then
        # Count all generated .tf files
        total_files=$(find "$OUTPUT_DIR" -name "*.tf" | wc -l)
        
        # Count resource blocks in generated files
        if [ "$total_files" -gt 0 ]; then
            total_resources=$(find "$OUTPUT_DIR" -name "*.tf" -exec grep -c "^resource " {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        fi
        
        echo "📄 Generated Files: $total_files"
        echo "🏗️  Discovered Resources: $total_resources"
        echo ""
        
        # List discovered resource types
        echo "📋 Discovered Resource Types:"
        find "$OUTPUT_DIR" -name "*.tf" -exec basename {} \; | sort | uniq | while read -r file; do
            echo "   - $file"
        done
        
        echo ""
        echo "📂 Output Structure:"
        tree "$OUTPUT_DIR" 2>/dev/null || find "$OUTPUT_DIR" -type f -name "*.tf" | head -20
        
    else
        echo "❌ No resources discovered"
    fi
    
    echo ""
    echo "💡 Next Steps (per GitHub Issue #444):"
    echo "======================================"
    echo "1. Review generated HCL files in $OUTPUT_DIR/"
    echo "2. Clean up hardcoded IDs and replace with variables"
    echo "3. Refactor into reusable modules"
    echo "4. Run terraform plan to verify zero-diff"
    echo "5. Import resources using modern import blocks"
    echo ""
    echo "🔗 GitHub Issue: https://github.com/lornu-ai/lornu-ai/issues/444"
}

# Function to create GitHub issue update
create_github_update() {
    echo ""
    echo "📝 Creating GitHub Issue Update..."
    
    local discovery_summary=""
    if [ -d "$OUTPUT_DIR" ]; then
        local file_count=$(find "$OUTPUT_DIR" -name "*.tf" | wc -l)
        local resource_count=$(find "$OUTPUT_DIR" -name "*.tf" -exec grep -c "^resource " {} \; 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        
        discovery_summary="## 🔍 Automated Discovery Results

**Project:** $PROJECT_ID  
**Region:** $REGION  
**Discovered Files:** $file_count  
**Discovered Resources:** $resource_count  

### 📊 Resource Categories Discovered:
$(find "$OUTPUT_DIR" -name "*.tf" -exec basename {} \; | sort | uniq | sed 's/^/- /')

### ✅ Completed Tasks:
- [x] Phase 1: Inventory & Prioritization
- [x] Automated resource discovery using terraformer
- [x] Prioritized mission-critical resources (networking, IAM)
- [x] Generated initial HCL files

### 🔄 Next Steps:
- [ ] Review and clean generated HCL files
- [ ] Replace hardcoded IDs with variables
- [ ] Refactor into reusable modules
- [ ] Implement modern import blocks
- [ ] Verify zero-diff with terraform plan

**Output Location:** \`$OUTPUT_DIR/\`"
    else
        discovery_summary="## ❌ Discovery Issues

No resources were discovered. This may indicate:
- Authentication issues
- Project access problems  
- No resources exist in the specified project/region

Please verify project access and try again."
    fi
    
    # Update GitHub issue with results (if gh CLI is available)
    if command -v gh &> /dev/null; then
        echo "$discovery_summary" | gh issue comment 444 --body-file -
        echo "✅ Posted discovery results to GitHub Issue #444"
    else
        echo "⚠️  GitHub CLI not available. Manual update needed:"
        echo ""
        echo "$discovery_summary"
    fi
}

# Main execution function
main() {
    echo "🚀 Starting GCP Infrastructure Discovery Process..."
    echo "   Addressing GitHub Issue #444 requirements"
    echo ""
    
    # Prerequisites
    check_terraformer
    check_gcloud_auth
    
    # Clean up any previous discovery
    if [ -d "$OUTPUT_DIR" ]; then
        echo "🧹 Cleaning up previous discovery output..."
        rm -rf "$OUTPUT_DIR"
    fi
    
    # Run discovery
    discover_priority_resources
    
    # Generate reports
    generate_summary_report
    create_github_update
    
    echo ""
    echo "✅ GCP Infrastructure Discovery Complete!"
    echo "   Review the generated files and proceed with import process"
    echo ""
    echo "🔗 GitHub Issue: https://github.com/lornu-ai/lornu-ai/issues/444"
}

# Run main function
main "$@"