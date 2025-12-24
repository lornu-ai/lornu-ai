# GitHub Comment Templates for EKS Pivot

## Comment for Issue #150: AWS Production Infrastructure Provisioning

---

### Strategy Update: ECS Fargate → AWS EKS (Kubernetes)

Thanks for outlining the production infrastructure requirements. We've reviewed the design and made a strategic pivot from **ECS Fargate** to **AWS EKS**, while preserving all the high-availability, security, and persistence goals you outlined.

#### What Changed (Compute)
- **Old**: ECS Fargate service with ALB (proprietary container orchestration)
- **New**: EKS cluster with managed node groups + ALB Ingress Controller (Kubernetes-native)

#### What Stays the Same (Everything Else)
All other components remain aligned with your vision:
- ✅ **Multi-AZ High Availability**: EKS with 3 replicas across AZs, pod anti-affinity
- ✅ **Load Balancing**: ALB via AWS Load Balancer Controller (Ingress resource)
- ✅ **Data Persistence**: Aurora Serverless v2 (PostgreSQL)
- ✅ **Edge Security**: CloudFront + AWS WAF + Route53
- ✅ **SSL/TLS**: ACM for automated cert renewal
- ✅ **Secrets Management**: AWS Secrets Manager + IRSA (IAM Roles for Service Accounts)
- ✅ **CI/CD**: GitHub Actions with OIDC + manual approval gates

#### Why EKS?
1. **Local Parity**: Developers can run identical config on minikube/K3s locally, eliminating "works on my machine" issues
2. **Portability**: Kustomize overlays make it trivial to deploy the same manifests across staging, production, and even GCP
3. **Community Standard**: EKS aligns with industry-standard Kubernetes tooling and reduces vendor lock-in
4. **ADK/A2A Readiness**: Kubernetes is the de facto standard for orchestrating agent-to-agent communication at scale

#### Progress So Far
- ✅ Created `k8s/base/` and `k8s/overlays/{staging,production}` with Kustomize manifests
- ✅ Provisioned EKS cluster scaffold in `terraform/aws/production/eks.tf`
- ✅ Added production GitHub Actions OIDC role for secure CI/CD
- ✅ Updated CI workflow to deploy via `kubectl apply -k` instead of ECS task updates
- ✅ Documented local dev setup in `docs/LOCAL_TESTING.md` and `k8s/K8S_GUIDE.md`

#### Next Steps (Refined for EKS)
1. **Complete Production Terraform**:
   - Add RDS Aurora Serverless v2 (`terraform/aws/production/rds.tf`)
   - Add CloudFront + WAF + Route53 (`terraform/aws/production/cdn.tf`)
   - Configure ALB Ingress Controller via Helm
   - Set up cluster autoscaler

2. **Production Kustomize Overlay**:
   - 3 replicas with pod anti-affinity
   - Appropriate resource limits (512Mi / 500m request, 1Gi / 1000m limit)
   - Secret references to AWS Secrets Manager (via External Secrets Operator or manual Secrets)

3. **CI/CD for Production**:
   - Add manual approval gate for production deployments
   - Extend workflow to test Terraform plan and apply to production workspace
   - Use `AWS_ACTIONS_PROD_ROLE_ARN` secret for production OIDC assume

4. **Zero-Downtime Deployment**:
   - Use Kubernetes rolling updates (already configured in base Deployment)
   - Pod disruption budgets (PDB) for graceful node drains
   - Health probes mapped to `/api/health` endpoint

#### Acceptance Criteria (Revised)
- [ ] `terraform/aws/production/` fully provisions EKS cluster, node groups, RDS, CloudFront, WAF, Route53
- [ ] Zero-downtime deployment via `kubectl rollout` (no ECS minimum_healthy_percent needed, K8s handles this natively)
- [ ] Smoke test suite validates deployment before DNS cutover
- [ ] IRSA configured to allow pods to access GCP Firestore and AWS Secrets Manager
- [ ] Production endpoint returns 200 OK from `/api/health`

This pivot aligns with the broader "Open Source AI" mission—developers can now run the exact same Lornu AI stack locally, in staging, and in production without friction.

Questions? Happy to clarify the EKS design or any acceptance criteria.

---

## Comment for Issue #159: What's Next for Issue #150

---

### Updated Gaps vs. Issue #150 (Now EKS-Based)

Following the Kubernetes pivot, here's the revised gaps list:

#### Infrastructure Gaps (Updated)
- ❌ No `terraform/aws/production/eks.tf` (cluster, node groups) — **IN PROGRESS**
- ❌ No `terraform/aws/production/rds.tf` (Aurora Serverless v2) — Needed
- ❌ No `terraform/aws/production/cdn.tf` (CloudFront, WAF, Route53) — Needed
- ❌ No ALB Ingress Controller deployed (for Kubernetes Ingress resources) — Needed
- ❌ No cluster autoscaler configured — Needed
- ❌ No production Terraform Cloud workspace (`lornu-ai-prod-aws`) linked — Needed

#### Kubernetes/Kustomize Gaps (Updated)
- ✅ `k8s/overlays/production/` exists with 3 replicas, pod anti-affinity
- ✅ Base manifests include security context, IRSA ServiceAccount, health probes
- ❌ Production-specific ConfigMap secrets (RESEND_API_KEY, etc.) — Needs manual creation in cluster

#### CI/CD Gaps (Updated)
- ❌ No production deploy job in GitHub Actions with manual approval gate
- ❌ `AWS_ACTIONS_PROD_ROLE_ARN` secret not in GitHub (requires separate production OIDC role)
- ❌ Workflow doesn't validate Terraform plan for production before apply

#### Deployment Validation
- ❌ No smoke test suite covering 70% of core agent pathways
- ❌ DNS not updated to point to EKS ALB (still on staging or dev)

#### Revised Recommended Next Steps

1. **Complete Production Terraform** (2–3 days):
   - Finish `terraform/aws/production/eks.tf` with cluster, node groups, add-ons
   - Add RDS Aurora Serverless v2 with encryption at rest
   - Add CloudFront distribution + AWS WAF (regional) + Route53 alias
   - Configure IRSA for pod access to Secrets Manager

2. **Deploy ALB Ingress Controller** (1 day):
   - Helm chart or Kustomize patch to deploy controller in kube-system
   - Update k8s/overlays/production/ingress.yaml to route traffic via ALB

3. **Update GitHub Actions** (1 day):
   - Add production job with `terraform apply` for `terraform/aws/production`
   - Require manual approval before production deploy
   - Extend to run smoke tests post-deploy

4. **Production Secrets & ConfigMaps** (1 day):
   - Create AWS Secrets Manager entries for RESEND_API_KEY, etc.
   - Link via IRSA or External Secrets Operator
   - OR manually create Kubernetes Secrets in the cluster

5. **Validate & DNS Cutover** (1 day):
   - Run smoke tests to confirm endpoints are healthy
   - Update Route53 A record to point to ALB DNS name
   - Monitor prod traffic for issues

#### Questions Before Proceeding
- [ ] Should production use On-Demand or Spot instances for cost?
- [ ] Do we need a separate production AWS account, or shared VPC with staging?
- [ ] Should we add pod disruption budgets (PDBs) for graceful drains?
- [ ] Any specific SLA/uptime targets that inform autoscaling policies?

**Reference**: See `docs/EKS_PIVOT_SUMMARY.md` for a full breakdown of what's changed and current status.

---
