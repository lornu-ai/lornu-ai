#!/bin/bash
# Deploy Lornu AI to local Kubernetes (k3s via k3d)

set -euo pipefail

echo "🚀 Deploying Lornu AI to local Kubernetes..."

# Detect container runtime
if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
else
    CONTAINER_RUNTIME="docker"
fi

CLUSTER_NAME="lornu-dev"
REGISTRY_NAME="lornu-registry.localhost"
REGISTRY_PORT="5000"
REGISTRY_HOST="${REGISTRY_NAME}:${REGISTRY_PORT}"
IMAGE_TAG="${REGISTRY_HOST}/lornu-ai:local"

if ! kubectl config get-contexts "k3d-${CLUSTER_NAME}" >/dev/null 2>&1; then
    echo "❌ k3d cluster context not found. Run ./scripts/local-k8s-setup.sh first"
    exit 1
fi

kubectl config use-context "k3d-${CLUSTER_NAME}"

# Ensure image exists
if ! "$CONTAINER_RUNTIME" images | grep -q "lornu-registry.localhost:5000/lornu-ai.*local"; then
    echo "⚠️  Image not found. Building..."
    "$CONTAINER_RUNTIME" build -t "${IMAGE_TAG}" -f Dockerfile .
    "$CONTAINER_RUNTIME" push "${IMAGE_TAG}"
fi

# Apply kustomize configuration
echo "📦 Applying Kubernetes manifests..."
kustomize build k8s/overlays/dev | kubectl apply -f -

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment -l app.kubernetes.io/name=lornu-ai

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get pods -l app.kubernetes.io/name=lornu-ai
SERVICE_NAME=$(kubectl get svc -l app=lornu-ai -o jsonpath='{.items[0].metadata.name}')
echo ""
echo "📋 Next steps:"
echo "  Run smoke tests: ./scripts/local-k8s-test.sh"
echo "  View logs:       kubectl logs -f -l app.kubernetes.io/name=lornu-ai"
echo "  Port forward:    kubectl port-forward svc/${SERVICE_NAME} 8080:80"
echo "  Visit:           http://localhost:8080"
echo ""
echo "🔍 Debug commands:"
echo "  kubectl describe pod -l app.kubernetes.io/name=lornu-ai"
echo "  kubectl get events --sort-by=.metadata.creationTimestamp"
