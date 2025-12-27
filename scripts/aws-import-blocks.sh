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

if [[ -z "${AWS_TF_CLOUD_ORG:-}" || -z "${AWS_TF_CLOUD_WORKSPACE:-}" ]]; then
  echo "AWS_TF_CLOUD_ORG and AWS_TF_CLOUD_WORKSPACE must be set for Terraform Cloud state." >&2
  exit 1
fi

echo "Initializing Terraform in $TF_DIR"
if ! terraform -chdir="$TF_DIR" init; then
  echo "ERROR: 'terraform init' failed for directory: $TF_DIR" >&2
  echo "       Check your Terraform configuration, backend settings, and Terraform Cloud credentials," >&2
  echo "       then re-run: terraform -chdir=\"$TF_DIR\" init" >&2
  exit 1
fi

echo "Optional: generate missing config with import blocks in place"
echo "  terraform -chdir=$TF_DIR plan -generate-config-out=generated.tf"

echo "Running plan to validate import blocks"
if ! terraform -chdir="$TF_DIR" plan; then
  echo "ERROR: 'terraform plan' failed while validating import blocks in: $TF_DIR" >&2
  echo "       Fix the issues reported by Terraform (e.g., incorrect import blocks or configuration)" >&2
  echo "       and then re-run: terraform -chdir=\"$TF_DIR\" plan" >&2
  exit 1
fi

echo "If plan is clean, apply to write imports to Terraform Cloud state"
if ! terraform -chdir="$TF_DIR" apply; then
  echo "ERROR: 'terraform apply' failed when writing imports to Terraform Cloud state for: $TF_DIR" >&2
  echo "       Review the plan output and error details above, resolve any issues," >&2
  echo "       then re-run: terraform -chdir=\"$TF_DIR\" apply" >&2
  exit 1
fi
