# Crossplane Control Plane Setup

This directory contains Kustomize manifests for installing Crossplane on the GKE Autopilot cluster created by Terraform.

## Architecture

```
Terraform → Creates GKE Cluster + Workload Identity Binding
    ↓
Kustomize → Installs Crossplane on the cluster
    ↓
Crossplane → Manages GCP resources using Workload Identity
```

## Prerequisites

1. **GKE Cluster Created**: The cluster must be created via Terraform (`terraform/gcp/crossplane.tf`)
2. **Workload Identity Binding**: The IAM binding must exist (created by Terraform)
3. **kubectl Access**: Configure kubectl to access the GKE cluster

## Setup Steps

### 1. Configure kubectl

After Terraform creates the cluster, configure kubectl:

```bash
gcloud container clusters get-credentials crossplane-control-plane \
  --region <region> \
  --project gcp-lornu-ai
```

### 2. Apply Crossplane

Deploy Crossplane using Kustomize:

```bash
kubectl apply -k kubernetes/base/crossplane/
```

### 3. Verify Installation

Check that Crossplane is running:

```bash
kubectl get pods -n crossplane-system
kubectl get providers -n crossplane-system
```

### 4. Wait for Providers to be Ready

The GCP providers need to download and install:

```bash
kubectl wait --for=condition=Healthy provider/provider-gcp-storage -n crossplane-system --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-gcp-compute -n crossplane-system --timeout=300s
kubectl wait --for=condition=Healthy provider/provider-gcp-iam -n crossplane-system --timeout=300s
```

## Provider Configuration

The `provider-config.yaml` uses **WebIdentity** (Workload Identity) for authentication. This is configured to use the Kubernetes Service Account:

- **Namespace**: `crossplane-system`
- **Service Account**: `provider-gcp-default`
- **GCP Service Account**: `lornu-tfc-infra@gcp-lornu-ai.iam.gserviceaccount.com` (from Terraform)

The Workload Identity binding is created by Terraform in `terraform/gcp/crossplane.tf`.

## Customization

To customize the provider configuration (e.g., different project ID), create an overlay:

```yaml
# kubernetes/overlays/crossplane-custom/project-id-patch.yaml
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
  namespace: crossplane-system
spec:
  projectID: your-custom-project-id
```

## Next Steps

Once Crossplane is installed and providers are healthy, you can:

1. Create **Compositions** for standard GCP resource patterns
2. Define **Composite Resources** for developers to use
3. Start managing GCP resources via Crossplane instead of direct Terraform

## References

- [Crossplane Documentation](https://docs.crossplane.io/)
- [GCP Provider Documentation](https://marketplace.upbound.io/providers/upbound/provider-gcp-storage/)
- [Workload Identity with Crossplane](https://docs.crossplane.io/latest/concepts/pipeline#workload-identity)

