#!/bin/bash
# Deploy Lornu AI to local Kubernetes (minikube)

set -euo pipefail

echo "🚀 Deploying Lornu AI to local Kubernetes..."

# Detect container runtime
if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
else
    CONTAINER_RUNTIME="docker"
fi

# Use minikube's container environment for image lookup/build
eval "$(minikube docker-env)"

# Ensure image exists
if ! "$CONTAINER_RUNTIME" images | grep -q "lornu-ai.*local"; then
    echo "⚠️  Image not found. Building..."
    "$CONTAINER_RUNTIME" build -t lornu-ai:local -f Dockerfile .
fi

# Apply kustomize configuration
echo "📦 Applying Kubernetes manifests..."
kustomize build k8s/overlays/dev | kubectl apply -f -

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/lornu-ai

# Show status
echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get pods -l app.kubernetes.io/name=lornu-ai
echo ""
echo "📋 Next steps:"
echo "  Run smoke tests: ./scripts/local-k8s-test.sh"
echo "  View logs:       kubectl logs -f -l app.kubernetes.io/name=lornu-ai"
echo "  Port forward:    kubectl port-forward svc/lornu-ai 8080:8080"
echo "  Visit:           http://localhost:8080"
echo ""
echo "🔍 Debug commands:"
echo "  kubectl describe pod -l app.kubernetes.io/name=lornu-ai"
echo "  kubectl get events --sort-by=.metadata.creationTimestamp"
