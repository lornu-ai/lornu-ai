# Crossplane GCP Bootstrap Guide

This guide walks through the complete "chicken and egg" setup for using Crossplane to manage GCP resources.

## Architecture Overview

```
Terraform → Creates GKE Cluster + Workload Identity Binding (the "Egg")
    ↓
Kustomize → Deploys Crossplane + Custom Project API (the "Chicken")
    ↓
Developer → Creates XGCPProject YAML (5 lines) → New GCP Project
```

## Prerequisites

- **Organization ID**: Your GCP organization numeric ID (e.g., `123456789012`)
- **Seed Project**: The bootstrap project (e.g., `gcp-lornu-ai`)
- **Service Account**: Terraform Cloud SA with Project Creator role at org level
- **Billing Account ID**: Format `XXXXXX-XXXXXX-XXXXXX`

## Step 1: Terraform - Build the "Egg"

Terraform creates the GKE Autopilot cluster and the Workload Identity bridge.

### Apply Terraform

```bash
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

This creates:
- VPC and subnet for the control plane cluster
- GKE Autopilot cluster with Workload Identity enabled
- Workload Identity binding: `crossplane-system/provider-gcp-default` → `lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com`

### Get Cluster Credentials

```bash
gcloud container clusters get-credentials crossplane-control-plane \
  --region us-central1 \
  --project gcp-lornu-ai
```

## Step 2: Kustomize - Deploy the "Chicken"

Deploy Crossplane and the custom GCP Project API.

### Update Configuration

Before applying, update these values in the files:

1. **`xgcpproject-composition.yaml`**: Replace `orgId: "123456789012"` with your actual organization ID
2. **`provider-config.yaml`**: Replace `projectID: gcp-lornu-ai` with your seed project ID

### Apply the Bundle

```bash
kubectl apply -k kubernetes/base/crossplane/
```

This installs:
- Crossplane Core (v1.14.0)
- GCP Providers (resourcemanager, storage, compute, IAM)
- Custom XRD: `XGCPProject` (the interface)
- Composition: `gcp-project-standard` (the implementation)
- ProviderConfig: `default` (WebIdentity connection)

### Verify Installation

```bash
# Check Crossplane pods
kubectl get pods -n crossplane-system

# Check providers are healthy
kubectl get providers -n crossplane-system

# Wait for providers to be ready
kubectl wait --for=condition=Healthy provider/provider-gcp-resourcemanager -n crossplane-system --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-gcp-storage -n crossplane-system --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-gcp-compute -n crossplane-system --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-gcp-iam -n crossplane-system --timeout=300s

# Check XRD is installed
kubectl get xrd xgcpprojects.lornu.ai

# Check Composition is installed
kubectl get composition gcp-project-standard
```

## Step 3: Developer Usage - Create a GCP Project

Now developers can create GCP projects with a simple 5-line YAML file.

### Example: Create a New Project

```yaml
# my-app-project.yaml
apiVersion: lornu.ai/v1alpha1
kind: XGCPProject
metadata:
  name: my-awesome-app
spec:
  projectName: "Awesome App Production"
  projectId: "awesome-app-prod-2024"  # Must be globally unique
  billingAccountId: "XXXXXX-XXXXXX-XXXXXX"  # Your billing account
  environment: "prod"
  description: "Production environment for Awesome App"
```

### Apply the Project

```bash
kubectl apply -f my-app-project.yaml
```

### Check Status

```bash
# Check the composite resource
kubectl get xgcpproject my-awesome-app

# Check the underlying GCP project
kubectl get project awesome-app-prod-2024

# Get connection details
kubectl get secret my-awesome-app -o yaml
```

## How It Works

1. **Developer creates XGCPProject**: Simple YAML with project details
2. **Crossplane reads the Composition**: Maps the simple fields to actual GCP resources
3. **GCP Provider creates the Project**: Uses Workload Identity to authenticate
4. **Drift Detection**: If someone manually changes the project, Crossplane reverts it

## Benefits Over Terraform Modules

- ✅ **Self-Service**: Developers stay in Kubernetes, no Terraform knowledge needed
- ✅ **Drift Correction**: Automatic reversion of manual changes
- ✅ **Versioned APIs**: Update the Composition without changing developer YAML
- ✅ **No Static Keys**: Uses Workload Identity for secure authentication

## Troubleshooting

### Provider Not Healthy

```bash
# Check provider logs
kubectl logs -n crossplane-system -l pkg.crossplane.io/provider=provider-gcp-resourcemanager

# Check for authentication errors
kubectl describe provider provider-gcp-resourcemanager -n crossplane-system
```

### Workload Identity Issues

Verify the IAM binding exists:

```bash
gcloud iam service-accounts get-iam-policy lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com \
  --project gcp-lornu-ai
```

Should show:
```
member: serviceAccount:gcp-lornu-ai.svc.id.goog[crossplane-system/provider-gcp-default]
role: roles/iam.workloadIdentityUser
```

### Project Creation Fails

Check the XGCPProject status:

```bash
kubectl describe xgcpproject my-awesome-app
```

Common issues:
- Project ID already exists (must be globally unique)
- Invalid billing account ID
- Missing organization permissions

## Next Steps

Once this is working, you can:

1. **Create More Compositions**: For VPCs, GKE clusters, Cloud Storage buckets, etc.
2. **Add Default Resources**: Modify the Composition to automatically create a VPC or IAM bindings
3. **Multi-Project Management**: Use Crossplane to manage projects across your organization

## References

- [Crossplane Documentation](https://docs.crossplane.io/)
- [GCP Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-gcp-resourcemanager/)
- [Composition Guide](https://docs.crossplane.io/latest/concepts/composition)
- [Workload Identity with Crossplane](https://docs.crossplane.io/latest/concepts/pipeline#workload-identity)

