#!/bin/bash
# Local Kubernetes setup for Lornu AI (k3s via k3d + podman preferred)
# Boots a small cluster, builds the local image, and pushes it to the local registry.

set -euo pipefail

echo "🚀 Setting up local Kubernetes environment for Lornu AI (k3s)"

# Check prerequisites
command -v k3d >/dev/null 2>&1 || { echo "❌ k3d not found. Install: brew install k3d"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Install: brew install kubectl"; exit 1; }
command -v kustomize >/dev/null 2>&1 || { echo "❌ kustomize not found. Install: brew install kustomize"; exit 1; }

# Detect container runtime (prefer podman, fallback to docker)
if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
    echo "🐳 Using Podman as container runtime"
else
    CONTAINER_RUNTIME="docker"
    echo "⚠️  Podman not found. Falling back to Docker"
fi

CLUSTER_NAME="lornu-dev"
REGISTRY_NAME="lornu-registry.localhost"
REGISTRY_PORT="5000"
REGISTRY_HOST="${REGISTRY_NAME}:${REGISTRY_PORT}"
IMAGE_TAG="${REGISTRY_HOST}/lornu-ai:local"

# Create registry if missing
if ! k3d registry list | awk 'NR>1 {print $1}' | grep -q "^${REGISTRY_NAME}$"; then
    echo "📦 Creating local registry ${REGISTRY_NAME}..."
    k3d registry create "${REGISTRY_NAME}" --port "${REGISTRY_PORT}"
else
    echo "✅ Local registry already exists"
fi

# Create cluster if missing
if ! k3d cluster list | awk 'NR>1 {print $1}' | grep -q "^${CLUSTER_NAME}$"; then
    echo "📦 Creating k3d cluster ${CLUSTER_NAME}..."
    k3d cluster create "${CLUSTER_NAME}" \
        --agents 1 \
        --servers 1 \
        --registry-use "k3d-${REGISTRY_NAME}:${REGISTRY_PORT}"
else
    echo "✅ k3d cluster already exists"
fi

kubectl config use-context "k3d-${CLUSTER_NAME}"

# Build and push image to local registry
echo "🐳 Building container image..."
"$CONTAINER_RUNTIME" build -t "${IMAGE_TAG}" -f Dockerfile .
echo "📦 Pushing image to local registry..."
"$CONTAINER_RUNTIME" push "${IMAGE_TAG}"

echo ""
echo "✅ Local Kubernetes environment ready!"
echo ""
echo "📋 Next steps:"
echo "  1. Deploy manifests:    ./scripts/local-k8s-deploy.sh"
echo "  2. Run smoke tests:     ./scripts/local-k8s-test.sh"
echo "  3. Check status:        kubectl get pods"
echo "  4. View logs:           kubectl logs -l app.kubernetes.io/name=lornu-ai"
echo "  5. Port forward:        kubectl port-forward svc/dev-lornu-ai 8080:80"
echo ""
echo "💡 Tips:"
echo "  - k3d cluster list      # clusters"
echo "  - k3d registry list     # registries"
echo "  - Clean up with:        ./scripts/local-k8s-cleanup.sh"
