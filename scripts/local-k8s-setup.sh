#!/bin/bash
# Local Kubernetes Setup for Lornu AI Testing
# Uses minikube with minimal resources to test builds before AWS deployment

set -e

echo "🚀 Setting up local Kubernetes environment for Lornu AI"

# Check prerequisites
command -v minikube >/dev/null 2>&1 || { echo "❌ minikube not found. Install: brew install minikube"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl not found. Install: brew install kubectl"; exit 1; }
command -v kustomize >/dev/null 2>&1 || { echo "❌ kustomize not found. Install: brew install kustomize"; exit 1; }

# Detect container runtime (prefer podman, fallback to docker)
if command -v podman >/dev/null 2>&1; then
    CONTAINER_RUNTIME="podman"
    DRIVER="podman"
    echo "🐳 Using Podman as container runtime"
else
    CONTAINER_RUNTIME="docker"
    DRIVER="docker"
    echo "🐳 Using Docker as container runtime"
fi

# Start minikube with minimal resources (saves $$)
echo "📦 Starting minikube cluster with $CONTAINER_RUNTIME..."
if ! minikube status >/dev/null 2>&1; then
    minikube start \
        --driver=$DRIVER \
        --cpus=2 \
        --memory=4096 \
        --disk-size=20g \
        --kubernetes-version=v1.28.0 \
        --container-runtime=$CONTAINER_RUNTIME
else
    echo "✅ Minikube already running"
fi

# Enable minikube registry addon (alternative to local registry)
echo "🔧 Configuring minikube..."
minikube addons enable registry
minikube addons enable ingress
minikube addons enable metrics-server

# Build image in minikube's container environment
echo "🐳 Building container image in minikube..."
eval $(minikube docker-env)
$CONTAINER_RUNTIME build -t lornu-ai:local -f Dockerfile .

echo ""
echo "✅ Local Kubernetes environment ready!"
echo ""
echo "📋 Next steps:"
echo "  1. Deploy to minikube:  ./scripts/local-k8s-deploy.sh"
echo "  2. Check status:        kubectl get pods"
echo "  3. View logs:           kubectl logs -l app.kubernetes.io/name=lornu-ai"
echo "  4. Port forward:        kubectl port-forward svc/lornu-ai 8080:8080"
echo "  5. Access app:          http://localhost:8080"
echo ""
echo "💡 Tips:"
echo "  - Use minikube dashboard for GUI"
echo "  - Use minikube tunnel to expose LoadBalancer services"
echo "  - Clean up with: minikube delete"
