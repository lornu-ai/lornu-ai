#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Usage: aws-import-blocks.sh --dir <terraform-dir>

Runs a guided import-block workflow against Terraform Cloud state.

Examples:
  scripts/aws-import-blocks.sh --dir terraform/aws
USAGE
}

TF_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      TF_DIR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
 done

if [[ -z "$TF_DIR" ]]; then
  echo "Missing --dir." >&2
  usage
  exit 1
fi

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform is not installed." >&2
  exit 1
fi

if [[ -z "${TF_CLOUD_ORGANIZATION:-}" || -z "${TF_WORKSPACE:-}" ]]; then
  echo "TF_CLOUD_ORGANIZATION and TF_WORKSPACE must be set for Terraform Cloud state." >&2
  exit 1
fi

echo "Initializing Terraform in $TF_DIR"
terraform -chdir="$TF_DIR" init

echo "Optional: generate missing config with import blocks in place"
echo "  terraform -chdir=$TF_DIR plan -generate-config-out=generated.tf"

echo "Running plan to validate import blocks"
terraform -chdir="$TF_DIR" plan

echo "If plan is clean, apply to write imports to Terraform Cloud state"
terraform -chdir="$TF_DIR" apply
