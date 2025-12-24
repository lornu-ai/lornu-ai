# AWS Staging Environment Deployment Guide

This guide describes how to deploy the Lornu AI application to the AWS staging environment.

## Overview

The AWS staging environment uses:
- **AWS ECS Fargate** for serverless container orchestration
- **Application Load Balancer (ALB)** for traffic routing and SSL termination
- **Amazon ECR** for Docker image storage
- **Terraform Cloud** for infrastructure state management
- **GitHub Actions** for CI/CD automation

## Prerequisites

### AWS Setup
1. **AWS Account** with appropriate permissions
2. **IAM Role for GitHub Actions** with OIDC trust relationship
   - Role name: `github-actions`
   - Required permissions: ECR push, ECS deploy, Terraform Cloud integration
3. **ACM Certificate** for HTTPS (must be in `us-east-1` region)
4. **AWS Secrets Manager** secrets for application configuration

### GitHub Secrets
Configure the following secrets in the GitHub repository:

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AWS_ACCOUNT_ID` | AWS Account ID | `123456789012` |
| `TERRAFORM_API_TOKEN` | Terraform Cloud API token | `xxxxxxxx.atlasv1.xxxxxxxxx` |
| `ACM_CERTIFICATE_ARN` | ARN of ACM certificate | `arn:aws:acm:us-east-1:123456789012:certificate/xxx` |
| `SECRETS_MANAGER_ARN_PATTERN` | ARN pattern for secrets | `arn:aws:secretsmanager:us-east-1:123456789012:secret:lornu-*` |
| `TF_CLOUD_ORG` | Terraform Cloud organization | `lornu-ai` |
| `TF_CLOUD_WORKSPACE` | Terraform Cloud workspace | `lornu-ai-staging-aws` |
| `AWS_DEFAULT_REGION` | AWS region for deployment | `us-east-1` |

### Terraform Cloud Setup
1. **Organization**: `lornu-ai`
2. **Workspace**: `lornu-ai-staging-aws`
3. Configure AWS credentials in the workspace (optional, if not using OIDC)

## Architecture

```
┌─────────────────┐
│   GitHub        │
│   Actions       │
└────────┬────────┘
         │
         ├─── Build Docker Image
         │    └─► Amazon ECR
         │
         └─── Terraform Apply
              └─► AWS ECS Fargate
                  ├─► Application Load Balancer
                  ├─► VPC & Networking
                  └─► IAM Roles
```

## Infrastructure Components

### Networking (`vpc.tf`)
- **VPC**: 10.1.0.0/16
- **Public Subnets**: 2x (for ALB) across AZs
- **Private Subnets**: 2x (for ECS tasks) across AZs
- **NAT Gateway**: For outbound internet access from private subnets
- **Internet Gateway**: For public subnet internet access

### Compute (`ecs.tf`)
- **ECS Cluster**: `lornu-ai-staging-cluster`
- **ECS Service**: Fargate launch type, 1 desired task
- **Task Definition**: 256 CPU, 512 MB memory
- **Container Port**: 8080

### Load Balancer (`alb.tf`)
- **ALB**: Public-facing, HTTPS with ACM certificate
- **Target Group**: Health check on `/health`
- **Listeners**: 
  - Port 80: Redirect to HTTPS
  - Port 443: Forward to ECS tasks

### Container Registry (`ecr.tf`)
- **Repository**: `lornu-ai-staging`
- **Image Scanning**: Enabled on push
- **Lifecycle Policy**: Keep last 10 images

### IAM (`iam.tf`)
- **ECS Task Execution Role**: ECR and CloudWatch Logs access
- **ECS Task Role**: Secrets Manager access

## Deployment Process

### Automated Deployment (via GitHub Actions)

The deployment is triggered automatically:

1. **Pull Request**: Builds image and runs Terraform plan
   ```
   Trigger: PR with changes to:
   - terraform/aws/staging/**
   - apps/web/**
   - packages/api/**
   - Dockerfile
   ```

2. **Push to Main**: Builds image and applies Terraform
   ```
   Trigger: Push to main branch
   ```

3. **Manual Deploy**: Workflow dispatch
   ```
   GitHub UI: Actions → Terraform AWS → Run workflow
   ```

### Workflow Steps

1. **Build and Push Docker Image**
   - Checkout code
   - Authenticate to AWS
   - Login to ECR
   - Build multi-stage Docker image
   - Tag with commit SHA and branch name
   - Push to ECR

2. **Terraform Plan**
   - Initialize Terraform with cloud backend
   - Run `terraform plan` with Docker image tag
   - Run security scan with tfsec

3. **Terraform Apply** (main/workflow_dispatch only)
   - Apply infrastructure changes
   - Update ECS service with new task definition

## Manual Deployment

### Build and Push Docker Image Locally

```bash
# Authenticate to AWS
aws sso login --profile lornu-staging

# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build image
docker build -t lornu-ai-staging:local .

# Tag image
docker tag lornu-ai-staging:local \
  <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:local

# Push image
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:local
```

### Deploy Infrastructure with Terraform

```bash
cd terraform/aws/staging

# Initialize Terraform
terraform init

# Plan changes
terraform plan \
  -var="docker_image=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:local" \
  -var="acm_certificate_arn=<ACM_CERT_ARN>" \
  -var="secrets_manager_arn_pattern=<SECRETS_ARN_PATTERN>"

# Apply changes
terraform apply \
  -var="docker_image=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:local" \
  -var="acm_certificate_arn=<ACM_CERT_ARN>" \
  -var="secrets_manager_arn_pattern=<SECRETS_ARN_PATTERN>"
```

## Verification

### Check Deployment Status

1. **ECS Service Status**
   ```bash
   aws ecs describe-services \
     --cluster lornu-ai-staging-cluster \
     --services lornu-ai-staging-service \
     --region us-east-1
   ```

2. **Task Status**
   ```bash
   aws ecs list-tasks \
     --cluster lornu-ai-staging-cluster \
     --service-name lornu-ai-staging-service \
     --region us-east-1
   ```

3. **ALB Health**
   ```bash
   aws elbv2 describe-target-health \
     --target-group-arn <TARGET_GROUP_ARN> \
     --region us-east-1
   ```

### Test Application

1. **Get ALB DNS Name**
   ```bash
   terraform output -raw alb_dns_name
   ```

2. **Test Health Endpoint**
   ```bash
   curl http://<ALB_DNS_NAME>/health
   # Expected: {"status":"ok"}
   ```

3. **Test HTTPS** (after DNS configuration)
   ```bash
   curl https://staging.lornu.ai/health
   ```

## Troubleshooting

### Task Fails to Start

1. Check CloudWatch Logs:
   ```bash
   aws logs tail /ecs/lornu-ai-staging-task --follow
   ```

2. Check task stopped reason:
   ```bash
   aws ecs describe-tasks \
     --cluster lornu-ai-staging-cluster \
     --tasks <TASK_ARN>
   ```

### Health Check Failures

1. Verify container is listening on port 8080
2. Check security group rules allow ALB → ECS traffic
3. Verify health check path is `/health`

### Image Pull Errors

1. Verify ECR repository exists
2. Check task execution role has ECR permissions
3. Verify image tag exists in ECR

## Rollback

To rollback to a previous version:

1. **Find previous image tag**
   ```bash
   aws ecr describe-images \
     --repository-name lornu-ai-staging \
     --region us-east-1
   ```

2. **Update task definition**
   ```bash
   terraform apply \
     -var="docker_image=<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/lornu-ai-staging:<OLD_TAG>"
   ```

## Monitoring

- **CloudWatch Logs**: `/ecs/lornu-ai-staging-task`
- **ECS Metrics**: CPU, Memory utilization
- **ALB Metrics**: Request count, target response time, 5xx errors

## Cost Estimation

- **ECS Fargate**: ~$15-20/month (1 task, 0.25 vCPU, 0.5 GB RAM)
- **ALB**: ~$20-25/month (base cost + LCU charges)
- **NAT Gateway**: ~$30-35/month (data transfer + hourly)
- **ECR**: Minimal (< 10 images)
- **Total**: ~$70-85/month

## Security Considerations

1. **IAM**: Use least privilege principles
2. **Secrets**: Store sensitive data in AWS Secrets Manager
3. **Network**: ECS tasks in private subnets
4. **SSL/TLS**: All public traffic over HTTPS
5. **Image Scanning**: Enabled on ECR push

## Next Steps

- [ ] Configure Route 53 DNS for custom domain
- [ ] Set up CloudWatch alarms for monitoring
- [ ] Implement log aggregation and analysis
- [ ] Configure auto-scaling policies
- [ ] Set up backup and disaster recovery
