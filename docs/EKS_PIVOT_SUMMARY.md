# Issue Updates: ECS → EKS Kubernetes Pivot Summary

## Overview
We have pivoted the entire infrastructure strategy from **AWS ECS Fargate** to **AWS EKS with Kubernetes orchestration**, using **Kustomize** for environment-specific overlays. This enables local parity (minikube/K3s) and cloud-native deployments.

## Key Changes

### Staging Infrastructure (#79, #103)
- **Old**: ECS Fargate tasks → ALB
- **New**: EKS cluster + Managed Node Groups → ALB Ingress Controller
- **Local Dev**: Minikube/K3s with Kustomize overlays (identical to staging/prod)
- **Status**: ✅ COMPLETE via PR #161 rework

### Production Infrastructure (#150)
- **Old**: ECS Fargate service (3 AZs), Aurora Serverless, CloudFront, WAF, Route53
- **New**: EKS cluster with 3 replicas, pod anti-affinity, same support services (Aurora, CF, WAF, Route53)
- **Status**: 🔄 IN PROGRESS (EKS scaffold complete, production Terraform in progress)

### Kubernetes Manifests (#80, #102, #103, #104)
- **Status**: ✅ COMPLETE
- **Location**: `kubernetes/base/` (core) + `kubernetes/overlays/{dev,staging,production}` (patches)
- **Features**:
  - Security context (non-root, read-only FS)
  - IRSA (IAM Roles for Service Accounts)
  - Health probes pointing to `/api/health`
  - ConfigMap + Secret injection

### CI/CD Pipeline
- **Old**: `terraform apply` for ECS → ALB
- **New**: `terraform apply` (EKS) + `kubectl apply -k` (Kustomize deploy)
- **Status**: ✅ UPDATED in PR #161 rework

### Local Development Setup
- **Scripts**: `./scripts/local-k8s-setup.sh`, `deploy.sh`, `test.sh`, `cleanup.sh`
- **Documentation**: `docs/LOCAL_TESTING.md`, `kubernetes/K8S_GUIDE.md`
- **Status**: ✅ COMPLETE

## Affected Issues

| Issue | Title | Old Pattern | New Pattern | Status |
|-------|-------|------------|------------|--------|
| #79 | AWS Staging (Kubernetes Pivot) | ECS | EKS | ✅ Complete |
| #80 | Cloud-Native Kustomize Strategy | N/A | Kustomize | ✅ Complete |
| #102 | Kustomize Base Manifests | N/A | kubernetes/base/ | ✅ Complete |
| #103 | Staging Overlay & CI | ECS workflow | kubectl deploy | ✅ Complete |
| #104 | Local Dev Overlay | N/A | Minikube + Kustomize | ✅ Complete |
| #150 | Production Infrastructure | ECS + RDS + CF + WAF | EKS + RDS + CF + WAF | 🔄 In Progress |
| #159 | What's Next (Issue #150) | ECS staging reference | EKS reference | 🔄 In Progress |

## Files Changed

### Kubernetes Manifests
- `kubernetes/base/deployment.yaml` – Added security, IRSA, probes
- `kubernetes/base/serviceaccount.yaml` – New for IRSA
- `kubernetes/base/configmap.yaml` – Updated keys
- `kubernetes/base/kustomization.yaml` – Added ServiceAccount
- `kubernetes/overlays/staging/kustomization.yaml` – ECR image, 2 replicas
- `kubernetes/overlays/production/*` – New (3 replicas, pod anti-affinity)

### Terraform
- `terraform/aws/staging/eks.tf` – EKS cluster, node groups, add-ons
- `terraform/aws/production/eks.tf` – EKS cluster scaffold
- `terraform/aws/production/github-oidc.tf` – OIDC IAM role (new)
- `terraform/aws/staging/github-oidc.tf` – OIDC IAM role (new)

### CI/CD
- `.github/workflows/terraform-aws.yml` – Replaced ECS task apply with kubectl deploy

### Documentation
- `docs/LOCAL_TESTING.md` – Minikube quick-start (new)
- `kubernetes/K8S_GUIDE.md` – Comprehensive Kustomize guide (new)
- `.github/copilot-instructions.md` – Updated to EKS/Kustomize

### Scripts
- `scripts/local-k8s-setup.sh` – Enhanced (podman-first)
- `scripts/local-k8s-deploy.sh` – Enhanced (kustomize)
- `scripts/local-k8s-test.sh` – Enhanced (EKS messaging)
- `scripts/local-k8s-cleanup.sh` – Enhanced (podman support)

## Next Steps

1. **Finish Production Terraform**: Complete `terraform/aws/production/` with EKS cluster, node groups, RDS, CloudFront, WAF, Route53
2. **Update Issue #150**: Reflect EKS strategy instead of ECS
3. **Update Issue #159**: Reference EKS in "what's next" summary
4. **Production Secrets**: Set up AWS_ACTIONS_PROD_ROLE_ARN secret for prod CI/CD
5. **Merge PR #161**: Reworked staging infrastructure (EKS instead of ECS)
6. **Close sub-issues**: Mark #102, #103, #104 as complete (Kustomize phase done)

## Questions for Review

- [ ] Should we keep staging Terraform's ECS artifacts for backward compatibility, or remove entirely?
- [ ] Is the production overlay's 3-replica count and pod anti-affinity correct for initial HA setup?
- [ ] Should production use spot instances for cost savings, or stay on-demand?
- [ ] Are there additional security group / IRSA bindings needed for production EKS?
