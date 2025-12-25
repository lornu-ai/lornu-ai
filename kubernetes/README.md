# Kubernetes Configuration with Kustomize

This directory contains the Kubernetes manifests for the Lornu AI application, managed with Kustomize to support environment-specific configurations.

## Structure

- `base/`: Contains the environment-agnostic base manifests.
  - `deployment.yaml`: Defines the Lornu AI application deployment with 2 replicas.
    - **Resources**: Container resource requests of 256Mi memory / 250m CPU, with limits of 512Mi memory / 500m CPU.
  - `service.yaml`: Exposes the application via a ClusterIP service.
  - `configmap.yaml`: Provides a base configuration with `LOG_LEVEL: "info"` and `ENVIRONMENT: "base"`.
  - `kustomization.yaml`: Defines the base resources and common labels.

- `overlays/`: Contains environment-specific overlays.
  - `dev/`: Configuration for local development.
    - **Image**: `localhost:5000/lornu-ai:dev` (local registry)
    - **Replicas**: 1
    - **Resources**: Requests and limits of 256Mi memory / 250m CPU.
    - **Logging**: `DEBUG`
  - `staging/`: Configuration for the AWS staging environment.
    - **Image**: ECR registry (substituted in CI/CD)
    - **Replicas**: 3
    - **Resources**: Requests 512Mi memory / 500m CPU; limits 1Gi memory / 1000m CPU.
    - **Logging**: `INFO`

## Usage

To apply the configuration for a specific environment, use `kustomize build` with the appropriate overlay.

### Local Development

To deploy the application to a local Kubernetes cluster (e.g., Kind, K3s), run the following command from the `apps/web` directory:

```bash
bun run dev:k8s
```

This executes `kustomize build ../../kubernetes/overlays/dev | kubectl apply -f -`.

### Staging

The staging manifests are built and applied automatically by the CI/CD pipeline in `.github/workflows/terraform.yml` when changes are pushed to the `develop` branch.

## CI/CD Integration

The `.github/workflows/terraform.yml` workflow includes steps to:
1. **Setup Kustomize**: Installs the Kustomize CLI.
2. **Build Staging Manifests**: Substitutes the `<AWS_ECR_REGISTRY>` placeholder with the actual ECR registry and builds the final manifests.
3. **Deploy to EKS**: (Currently commented out) Applies the generated manifests to the EKS cluster.
