#!/bin/bash
# Deploy Lornu AI to local Kubernetes cluster

set -e

echo "🚀 Deploying Lornu AI to local Kubernetes..."

# Ensure we're using minikube's docker environment
eval $(minikube docker-env)

# Check if image exists
if ! docker images | grep -q "lornu-ai.*local"; then
    echo "⚠️  Image not found. Building..."
    docker build -t lornu-ai:local -f Dockerfile .
fi

# Apply kustomize configuration
echo "📦 Applying Kubernetes manifests..."
kustomize build k8s/overlays/dev | kubectl apply -f -

# Wait for deployment
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/lornu-ai

# Get pod status
echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get pods -l app.kubernetes.io/name=lornu-ai
echo ""
echo "📋 Next steps:"
echo "  View logs:    kubectl logs -f -l app.kubernetes.io/name=lornu-ai"
echo "  Port forward: kubectl port-forward svc/lornu-ai 8080:8080"
echo "  Then visit:   http://localhost:8080"
echo ""
echo "🔍 Debug commands:"
echo "  kubectl describe pod -l app.kubernetes.io/name=lornu-ai"
echo "  kubectl get events --sort-by=.metadata.creationTimestamp"
