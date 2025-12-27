#!/bin/bash
# Verify AWS OIDC configuration for GitHub Actions
# This script checks if OIDC is properly configured for drift-sentinel workflow

set -e

echo "🔍 Checking AWS OIDC Configuration for GitHub Actions"
echo "======================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq is not installed (needed for JSON parsing)${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Get AWS region from environment or default
AWS_REGION=${AWS_REGION:-us-east-1}
echo "📍 AWS Region: $AWS_REGION"
echo ""

# 1. Check if OIDC Provider exists
echo "1️⃣  Checking OIDC Provider..."
OIDC_PROVIDER=$(aws iam list-open-id-connect-providers --query 'OpenIDConnectProviderList[?contains(Arn, `token.actions.githubusercontent.com`)].Arn' --output text 2>/dev/null || echo "")

if [ -z "$OIDC_PROVIDER" ]; then
    echo -e "${RED}❌ OIDC Provider not found${NC}"
    echo "   Expected: OIDC provider for https://token.actions.githubusercontent.com"
    echo "   Action: Create OIDC provider manually or via Terraform"
    exit 1
else
    echo -e "${GREEN}✅ OIDC Provider found:${NC}"
    echo "   $OIDC_PROVIDER"
fi
echo ""

# 2. Check GitHub Actions roles
echo "2️⃣  Checking GitHub Actions IAM Roles..."

# Check staging role
STAGING_ROLE="github-actions"
STAGING_ROLE_ARN=$(aws iam get-role --role-name "$STAGING_ROLE" --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [ -z "$STAGING_ROLE_ARN" ]; then
    echo -e "${YELLOW}⚠️  Staging role '$STAGING_ROLE' not found${NC}"
else
    echo -e "${GREEN}✅ Staging role found:${NC}"
    echo "   Role: $STAGING_ROLE"
    echo "   ARN: $STAGING_ROLE_ARN"

    # Check trust policy
    echo "   Checking trust policy..."
    TRUST_POLICY=$(aws iam get-role --role-name "$STAGING_ROLE" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)

    if echo "$TRUST_POLICY" | jq -e '.Statement[] | select(.Principal.Federated != null)' > /dev/null; then
        echo -e "   ${GREEN}✅ Trust policy includes OIDC federation${NC}"

        # Check if it allows the correct repo
        if echo "$TRUST_POLICY" | jq -e '.Statement[].Condition.StringLike."token.actions.githubusercontent.com:sub"[] | select(contains("lornu-ai/lornu-ai"))' > /dev/null; then
            echo -e "   ${GREEN}✅ Trust policy allows lornu-ai/lornu-ai repository${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Trust policy may not allow lornu-ai/lornu-ai repository${NC}"
        fi
    else
        echo -e "   ${RED}❌ Trust policy does not include OIDC federation${NC}"
    fi
fi
echo ""

# Check production role
PROD_ROLE="github-actions-prod"
PROD_ROLE_ARN=$(aws iam get-role --role-name "$PROD_ROLE" --query 'Role.Arn' --output text 2>/dev/null || echo "")

if [ -z "$PROD_ROLE_ARN" ]; then
    echo -e "${YELLOW}⚠️  Production role '$PROD_ROLE' not found${NC}"
else
    echo -e "${GREEN}✅ Production role found:${NC}"
    echo "   Role: $PROD_ROLE"
    echo "   ARN: $PROD_ROLE_ARN"

    # Check trust policy
    echo "   Checking trust policy..."
    TRUST_POLICY=$(aws iam get-role --role-name "$PROD_ROLE" --query 'Role.AssumeRolePolicyDocument' --output json 2>/dev/null)

    if echo "$TRUST_POLICY" | jq -e '.Statement[] | select(.Principal.Federated != null)' > /dev/null; then
        echo -e "   ${GREEN}✅ Trust policy includes OIDC federation${NC}"

        # Check if it allows the correct repo
        if echo "$TRUST_POLICY" | jq -e '.Statement[].Condition.StringLike."token.actions.githubusercontent.com:sub"[] | select(contains("lornu-ai/lornu-ai"))' > /dev/null; then
            echo -e "   ${GREEN}✅ Trust policy allows lornu-ai/lornu-ai repository${NC}"
        else
            echo -e "   ${YELLOW}⚠️  Trust policy may not allow lornu-ai/lornu-ai repository${NC}"
        fi
    else
        echo -e "   ${RED}❌ Trust policy does not include OIDC federation${NC}"
    fi
fi
echo ""

# 3. Check GitHub Secrets
echo "3️⃣  Checking GitHub Secrets (requires gh CLI)..."
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not installed - skipping secret check${NC}"
    echo "   Install with: brew install gh"
else
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        echo -e "${YELLOW}⚠️  Not authenticated with GitHub CLI${NC}"
        echo "   Run: gh auth login"
    else
        REPO="lornu-ai/lornu-ai"
        echo "   Checking secrets for $REPO..."

        # Check for AWS_ACTIONS_ROLE_ARN
        if gh secret list --repo "$REPO" | grep -q "AWS_ACTIONS_ROLE_ARN"; then
            echo -e "   ${GREEN}✅ AWS_ACTIONS_ROLE_ARN secret exists${NC}"
        else
            echo -e "   ${RED}❌ AWS_ACTIONS_ROLE_ARN secret not found${NC}"
            echo "      This is required for drift-sentinel workflow"
        fi

        # Check for AWS_TF_API_TOKEN
        if gh secret list --repo "$REPO" | grep -q "AWS_TF_API_TOKEN"; then
            echo -e "   ${GREEN}✅ AWS_TF_API_TOKEN secret exists${NC}"
        else
            echo -e "   ${YELLOW}⚠️  AWS_TF_API_TOKEN secret not found${NC}"
            echo "      This is required for Terraform Cloud authentication"
        fi
    fi
fi
echo ""

# 4. Verify drift-sentinel workflow references
echo "4️⃣  Checking drift-sentinel workflow configuration..."
if [ -f ".github/workflows/drift-sentinel.yml" ]; then
    echo -e "${GREEN}✅ drift-sentinel.yml workflow exists${NC}"

    # Check if it references AWS_ACTIONS_ROLE_ARN
    if grep -q "AWS_ACTIONS_ROLE_ARN" .github/workflows/drift-sentinel.yml; then
        echo -e "   ${GREEN}✅ Workflow references AWS_ACTIONS_ROLE_ARN${NC}"
    else
        echo -e "   ${RED}❌ Workflow does not reference AWS_ACTIONS_ROLE_ARN${NC}"
    fi

    # Check if it uses OIDC
    if grep -q "configure-aws-credentials" .github/workflows/drift-sentinel.yml; then
        echo -e "   ${GREEN}✅ Workflow uses AWS credentials action (OIDC)${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Workflow may not use OIDC authentication${NC}"
    fi
else
    echo -e "${RED}❌ drift-sentinel.yml workflow not found${NC}"
fi
echo ""

# 5. Summary
echo "======================================================"
echo "📋 Summary"
echo "======================================================"

if [ -n "$OIDC_PROVIDER" ] && ([ -n "$STAGING_ROLE_ARN" ] || [ -n "$PROD_ROLE_ARN" ]); then
    echo -e "${GREEN}✅ OIDC configuration appears to be set up correctly${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Verify GitHub secrets are configured:"
    echo "   - AWS_ACTIONS_ROLE_ARN (should match one of the role ARNs above)"
    echo "   - AWS_TF_API_TOKEN (for Terraform Cloud)"
    echo ""
    echo "2. Test the drift-sentinel workflow:"
    echo "   gh workflow run drift-sentinel.yml -f workspace=all -f remediation=false"
    echo ""
    echo "3. Check workflow logs for authentication errors"
else
    echo -e "${YELLOW}⚠️  Some OIDC components may be missing${NC}"
    echo ""
    echo "To fix:"
    echo "1. Ensure OIDC provider exists in AWS"
    echo "2. Apply Terraform configuration:"
    echo "   cd terraform/aws/staging && terraform apply"
    echo "   cd terraform/aws/production && terraform apply"
    echo "3. Update GitHub secrets with the role ARNs"
fi
