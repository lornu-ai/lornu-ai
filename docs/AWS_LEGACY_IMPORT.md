# AWS Legacy Infrastructure Discovery and Import

This guide covers AWS discovery and Terraform import using Terraform Cloud state.
It targets issue #444 and focuses on automation steps for existing resources.

## Prerequisites

- Terraform CLI 1.5+ installed.
- AWS CLI authenticated with read access for discovery and write access for import, used only when running these steps manually (do not configure or run discovery/import with write-capable credentials in CI).
- Terraform Cloud workspace already created and configured (standard: `aws-kustomize` in the `lornu-ai` organization).
- Environment variables:
  - `AWS_TF_CLOUD_ORG` (typically `lornu-ai`)
  - `AWS_TF_CLOUD_WORKSPACE` (typically `aws-kustomize` for this AWS/Kustomize stack; adjust per environment as needed)
  - `AWS_REGION`

## Discovery (AWS)

We use `terraformer` to generate initial HCL/state for unmanaged resources.

1. Install terraformer
   ```bash
   brew install terraformer
   # or see https://github.com/GoogleCloudPlatform/terraformer
   ```

2. Run discovery script
   ```bash
   scripts/discover-aws-resources.sh \
     --region us-east-1 \
     --profile lornu \
     --services "vpc,subnet,route_table,igw,nat,security_group,rds,s3,iam"
   ```

3. Review output in `terraformer-exports/` and move relevant resources into
   the target Terraform module structure.

## Import Using Terraform 1.5+ Import Blocks

We use import blocks for idempotent, reviewable imports against Terraform Cloud.

1. Create an import file in your module (example)
   ```hcl
   import {
     to = aws_vpc.main
     id = "vpc-0123456789abcdef0"
   }
   ```

2. Generate config for any missing resources (optional)
   ```bash
   terraform plan -generate-config-out=generated.tf
   ```

3. Run a plan and verify zero-diff
   ```bash
   terraform plan
   ```

4. Apply once the plan is clean
   ```bash
   terraform apply
   ```

5. Remove import blocks after a successful apply to keep config clean.

## Suggested Workflow

1. Inventory critical services (VPC, subnets, IAM, RDS, S3).
2. Generate HCL with terraformer and refactor into modules.
3. Add import blocks for each resource and run plan.
4. Confirm zero-diff before apply.
5. Tag imported resources with `ManagedBy=Terraform`.

## Notes

- Do not run discovery or import in CI. Keep these operations manual.
- Use read-only AWS credentials for discovery.
- For staging vs production, set the correct `TF_WORKSPACE` per environment.
