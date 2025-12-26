# EKS to ECS Migration Guide

**Status**: Migration from ECS Fargate to EKS in progress

## Why EKS Instead of ECS?

1. **Native Kubernetes**: We already have k8s manifests and local minikube testing
2. **Portability**: Can run same manifests locally, AWS, GCP, or on-prem
3. **Ecosystem**: Better tooling (kubectl, helm, kustomize, istio, etc.)
4. **Consistency**: Local dev environment matches production
5. **Future-proof**: Industry standard for container orchestration

## Migration Steps

### Phase 1: Create EKS Infrastructure ✅ (In Progress)

New files created:
- `terraform/aws/staging/eks.tf` - EKS cluster and node group
- `terraform/aws/staging/eks-iam.tf` - IAM roles for EKS

### Phase 2: Remove ECS Infrastructure

Files to remove/update:
- `terraform/aws/staging/ecs.tf` - Remove entirely
- `terraform/aws/staging/alb.tf` - Update for EKS ingress
- `terraform/aws/staging/iam.tf` - Remove ECS-specific roles

### Phase 3: Add ALB Ingress Controller

```bash
# After EKS is created, install ALB Ingress Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=lornu-ai-staging \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1
```

### Phase 4: Update CI/CD Workflow

Update `.github/workflows/terraform-aws.yml` to:
1. Run Terraform (creates EKS cluster)
2. Configure kubectl with EKS
3. Apply Kustomize manifests
4. Create Ingress resource for ALB

### Phase 5: Create Ingress Resource

Create `kubernetes/overlays/staging/ingress.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: lornu-ai
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_CERTIFICATE_ARN}
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: lornu-ai
            port:
              number: 8080
```

## Cost Comparison

| Service | ECS Fargate | EKS |
|---------|-------------|-----|
| Compute | $0.04/vCPU/hour | $0.0464/hour (t3.medium) |
| Control Plane | Free | $0.10/hour |
| NAT Gateway | $0.045/hour | $0.045/hour |
| ALB | $0.0225/hour | $0.0225/hour |
| **Monthly (2 nodes)** | **~$30** | **~$75** |

**Trade-off**: +$45/month for better developer experience and portability

## Timeline

- [x] Create EKS Terraform files
- [ ] Update VPC for EKS requirements
- [ ] Remove ECS resources
- [ ] Update ALB for ingress
- [ ] Test locally with minikube
- [ ] Deploy to AWS
- [ ] Validate end-to-end
- [ ] Update production plan

## Next Actions

1. Review `eks.tf` and `eks-iam.tf`
2. Update `variables.tf` for EKS-specific vars
3. Remove ECS references from `iam.tf`
4. Update workflow to deploy to EKS
5. Create staging ingress manifest
6. Test full deployment

## Rollback Plan

If issues arise, we can:
1. Keep both ECS and EKS Terraform in separate branches
2. Use feature flags in workflow to choose deployment target
3. Blue/green deployment during migration
