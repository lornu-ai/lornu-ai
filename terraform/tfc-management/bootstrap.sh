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

if [ "$STATUS_CODE" -eq 200 ]; then
  echo "Workspace $WORKSPACE_NAME already exists."
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
  else
    echo "Failed to create workspace: $CREATE_RESPONSE"
    exit 1
  fi
else
  echo "Unexpected status code from TFC API: $STATUS_CODE"
  exit 1
fi
