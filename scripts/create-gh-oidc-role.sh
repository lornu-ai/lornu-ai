#!/usr/bin/env bash
set -euo pipefail

# GitHub OIDC Role Setup Script
# - Ensures OIDC provider exists
# - Creates or updates IAM role trust policy for GitHub Actions
# - Attaches AdministratorAccess (temporary; tighten later)
# - Prints the role ARN
#
# Usage:
#   AWS_PROFILE=yourprofile AWS_REGION=us-east-2 ./scripts/create-gh-oidc-role.sh
#   Or pass profile via first arg: ./scripts/create-gh-oidc-role.sh yourprofile
#
# Requirements: awscli v2, valid AWS credentials for the target account

PROFILE="${1:-${AWS_PROFILE:-}}"
if [[ -z "${PROFILE}" ]]; then
  echo "ERROR: AWS profile not set. Set AWS_PROFILE or pass as first argument." >&2
  exit 1
fi

REGION="${AWS_REGION:-us-east-2}"
ROLE_NAME="github-actions"
PROVIDER_URL="token.actions.githubusercontent.com"
THUMBPRINT="6938fd4d98bab03faadb97b34396831e3780aea1"

export AWS_PROFILE="${PROFILE}"
export AWS_REGION="${REGION}"

# Resolve account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [[ -z "${ACCOUNT_ID}" ]]; then
  echo "ERROR: Unable to resolve AWS account ID for profile ${PROFILE}." >&2
  exit 1
fi

echo "Using account: ${ACCOUNT_ID} (profile: ${PROFILE}, region: ${REGION})"

OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${PROVIDER_URL}"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"

# 1) Ensure OIDC provider exists
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_ARN}" >/dev/null 2>&1; then
  echo "OIDC provider exists: ${OIDC_ARN}"
else
  echo "Creating OIDC provider: ${OIDC_ARN}"
  aws iam create-open-id-connect-provider \
    --url "https://${PROVIDER_URL}" \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list "${THUMBPRINT}"
fi

# 2) Create or update IAM role trust policy
cat > /tmp/gha-trust.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GitHubOIDCTrust",
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:lornu-ai/lornu-ai:*"
          ]
        }
      }
    }
  ]
}
JSON

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Updating trust policy on role: ${ROLE_NAME}"
  aws iam update-assume-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-document file:///tmp/gha-trust.json
else
  echo "Creating role: ${ROLE_NAME}"
  aws iam create-role \
    --role-name "${ROLE_NAME}" \
    --assume-role-policy-document file:///tmp/gha-trust.json \
    --tags Key=Owner,Value=GitHubActions Key=Env,Value=prod
fi

# 3) Attach AdministratorAccess if not already (temporary)
ATTACHED=$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --query 'AttachedPolicies[].PolicyArn' --output text || true)
if echo "${ATTACHED}" | grep -q "arn:aws:iam::aws:policy/AdministratorAccess"; then
  echo "AdministratorAccess already attached to ${ROLE_NAME}"
else
  echo "Attaching AdministratorAccess to ${ROLE_NAME} (temporary; tighten later)"
  aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
fi

# 4) Output final role ARN and trust policy
ROLE_ARN_OUT=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.Arn' --output text)
TRUST_OUT=$(aws iam get-role --role-name "${ROLE_NAME}" --query 'Role.AssumeRolePolicyDocument' --output json)

echo "ROLE_ARN=${ROLE_ARN_OUT}"
echo "TrustPolicy=${TRUST_OUT}"

echo "Done. Use this in GitHub Secrets: AWS_ACTIONS_PROD_ROLE_ARN=${ROLE_ARN_OUT}"
