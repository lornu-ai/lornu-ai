# PR #320 Deployment Instructions

## Overview
PR #320 adds staging domain alias support (e.g., `s1.lornu.ai`) to the production CloudFront distribution.

## Prerequisites
1. Checkout the feature branch:
   ```bash
   git checkout fix/staging-domain-alias
   ```

2. Verify GitHub secrets are set:
   - `PROD_DOMAIN` (e.g., lornu.ai)
   - `PROD_API_DOMAIN` (e.g., api.lornu.ai)
   - `STAGE_DOMAIN` (e.g., s1.lornu.ai) ← **NEW**
   - `PROD_DB_USERNAME`, `PROD_DB_PASSWORD`
   - `ROUTE53_ZONE_NAME`
   - `SECRETS_MANAGER_ARN_PATTERN`
   - `PROD_ACM_CERTIFICATE_ARN` (can be empty to create new cert)

## Deployment Plan

### Option A: Using GitHub Actions Workflows (Recommended)

#### Stage 1: Create ACM Certificate
```bash
gh workflow run terraform-aws-stage1-acm.yml \
  -f environment=prod \
  -f action=apply
```

**What happens:**
- Creates ACM certificate with SANs: `lornu.ai`, `api.lornu.ai`, `s1.lornu.ai`
- Creates Route53 DNS validation records
- Waits for certificate validation (5-15 minutes)

**Monitor:** 
- GitHub Actions: `terraform-aws-stage1-acm.yml`
- AWS Console: ACM → Certificate status should show "ISSUED"

#### Stage 2: Deploy CloudFront & Route53
After Stage 1 completes and certificate is ISSUED:

```bash
gh workflow run terraform-aws-stage2-cdn.yml \
  -f environment=prod \
  -f action=apply
```

**What happens:**
- Creates CloudFront distribution with aliases for all domains
- Creates Route53 A/AAAA records pointing to CloudFront
- Enables HTTPS for `s1.lornu.ai`

**Monitor:**
- GitHub Actions: `terraform-aws-stage2-cdn.yml`
- AWS Console: CloudFront → Distribution status should show "Deployed" (10-20 minutes)

#### Stage 3: Test
```bash
# Test HTTPS endpoint
curl -I https://s1.lornu.ai/

# Should return: 200 OK with valid SSL certificate
```

---

### Option B: Local Terraform Deployment

If you prefer running Terraform locally:

```bash
cd terraform/aws/production

# Set required environment variables
export PROD_DOMAIN=lornu.ai
export PROD_API_DOMAIN=api.lornu.ai
export STAGE_DOMAIN=s1.lornu.ai
export PROD_DB_USERNAME=lornu_admin
export PROD_DB_PASSWORD="<password>"
export ROUTE53_ZONE_NAME=lornu.ai
export SECRETS_MANAGER_ARN_PATTERN="<pattern>"
export PROD_ACM_CERTIFICATE_ARN=""  # Leave empty to create new cert

# Stage 1: Initialize and plan
terraform init

terraform plan \
  -var="deploy_stage=1" \
  -var="extra_domain_names=[\"$STAGE_DOMAIN\"]" \
  -var="domain_name=$PROD_DOMAIN" \
  -var="api_domain=$PROD_API_DOMAIN" \
  -var="db_username=$PROD_DB_USERNAME" \
  -var="db_password=$PROD_DB_PASSWORD" \
  -var="route53_zone_name=$ROUTE53_ZONE_NAME" \
  -var="secrets_manager_arn_pattern=$SECRETS_MANAGER_ARN_PATTERN" \
  -var="existing_acm_certificate_arn=$PROD_ACM_CERTIFICATE_ARN" \
  -target=aws_acm_certificate.cloudfront \
  -target=aws_route53_record.cloudfront_cert_validation \
  -target=aws_acm_certificate_validation.cloudfront \
  -out=tfplan-stage1

# Review plan and apply
terraform apply tfplan-stage1

# Wait 5-15 minutes for certificate validation...
echo "⏳ Waiting for DNS validation (check AWS Console ACM)"
read -p "Press Enter once certificate is ISSUED..."

# Stage 2: Deploy CloudFront
terraform plan \
  -var="deploy_stage=2" \
  -var="extra_domain_names=[\"$STAGE_DOMAIN\"]" \
  -var="domain_name=$PROD_DOMAIN" \
  -var="api_domain=$PROD_API_DOMAIN" \
  -var="db_username=$PROD_DB_USERNAME" \
  -var="db_password=$PROD_DB_PASSWORD" \
  -var="route53_zone_name=$ROUTE53_ZONE_NAME" \
  -var="secrets_manager_arn_pattern=$SECRETS_MANAGER_ARN_PATTERN" \
  -var="existing_acm_certificate_arn=$PROD_ACM_CERTIFICATE_ARN" \
  -out=tfplan-stage2

terraform apply tfplan-stage2

# Wait 10-20 minutes for CloudFront deployment...
echo "⏳ Waiting for CloudFront deployment"
read -p "Press Enter once CloudFront is deployed..."

# Test
curl -I https://s1.lornu.ai/
```

---

## Rollback (if needed)

If Stage 2 fails, you can safely rollback:

```bash
cd terraform/aws/production

# Destroy only CloudFront (keeps cert for retry)
terraform destroy \
  -var="deploy_stage=2" \
  -var="extra_domain_names=[\"s1.lornu.ai\"]" \
  -target=aws_cloudfront_distribution.api \
  -target=aws_route53_record.apex \
  -target=aws_route53_record.api_cloudfront \
  -target=aws_route53_record.staging_cloudfront

# Then rerun Stage 2
```

---

## Troubleshooting

### CloudFront shows "Certificate does not match alias"
**Cause:** ACM certificate doesn't include `s1.lornu.ai` SAN

**Fix:** 
1. Clear `PROD_ACM_CERTIFICATE_ARN` in GitHub secrets
2. Rerun Stage 1 to create new certificate with all SANs

### DNS not resolving for s1.lornu.ai
**Cause:** Route53 alias records not created or CloudFront not deployed

**Check:**
```bash
# Verify Route53 records exist
aws route53 list-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --query 'ResourceRecordSets[?Name==`s1.lornu.ai.`]'

# Verify CloudFront distribution
aws cloudfront get-distribution-config --id <distribution-id>
```

### Certificate validation stuck
**Cause:** DNS CNAME records not created or not propagated

**Check:**
```bash
# Verify Route53 records were created
aws route53 list-resource-record-sets --hosted-zone-id <zone-id>

# Test DNS propagation
nslookup _<random>.lornu.ai
```

---

## Success Criteria

✅ All checks should pass:
- [ ] ACM certificate created with status "ISSUED"
- [ ] ACM certificate includes SANs: lornu.ai, api.lornu.ai, s1.lornu.ai
- [ ] CloudFront distribution created with status "Deployed"
- [ ] CloudFront aliases include: lornu.ai, api.lornu.ai, s1.lornu.ai
- [ ] Route53 A/AAAA records created for all domains pointing to CloudFront
- [ ] `curl -I https://s1.lornu.ai/` returns 200 OK

---

## Post-Deployment

After successful deployment:

1. **Monitor CloudFront metrics:**
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/CloudFront \
     --metric-name Requests \
     --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
     --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
     --period 3600 \
     --statistics Sum
   ```

2. **Verify Kustomize can now use staging domain:**
   Update `kubernetes/overlays/staging/kustomization.yaml` to reference `s1.lornu.ai`

3. **Optional: Merge PR #320** to develop/main
   ```bash
   git checkout develop
   git pull origin develop
   gh pr merge 320
   ```
