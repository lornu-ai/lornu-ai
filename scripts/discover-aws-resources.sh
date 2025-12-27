#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat << 'USAGE'
Usage: discover-aws-resources.sh --region <region> --services <svc1,svc2> [--profile <aws-profile>]

Examples:
  scripts/discover-aws-resources.sh --region us-east-1 --services "vpc,subnet,route_table"
  scripts/discover-aws-resources.sh --region us-east-1 --profile lornu --services "vpc,rds,s3,iam"
USAGE
}

REGION=""
PROFILE=""
SERVICES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --region)
      REGION="$2"
      shift 2
      ;;
    --profile)
      PROFILE="$2"
      shift 2
      ;;
    --services)
      SERVICES="$2"
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

if [[ -z "$REGION" || -z "$SERVICES" ]]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if ! command -v terraformer >/dev/null 2>&1; then
  echo "terraformer is not installed. See https://github.com/GoogleCloudPlatform/terraformer" >&2
  exit 1
fi

OUT_DIR="terraformer-exports"
mkdir -p "$OUT_DIR"

PROFILE_ARGS=()
if [[ -n "$PROFILE" ]]; then
  PROFILE_ARGS=("--profile" "$PROFILE")
fi

terraformer import aws \
  --regions "$REGION" \
  --resources "$SERVICES" \
  --path-pattern "$OUT_DIR" \
  --path-output "$OUT_DIR" \
  "${PROFILE_ARGS[@]}"

echo "Discovery complete. Review output in $OUT_DIR/."
