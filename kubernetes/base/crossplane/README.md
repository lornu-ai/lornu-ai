# Crossplane GCP Bootstrap Bundle

This directory contains the complete Kustomize bundle for installing Crossplane and enabling self-service GCP project creation.

## Quick Start

See **[BOOTSTRAP_GUIDE.md](./BOOTSTRAP_GUIDE.md)** for the complete step-by-step guide.

## Bundle Contents

- **`kustomization.yaml`**: Main bundle that installs Crossplane core, providers, and custom APIs
- **`xgcpproject-xrd.yaml`**: Composite Resource Definition (XRD) - the interface developers use
- **`xgcpproject-composition.yaml`**: Composition - the implementation that creates GCP projects
- **`provider-config.yaml`**: GCP provider configuration using Workload Identity
- **`BOOTSTRAP_GUIDE.md`**: Complete setup and usage guide

## Architecture

```
Terraform → Creates GKE Cluster + Workload Identity Binding (the "Egg")
    ↓
Kustomize → Deploys Crossplane + Custom Project API (the "Chicken")
    ↓
Developer → Creates XGCPProject YAML (5 lines) → New GCP Project
```

## Installation

```bash
# 1. Apply the bundle
kubectl apply -k kubernetes/base/crossplane/

# 2. Wait for providers to be healthy
kubectl wait --for=condition=Healthy provider/provider-gcp-resourcemanager -n crossplane-system --timeout=300s
```

## Usage Example

```yaml
apiVersion: lornu.ai/v1alpha1
kind: XGCPProject
metadata:
  name: my-awesome-app
spec:
  projectName: "Awesome App Production"
  projectId: "awesome-app-prod-2024"
  billingAccountId: "XXXXXX-XXXXXX-XXXXXX"
  environment: "prod"
```

## Key Features

- ✅ **Self-Service**: Developers create projects with simple YAML
- ✅ **Drift Correction**: Automatic reversion of manual changes
- ✅ **Workload Identity**: Secure authentication without static keys
- ✅ **Versioned APIs**: Update implementation without changing developer YAML

For detailed instructions, see [BOOTSTRAP_GUIDE.md](./BOOTSTRAP_GUIDE.md).

