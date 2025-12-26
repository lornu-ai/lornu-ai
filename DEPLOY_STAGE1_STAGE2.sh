#!/bin/bash

# Deployment Script for PR #320: Staging Domain Aliases
# This script runs Terraform Stage 1 (ACM) then Stage 2 (CloudFront)
# Usage: ./DEPLOY_STAGE1_STAGE2.sh

set -e

echo "=========================================="
echo "Deploying PR #320: Staging Domain Aliases"
echo "=========================================="
echo ""

# Verify we're on the correct branch
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "fix/staging-domain-alias" ]; then
  echo "❌ ERROR: Not on fix/staging-domain-alias branch (currently on $BRANCH)"
  echo "Run: git checkout fix/staging-domain-alias"
  exit 1
fi

# Set environment variables from GitHub secrets
# These will be empty strings if not set - you'll need to export them manually
export PROD_DOMAIN="${PROD_DOMAIN:-lornu.ai}"
export PROD_API_DOMAIN="${PROD_API_DOMAIN:-api.lornu.ai}"
export STAGE_DOMAIN="${STAGE_DOMAIN:-s1.lornu.ai}"
export PROD_DB_USERNAME="${PROD_DB_USERNAME:-lornu_admin}"
export PROD_DB_PASSWORD="${PROD_DB_PASSWORD}"
export ROUTE53_ZONE_NAME="${ROUTE53_ZONE_NAME:-lornu.ai}"
export SECRETS_MANAGER_ARN_PATTERN="${SECRETS_MANAGER_ARN_PATTERN}"
export PROD_ACM_CERTIFICATE_ARN="${PROD_ACM_CERTIFICATE_ARN}"

# Validate required variables
if [ -z "$PROD_DB_PASSWORD" ]; then
  echo "❌ ERROR: PROD_DB_PASSWORD is required"
  echo "Export it: export PROD_DB_PASSWORD='<password>'"
  exit 1
fi

if [ -z "$SECRETS_MANAGER_ARN_PATTERN" ]; then
  echo "❌ ERROR: SECRETS_MANAGER_ARN_PATTERN is required"
  exit 1
fi

echo "✓ Using domain: $PROD_DOMAIN"
echo "✓ Using API domain: $PROD_API_DOMAIN"
echo "✓ Using staging domain: $STAGE_DOMAIN"
echo ""

cd terraform/aws/production

echo "=========================================="
echo "STAGE 1: Creating ACM Certificate"
echo "=========================================="
echo ""
echo "Initialize Terraform..."
terraform init

echo ""
echo "Planning Stage 1 (ACM + Route53 validation)..."
TF_VAR_extra_domain_names="[\"$STAGE_DOMAIN\"]" \
TF_VAR_docker_image="placeholder" \
TF_VAR_domain_name="$PROD_DOMAIN" \
TF_VAR_api_domain="$PROD_API_DOMAIN" \
TF_VAR_db_username="$PROD_DB_USERNAME" \
TF_VAR_db_password="$PROD_DB_PASSWORD" \
TF_VAR_route53_zone_name="$ROUTE53_ZONE_NAME" \
TF_VAR_create_route53_zone="true" \
TF_VAR_existing_acm_certificate_arn="$PROD_ACM_CERTIFICATE_ARN" \
TF_VAR_secrets_manager_arn_pattern="$SECRETS_MANAGER_ARN_PATTERN" \
TF_VAR_deploy_stage=1 \
terraform plan \
  -target=aws_acm_certificate.cloudfront \
  -target=aws_route53_record.cloudfront_cert_validation \
  -target=aws_acm_certificate_validation.cloudfront \
  -out=tfplan-stage1

echo ""
echo "STAGE 1 PLAN SUMMARY:"
terraform show -no-color tfplan-stage1 | tail -20

echo ""
read -p "Review the plan above. Continue with apply? (yes/no) " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "❌ Deployment cancelled"
  exit 1
fi

echo ""
echo "Applying Stage 1 (creating ACM cert + DNS validation records)..."
TF_VAR_extra_domain_names="[\"$STAGE_DOMAIN\"]" \
TF_VAR_docker_image="placeholder" \
TF_VAR_domain_name="$PROD_DOMAIN" \
TF_VAR_api_domain="$PROD_API_DOMAIN" \
TF_VAR_db_username="$PROD_DB_USERNAME" \
TF_VAR_db_password="$PROD_DB_PASSWORD" \
TF_VAR_route53_zone_name="$ROUTE53_ZONE_NAME" \
TF_VAR_create_route53_zone="true" \
TF_VAR_existing_acm_certificate_arn="$PROD_ACM_CERTIFICATE_ARN" \
TF_VAR_secrets_manager_arn_pattern="$SECRETS_MANAGER_ARN_PATTERN" \
TF_VAR_deploy_stage=1 \
terraform apply tfplan-stage1

echo ""
echo "=========================================="
echo "✓ STAGE 1 COMPLETE"
echo "=========================================="
echo ""
echo "⏳ Waiting for DNS validation (5-15 minutes)..."
echo "   Check: AWS Console → ACM → Certificate Status → ISSUED"
echo ""
read -p "Once certificate is ISSUED, press Enter to continue to Stage 2..."

echo ""
echo "=========================================="
echo "STAGE 2: Creating CloudFront Distribution"
echo "=========================================="
echo ""
echo "Planning Stage 2 (CloudFront + Route53 aliases)..."

TF_VAR_extra_domain_names="[\"$STAGE_DOMAIN\"]" \
TF_VAR_docker_image="placeholder" \
TF_VAR_domain_name="$PROD_DOMAIN" \
TF_VAR_api_domain="$PROD_API_DOMAIN" \
TF_VAR_db_username="$PROD_DB_USERNAME" \
TF_VAR_db_password="$PROD_DB_PASSWORD" \
TF_VAR_route53_zone_name="$ROUTE53_ZONE_NAME" \
TF_VAR_create_route53_zone="true" \
TF_VAR_existing_acm_certificate_arn="$PROD_ACM_CERTIFICATE_ARN" \
TF_VAR_secrets_manager_arn_pattern="$SECRETS_MANAGER_ARN_PATTERN" \
TF_VAR_deploy_stage=2 \
terraform plan \
  -out=tfplan-stage2

echo ""
echo "STAGE 2 PLAN SUMMARY:"
terraform show -no-color tfplan-stage2 | tail -30

echo ""
read -p "Review the plan above. Continue with apply? (yes/no) " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "❌ Deployment cancelled"
  exit 1
fi

echo ""
echo "Applying Stage 2 (creating CloudFront + Route53 alias records)..."
TF_VAR_extra_domain_names="[\"$STAGE_DOMAIN\"]" \
TF_VAR_docker_image="placeholder" \
TF_VAR_domain_name="$PROD_DOMAIN" \
TF_VAR_api_domain="$PROD_API_DOMAIN" \
TF_VAR_db_username="$PROD_DB_USERNAME" \
TF_VAR_db_password="$PROD_DB_PASSWORD" \
TF_VAR_route53_zone_name="$ROUTE53_ZONE_NAME" \
TF_VAR_create_route53_zone="true" \
TF_VAR_existing_acm_certificate_arn="$PROD_ACM_CERTIFICATE_ARN" \
TF_VAR_secrets_manager_arn_pattern="$SECRETS_MANAGER_ARN_PATTERN" \
TF_VAR_deploy_stage=2 \
terraform apply tfplan-stage2

echo ""
echo "=========================================="
echo "✓ STAGE 2 COMPLETE"
echo "=========================================="
echo ""
echo "⏳ CloudFront deployment in progress (10-20 minutes)..."
echo "   Check: AWS Console → CloudFront → Status should be 'Deployed'"
echo ""
read -p "Once CloudFront is deployed, press Enter to test..."

echo ""
echo "=========================================="
echo "Testing Staging Domain"
echo "=========================================="
echo ""

echo "Testing: https://$STAGE_DOMAIN/"
if curl -I "https://$STAGE_DOMAIN/" 2>/dev/null | head -3; then
  echo ""
  echo "✓ SUCCESS: Staging domain is responding!"
else
  echo ""
  echo "⚠️  Warning: Could not reach domain yet (may still be propagating)"
fi

echo ""
echo "=========================================="
echo "✓ DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "Summary:"
echo "  ✓ ACM Certificate created with SANs: $PROD_DOMAIN, $PROD_API_DOMAIN, $STAGE_DOMAIN"
echo "  ✓ CloudFront distribution deployed"
echo "  ✓ Route53 alias records created for staging domain"
echo ""
echo "Next steps:"
echo "  1. Verify DNS propagation: nslookup $STAGE_DOMAIN"
echo "  2. Test HTTPS: curl -I https://$STAGE_DOMAIN/"
echo "  3. Monitor CloudFront: aws cloudfront get-distribution --id <dist-id>"
echo ""
