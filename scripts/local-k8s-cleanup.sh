#!/bin/bash
# Cleanup local Kubernetes resources

set -euo pipefail

echo "🧹 Cleaning up local Kubernetes resources..."

# Delete deployment
if kubectl get deployment -l app.kubernetes.io/name=lornu-ai >/dev/null 2>&1; then
    echo "🗑️  Deleting deployment..."
    kubectl delete deployment -l app.kubernetes.io/name=lornu-ai
fi

# Delete service
if kubectl get service -l app=lornu-ai >/dev/null 2>&1; then
    echo "🗑️  Deleting service..."
    kubectl delete service -l app=lornu-ai
fi

# Delete configmaps (dev prefix may be applied)
kubectl delete configmap dev-lornu-ai-config >/dev/null 2>&1 || true
kubectl delete configmap lornu-ai-config >/dev/null 2>&1 || true

# Clean up local image (optional, supports podman or docker)
read -p "🐳 Remove local image lornu-ai:local? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
else
    CONTAINER_RUNTIME="docker"
fi
"$CONTAINER_RUNTIME" rmi lornu-registry.localhost:5000/lornu-ai:local || true
fi

# Delete k3d cluster/registry (optional)
read -p "🧹 Delete k3d cluster/registry? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    k3d cluster delete lornu-dev || true
    k3d registry delete lornu-registry.localhost || true
fi

echo ""
echo "✅ Cleanup complete!"
