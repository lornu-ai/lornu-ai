#!/bin/bash
# Local Kubernetes setup for Lornu AI (minikube + podman preferred)
# Boots a small cluster and builds the local image inside it so we can deploy immediately.

set -euo pipefail

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

# Start minikube with minimal resources
echo "📦 Starting minikube cluster with $CONTAINER_RUNTIME..."
if ! minikube status >/dev/null 2>&1; then
    minikube start \
        --driver="$DRIVER" \
        --cpus=2 \
        --memory=4096 \
        --disk-size=20g

    # Set runtime if specifically docker
    if [ "$CONTAINER_RUNTIME" = "docker" ]; then
        minikube config set container-runtime docker
    fi
else
    echo "✅ Minikube already running"
fi

# Enable helpful addons
echo "🔧 Configuring minikube..."
minikube addons enable registry
minikube addons enable ingress
minikube addons enable metrics-server

# Build image inside the minikube runtime (works for podman or docker)
echo "🐳 Building container image in minikube..."
if [ "$CONTAINER_RUNTIME" = "podman" ]; then
    eval "$(minikube podman-env)"
else
    eval "$(minikube docker-env)"
fi
"$CONTAINER_RUNTIME" build -t lornu-ai:local -f Dockerfile .

echo ""
echo "✅ Local Kubernetes environment ready!"
echo ""
echo "📋 Next steps:"
echo "  1. Deploy manifests:    ./scripts/local-k8s-deploy.sh"
echo "  2. Run smoke tests:     ./scripts/local-k8s-test.sh"
echo "  3. Check status:        kubectl get pods"
echo "  4. View logs:           kubectl logs -l app.kubernetes.io/name=lornu-ai"
echo "  5. Port forward:        kubectl port-forward svc/lornu-ai 8080:8080"
echo ""
echo "💡 Tips:"
echo "  - minikube dashboard    # GUI"
echo "  - minikube tunnel       # exposes LoadBalancer"
echo "  - Clean up with:        ./scripts/local-k8s-cleanup.sh"
