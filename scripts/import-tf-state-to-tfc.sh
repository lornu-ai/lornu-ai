#!/bin/bash
# Script to import Terraform state to Terraform Cloud
# Organization: lornu-ai
# Workspace: aws-kustomize

set -e

echo "🔧 Terraform State Import to Terraform Cloud"
echo "=============================================="
echo ""
echo "Organization: lornu-ai"
echo "Workspace: aws-kustomize"
echo ""

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "terraform.tfstate" ] && [ ! -f "terraform.tfstate.backup" ]; then
    echo "⚠️  No local state file found in current directory"
    echo "   Looking for: terraform.tfstate or terraform.tfstate.backup"
    echo ""
    echo "Please navigate to the directory containing your Terraform state"
    echo "Example: cd terraform/aws/production"
    exit 1
fi

# Check for Terraform Cloud token
if [ -z "$TF_TOKEN_app_terraform_io" ]; then
    echo "⚠️  TF_TOKEN_app_terraform_io not set"
    echo ""
    echo "Please set your Terraform Cloud API token:"
    echo "  export TF_TOKEN_app_terraform_io='your-token-here'"
    echo ""
    echo "Or run: terraform login"
    exit 1
fi

echo "✅ Terraform Cloud token found"
echo ""

# Backup current state
if [ -f "terraform.tfstate" ]; then
    BACKUP_FILE="terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)"
    echo "📦 Backing up current state..."
    cp terraform.tfstate "$BACKUP_FILE"
    echo "   Backup saved to: $BACKUP_FILE"
    echo ""
fi

# Check backend configuration
echo "🔍 Checking backend configuration..."
if grep -q "organization = \"lornu-ai\"" *.tf 2>/dev/null && grep -q "name = \"aws-kustomize\"" *.tf 2>/dev/null; then
    echo "✅ Backend configuration found for lornu-ai/aws-kustomize"
else
    echo "⚠️  Backend configuration may not be set correctly"
    echo "   Expected:"
    echo "     organization = \"lornu-ai\""
    echo "     workspaces { name = \"aws-kustomize\" }"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🚀 Starting state migration..."
echo ""

# Initialize and migrate state
echo "Step 1: Initializing Terraform..."
terraform init -migrate-state <<EOF
yes
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ State migration completed successfully!"
    echo ""
    echo "Step 2: Verifying state in Terraform Cloud..."
    terraform state list

    echo ""
    echo "✅ Import complete!"
    echo ""
    echo "Next steps:"
    echo "1. Verify state in Terraform Cloud UI:"
    echo "   https://app.terraform.io/app/lornu-ai/workspaces/aws-kustomize"
    echo ""
    echo "2. Run a plan to verify everything works:"
    echo "   terraform plan"
    echo ""
    echo "3. After verification, you can remove local state files:"
    echo "   rm terraform.tfstate terraform.tfstate.backup"
else
    echo ""
    echo "❌ Migration failed"
    echo "   Check the error messages above"
    echo "   Your state backup is saved at: $BACKUP_FILE"
    exit 1
fi
