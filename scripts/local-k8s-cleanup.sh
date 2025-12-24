#!/bin/bash
# Cleanup local Kubernetes resources

set -e

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

# Clean up docker images (optional)
read -p "🐳 Remove Docker image? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    eval $(minikube docker-env)
    docker rmi lornu-ai:local || true
fi

# Stop minikube (optional)
read -p "⏹️  Stop minikube? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    minikube stop
fi

echo ""
echo "✅ Cleanup complete!"
