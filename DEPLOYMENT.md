# 🚀 Deployment Guide: Local → AWS Fargate

Fast track to production deployment with cost-effective local testing.

## Overview

```
Local Testing (minikube) → AWS Staging (ECS Fargate) → AWS Production
    ↓ $0/hour              ↓ ~$0.04/hour           ↓ ~$0.08/hour
    ✅ Fast iteration       ✅ Real AWS infra       ✅ Production ready
```

## Phase 1: Local Testing (Start Here)

**Time**: 5-10 minutes  
**Cost**: $0

### Setup
```bash
# One-time setup
./scripts/local-k8s-setup.sh

# Deploy
./scripts/local-k8s-deploy.sh

# Test
./scripts/local-k8s-test.sh

# Access
kubectl port-forward svc/lornu-ai 8080:8080
curl http://localhost:8080/api/health
```

### What's Tested
- ✅ Docker image builds correctly
- ✅ Frontend serves from FastAPI
- ✅ Health endpoint works
- ✅ Kubernetes manifests valid
- ✅ Resource limits appropriate

### Iterate Fast
```bash
# Edit code
vim apps/web/src/App.tsx

# Quick rebuild & redeploy
eval $(minikube docker-env)
docker build -t lornu-ai:local . && \
kubectl rollout restart deployment/lornu-ai

# Watch logs
kubectl logs -f -l app.kubernetes.io/name=lornu-ai
```

## Phase 2: AWS Staging Deployment

**Time**: 10-15 minutes (first time)  
**Cost**: ~$30/month (~$0.04/hour)

### Prerequisites
- ✅ Local tests passing
- ✅ PR #146 merged
- ✅ AWS credentials configured
- ✅ Terraform Cloud setup

### Deploy to Staging

#### Option A: GitHub Actions (Recommended)
```bash
# 1. Merge PR #146
gh pr merge 146

# 2. Push to develop
git checkout develop
git pull origin develop
git push origin develop

# 3. Trigger deployment
gh workflow run terraform-aws.yml
```

#### Option B: Manual Terraform
```bash
# 1. Build and push to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

docker build -t $ECR_REGISTRY/lornu-ai-staging:$GIT_SHA .
docker push $ECR_REGISTRY/lornu-ai-staging:$GIT_SHA

# 2. Run Terraform
cd terraform/aws/staging
terraform init
terraform plan \
  -var="docker_image=$ECR_REGISTRY/lornu-ai-staging:$GIT_SHA"
terraform apply -auto-approve
```

### Verify Staging
```bash
# Get ALB URL from Terraform output
terraform output alb_dns_name

# Test
curl https://staging.lornu.ai/api/health
```

### What's Deployed
- ✅ ECS Fargate with 3 replicas
- ✅ Application Load Balancer
- ✅ ECR for images
- ✅ VPC with public/private subnets
- ✅ Security groups
- ✅ IAM roles

## Phase 3: Production Deployment

**Time**: 15-20 minutes  
**Cost**: ~$60/month (~$0.08/hour)

### Prerequisites
- ✅ Staging validated
- ✅ Issue #159 tasks completed
- ✅ Production Terraform created

### Tasks (from Issue #159)
1. Create `terraform/aws/production/`
2. Add production resources:
   - Multi-AZ VPC (3 AZs)
   - Aurora Serverless v2
   - CloudFront + WAF
   - Route53 DNS
3. Update CI/CD with manual approval gate

### Deploy to Production
```bash
# 1. Merge production infrastructure PR
gh pr merge <production-pr>

# 2. Trigger production deploy (manual approval required)
gh workflow run terraform-aws.yml --ref main

# 3. Wait for approval in GitHub Actions UI
# 4. Approve and deploy
```

## Monitoring & Operations

### Logs
```bash
# Local
kubectl logs -f -l app.kubernetes.io/name=lornu-ai

# AWS Staging/Prod
aws logs tail /aws/ecs/lornu-ai-staging --follow
```

### Metrics
```bash
# Local
kubectl top pods

# AWS
# Use CloudWatch dashboard or:
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=lornu-ai-staging
```

### Scaling
```bash
# Local (manual)
kubectl scale deployment/lornu-ai --replicas=2

# AWS (configured in Terraform)
# Auto-scales based on CPU/memory
```

## Cost Optimization

| Environment | Hours/Month | Cost/Month | Use Case |
|------------|-------------|------------|----------|
| Local | Unlimited | $0 | Development, testing |
| Staging | 730 | ~$30 | Integration, QA |
| Production | 730 | ~$60 | Live users |

**Savings**: Testing locally saves ~$720/year in staging costs! 💰

## Troubleshooting

### Local Issues
See [LOCAL_TESTING.md](LOCAL_TESTING.md)

### AWS Issues

#### Image not found in ECR
```bash
# Check image exists
aws ecr describe-images --repository-name lornu-ai-staging

# Rebuild and push
./scripts/build-and-push-ecr.sh
```

#### ECS tasks not starting
```bash
# Check task definition
aws ecs describe-task-definition --task-definition lornu-ai-staging

# Check service events
aws ecs describe-services \
  --cluster lornu-ai-staging \
  --services lornu-ai-staging \
  --query 'services[0].events'
```

#### ALB health checks failing
```bash
# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check logs
aws logs tail /aws/ecs/lornu-ai-staging --follow
```

## Next Steps

1. ✅ Complete local testing
2. ✅ Merge PR #146
3. ✅ Deploy to staging
4. ⏳ Complete Issue #159 tasks
5. ⏳ Deploy to production
6. ⏳ Set up monitoring (Better Stack)
7. ⏳ Configure DNS
8. ⏳ Enable CloudFront + WAF

## Support

- **Issues**: https://github.com/lornu-ai/lornu-ai/issues
- **Docs**: See `docs/` folder
- **Local Testing**: [LOCAL_TESTING.md](LOCAL_TESTING.md)
