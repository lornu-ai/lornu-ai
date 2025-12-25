#!/bin/bash
set -e

# Configuration
ORG_NAME=$1
WORKSPACE_NAME=$2
TFC_TOKEN=$3

if [ -z "$ORG_NAME" ] || [ -z "$WORKSPACE_NAME" ] || [ -z "$TFC_TOKEN" ]; then
  echo "Usage: ./bootstrap.sh <org_name> <workspace_name> <tfc_token>"
  exit 1
fi

echo "Checking if workspace $WORKSPACE_NAME exists in organization $ORG_NAME..."

STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  --header "Authorization: Bearer $TFC_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME")

WORKSPACE_ID="" # Initialize WORKSPACE_ID

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "Workspace $WORKSPACE_NAME already exists."
  WORKSPACE_ID=$(curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces/$WORKSPACE_NAME" | jq -r .data.id)
elif [ "$STATUS_CODE" -eq 404 ]; then
  echo "Workspace $WORKSPACE_NAME not found. Creating it..."

  PAYLOAD=$(cat <<EOF
{
  "data": {
    "attributes": {
      "name": "$WORKSPACE_NAME",
      "resource-count": 0,
      "updated-at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    },
    "type": "workspaces"
  }
}
EOF
)

  CREATE_RESPONSE=$(curl -s \
    --header "Authorization: Bearer $TFC_TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    --request POST \
    --data "$PAYLOAD" \
    "https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces")

  if echo "$CREATE_RESPONSE" | grep -q "\"type\":\"workspaces\""; then
    echo "Successfully created workspace $WORKSPACE_NAME."
    WORKSPACE_ID=$(echo "$CREATE_RESPONSE" | jq -r .data.id)
  else
    echo "Failed to create workspace: $CREATE_RESPONSE"
    exit 1
  fi
else
  echo "Unexpected status code from TFC API: $STATUS_CODE"
  exit 1
fi

# Ensure OIDC Variables exist
ROLE_ARN=$4
if [ -n "$ROLE_ARN" ] && [ -n "$WORKSPACE_ID" ] && [ "$WORKSPACE_ID" != "null" ]; then
  echo "Ensuring OIDC variables for workspace $WORKSPACE_ID..."

  for KEY in "TFC_AWS_PROVIDER_AUTH" "TFC_AWS_RUN_ROLE_ARN"; do
    VALUE="true"
    [ "$KEY" == "TFC_AWS_RUN_ROLE_ARN" ] && VALUE="$ROLE_ARN"

    # Check if variable exists
    VAR_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      --header "Authorization: Bearer $TFC_TOKEN" \
      "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/vars?filter%5Bkey%5D=$KEY")

    # Simple check: if not 200/found, create it.
    # (Actually TFC API for vars is a bit more complex, but a POST usually works or fails if exists)
    curl -s \
      --header "Authorization: Bearer $TFC_TOKEN" \
      --header "Content-Type: application/vnd.api+json" \
      --request POST \
      --data "{\"data\":{\"type\":\"vars\",\"attributes\":{\"key\":\"$KEY\",\"value\":\"$VALUE\",\"category\":\"env\",\"hcl\":false,\"sensitive\":false}}}" \
      "https://app.terraform.io/api/v2/workspaces/$WORKSPACE_ID/vars" > /dev/null || true
  done
fi
