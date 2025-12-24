# AWS Terraform Infrastructure

This directory contains Terraform configurations for deploying Lornu AI to AWS using ECS Fargate.

## Directory Structure

```
terraform/aws/
├── staging/     # Staging environment (develop branch)
├── prod/        # Production environment (main branch)
└── README.md    # This file
```

## Required GitHub Repository Secrets

The following secrets must be configured in GitHub repository settings (Settings > Secrets and variables > Actions > Repository secrets):

### AWS Credentials

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCOUNT_ID` | AWS account ID (12-digit number) |
| `AWS_ACCESS_KEY_ID` | AWS access key for GitHub Actions |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key for GitHub Actions |
| `AWS_DEFAULT_REGION` | AWS region (e.g., `us-east-1`) |

### Terraform Cloud

| Secret Name | Description |
|-------------|-------------|
| `TF_API_TOKEN` | Terraform Cloud API token |
| `TF_CLOUD_ORG` | Terraform Cloud organization name |
| `TF_CLOUD_WORKSPACE` | Terraform Cloud workspace name |

### Environment-Specific Secrets

#### Production (`main` branch)

| Secret Name | Description |
|-------------|-------------|
| `SECRETS_MANAGER_ARN_PATTERN_PROD` | ARN pattern for Secrets Manager access |
| `ECR_REPOSITORY` | ECR repository name (e.g., `lornu-ai-prod`) |
| `EKS_CLUSTER_NAME` | EKS cluster name (for K8s deployments) |
| `PROD_DOMAIN` | Production domain (e.g., `lornu.ai`) |

#### Staging (`develop` branch)

| Secret Name | Description |
|-------------|-------------|
| `ACM_CERTIFICATE_ARN` | ARN of ACM certificate for staging ALB |
| `SECRETS_MANAGER_ARN_PATTERN` | ARN pattern for staging Secrets Manager access |
| `STAGE_DOMAIN` | Staging domain (e.g., `staging.lornu.ai`) |

## Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| `terraform-aws-prod.yml` | Push to `main`, manual | Production ECS/Fargate deployment |
| `terraform-aws.yml` | PR to `develop`, manual | Staging ECS/Fargate deployment |
| `k8s-prod.yml` | Manual | Production EKS deployment via Kustomize |

## Infrastructure Components

Each environment provisions:

- **VPC**: Isolated network with public/private subnets
- **ECS Cluster**: Fargate-based container orchestration
- **ALB**: Application Load Balancer with HTTPS
- **ECR**: Container registry for Docker images
- **IAM**: Task execution and task roles with least-privilege policies
- **Security Groups**: Network access controls

## Manual Steps Before First Deployment

1. Create ACM certificates in AWS Certificate Manager
2. Validate domain ownership for ACM certificates
3. Create secrets in AWS Secrets Manager (if using application secrets)
4. Configure all GitHub repository secrets listed above
5. Create Terraform Cloud workspace(s)

## Related Documentation

- [AWS Staging Design](../docs/AWS_STAGING_DESIGN.md)
- [AWS Compute Strategy](../docs/aws-compute-strategy.md)
