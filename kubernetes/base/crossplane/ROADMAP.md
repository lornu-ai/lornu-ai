# Crossplane Setup Roadmap

This document outlines the step-by-step roadmap to get Crossplane up and running on your existing GKE cluster.

## Current Status

✅ **Completed:**
- Terraform code for Workload Identity binding (`terraform/gcp/crossplane.tf`)
- Kustomize bundle for Crossplane installation
- XGCPProject XRD and Composition for self-service project creation
- Documentation and guides

## Roadmap to Production

### Phase 1: Terraform Setup (Prerequisites)

**Status:** ⏳ Pending

**Steps:**

1. **Merge PR #464**
   - Review and merge the Crossplane setup PR
   - Contains all Terraform and Kustomize manifests

2. **Apply Terraform to create Workload Identity binding**
   ```bash
   # In Terraform Cloud workspace: gcp-lornu-ai
   # Or locally:
   cd terraform/gcp
   terraform init
   terraform plan
   terraform apply
   ```
   
   **This creates:**
   - `google_service_account_iam_member.crossplane_workload_identity`
   - Allows: `serviceAccount:gcp-lornu-ai.svc.id.goog[crossplane-system/provider-gcp-default]` → `lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com`

3. **Verify Workload Identity binding exists**
   ```bash
   gcloud iam service-accounts get-iam-policy \
     lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com \
     --project gcp-lornu-ai
   ```
   
   Should show the binding with `roles/iam.workloadIdentityUser`

### Phase 2: GKE Cluster Access

**Status:** ⏳ Pending

**Steps:**

1. **Get credentials for existing GKE cluster**
   ```bash
   gcloud container clusters get-credentials lornu-ai-gke \
     --region us-central1 \
     --project gcp-lornu-ai
   ```

2. **Verify cluster access**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Verify Workload Identity is enabled on cluster**
   ```bash
   gcloud container clusters describe lornu-ai-gke \
     --region us-central1 \
     --project gcp-lornu-ai \
     --format="value(workloadIdentityConfig.workloadPool)"
   ```
   
   Should output: `gcp-lornu-ai.svc.id.goog`

### Phase 3: Crossplane Installation

**Status:** ⏳ Pending

**Steps:**

1. **Update configuration values** (if needed)
   - Review `kubernetes/base/crossplane/xgcpproject-composition.yaml`
     - Replace `orgId: "123456789012"` with actual organization ID
   - Review `kubernetes/base/crossplane/provider-config.yaml`
     - Verify `projectID: gcp-lornu-ai` is correct

2. **Apply Crossplane bundle**
   ```bash
   kubectl apply -k kubernetes/base/crossplane/
   ```

3. **Wait for Crossplane Core to be ready**
   ```bash
   kubectl wait --for=condition=Ready pod -l app=crossplane -n crossplane-system --timeout=300s
   kubectl get pods -n crossplane-system
   ```

4. **Wait for GCP Providers to be healthy**
   ```bash
   # Check provider installation status
   kubectl get providers -n crossplane-system
   
   # Wait for each provider to be healthy (may take 2-5 minutes)
   kubectl wait --for=condition=Healthy provider/provider-gcp-resourcemanager -n crossplane-system --timeout=300s
   kubectl wait --for=condition=Healthy provider/provider-gcp-storage -n crossplane-system --timeout=300s
   kubectl wait --for=condition=Healthy provider/provider-gcp-compute -n crossplane-system --timeout=300s
   kubectl wait --for=condition=Healthy provider/provider-gcp-iam -n crossplane-system --timeout=300s
   ```

5. **Verify XRD and Composition are installed**
   ```bash
   kubectl get xrd xgcpprojects.lornu.ai
   kubectl get composition gcp-project-standard
   ```

### Phase 4: Test Project Creation

**Status:** ⏳ Pending

**Steps:**

1. **Create a test GCP project via Crossplane**
   ```yaml
   # test-project.yaml
   apiVersion: lornu.ai/v1alpha1
   kind: XGCPProject
   metadata:
     name: crossplane-test-project
   spec:
     projectName: "Crossplane Test Project"
     projectId: "crossplane-test-2024"  # Must be globally unique
     billingAccountId: "XXXXXX-XXXXXX-XXXXXX"  # Your billing account
     environment: "dev"
     description: "Test project for Crossplane setup"
   ```

2. **Apply the test project**
   ```bash
   kubectl apply -f test-project.yaml
   ```

3. **Monitor the creation**
   ```bash
   # Check the composite resource status
   kubectl get xgcpproject crossplane-test-project
   kubectl describe xgcpproject crossplane-test-project
   
   # Check the underlying GCP project resource
   kubectl get project crossplane-test-2024
   kubectl describe project crossplane-test-2024
   ```

4. **Verify project was created in GCP**
   ```bash
   gcloud projects describe crossplane-test-2024
   ```

5. **Cleanup test project** (if successful)
   ```bash
   kubectl delete xgcpproject crossplane-test-project
   # This will delete the GCP project via Crossplane
   ```

### Phase 5: Production Readiness

**Status:** ⏳ Pending

**Steps:**

1. **Verify Service Account has Project Creator role**
   - The `lornu-tfc-infra` SA needs `roles/resourcemanager.projectCreator` at org level
   - Check with:
     ```bash
     gcloud organizations get-iam-policy <ORG_ID> \
       --flatten="bindings[].members" \
       --filter="bindings.members:serviceAccount:lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com"
     ```

2. **Document actual values**
   - Update `xgcpproject-composition.yaml` with real organization ID
   - Document billing account IDs per environment

3. **Create example project requests**
   - Add examples for dev, staging, prod projects
   - Document required fields and validation rules

4. **Set up monitoring/alerting** (optional)
   - Monitor Crossplane pod health
   - Alert on provider failures
   - Track project creation metrics

## Dependencies Checklist

Before starting, ensure:

- [x] Existing GKE cluster (`lornu-ai-gke`) is running
- [x] Workload Identity is enabled on the cluster
- [ ] Terraform Cloud SA (`lornu-tfc-infra`) has Project Creator role at org level
- [ ] Terraform Cloud SA has billing account user role
- [ ] `kubectl` is configured for the GKE cluster
- [ ] You have permissions to create IAM bindings in the project

## Quick Start Commands

Once PR is merged and Terraform is applied:

```bash
# 1. Get cluster credentials
gcloud container clusters get-credentials lornu-ai-gke \
  --region us-central1 \
  --project gcp-lornu-ai

# 2. Install Crossplane
kubectl apply -k kubernetes/base/crossplane/

# 3. Wait for providers (this takes a few minutes)
kubectl wait --for=condition=Healthy provider/provider-gcp-resourcemanager \
  -n crossplane-system --timeout=300s

# 4. Create a test project
kubectl apply -f test-project.yaml

# 5. Check status
kubectl get xgcpproject test-project
```

## Troubleshooting

See [BOOTSTRAP_GUIDE.md](./BOOTSTRAP_GUIDE.md) for detailed troubleshooting steps.

Common issues:
- Provider not healthy: Check logs with `kubectl logs -n crossplane-system`
- Workload Identity issues: Verify IAM binding exists
- Project creation fails: Check Service Account has Project Creator role

## Next Steps After Setup

Once Crossplane is working:

1. **Create more Compositions** for:
   - VPCs
   - GKE clusters
   - Cloud Storage buckets
   - Service accounts with IAM bindings

2. **Add default resources** to project Composition:
   - Default VPC
   - Default IAM bindings
   - Default Cloud Storage bucket

3. **Multi-project management**:
   - Use Crossplane to manage projects across organization
   - Create project templates per environment

