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

This executes `kustomize build ../../k8s/overlays/dev | kubectl apply -f -`.

### Staging

The staging manifests use placeholder values that are dynamically replaced during CI/CD deployment. The CI/CD pipeline should use Kustomize's `edit set image` command to set the correct image before building:

```bash
cd k8s/overlays/staging
kustomize edit set image lornu-ai=${AWS_ECR_REGISTRY}/lornu-ai-staging:${GITHUB_SHA}
kustomize build . | kubectl apply -f -
```

This approach keeps the checked-in `kustomization.yaml` file clean and environment-agnostic, while allowing CI/CD to inject the correct registry and tag at deployment time.

## CI/CD Integration

The `.github/workflows/terraform-aws.yml` workflow includes steps to:
1. **Build and Push Docker Image**: Builds the multi-stage Docker image and pushes to AWS ECR.
2. **Setup Kustomize**: Installs the Kustomize CLI.
3. **Set Image**: Uses `kustomize edit set image` to configure the correct ECR registry and commit SHA.
4. **Build & Deploy**: Builds the final manifests and applies them to the EKS cluster.
