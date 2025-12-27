#!/bin/bash
# Setup pre-commit hooks for Terraform automation

set -e

echo "🔧 Setting up pre-commit hooks for Terraform automation"
echo "======================================================"
echo ""

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit is not installed"
    echo ""
    echo "Install with:"
    echo "  brew install pre-commit"
    echo "  # or"
    echo "  pip install pre-commit"
    exit 1
fi

echo "✅ pre-commit is installed"
echo ""

# Install hooks
echo "Installing pre-commit hooks..."
pre-commit install

echo ""
echo "✅ Pre-commit hooks installed!"
echo ""
echo "To test:"
echo "  pre-commit run --all-files"
echo ""
echo "To run only Terraform hooks:"
echo "  pre-commit run terraform_fmt --all-files"
echo "  pre-commit run terraform_validate --all-files"
echo ""
