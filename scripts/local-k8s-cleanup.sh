#!/bin/bash
# Cleanup local Kubernetes resources

set -euo pipefail

echo "🧹 Cleaning up local Kubernetes resources..."

# Delete deployment
if kubectl get deployment lornu-ai >/dev/null 2>&1; then
    echo "🗑️  Deleting deployment..."
    kubectl delete deployment lornu-ai
fi

# Delete service
if kubectl get service lornu-ai >/dev/null 2>&1; then
    echo "🗑️  Deleting service..."
    kubectl delete service lornu-ai
fi

# Delete configmap
if kubectl get configmap lornu-ai-config >/dev/null 2>&1; then
    echo "🗑️  Deleting configmap..."
    kubectl delete configmap lornu-ai-config
fi

# Clean up local image (optional, supports podman or docker)
read -p "🐳 Remove local image lornu-ai:local? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v podman >/dev/null 2>&1; then
        CONTAINER_RUNTIME="podman"
    else
        CONTAINER_RUNTIME="docker"
    fi
    eval "$(minikube docker-env)"
    "$CONTAINER_RUNTIME" rmi lornu-ai:local || true
fi

# Stop minikube (optional)
read -p "⏹️  Stop minikube? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube stop
fi

echo ""
echo "✅ Cleanup complete!"
