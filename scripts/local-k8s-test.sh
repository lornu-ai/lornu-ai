#!/bin/bash

# Script to test the local Kubernetes deployment (Minikube + Podman)
# Ensures the service is reachable and returning a 200 OK.

set -e

NAMESPACE="lornu-dev"
SERVICE_NAME="lornu-ai"
MAX_RETRIES=30
RETRY_INTERVAL=5

echo "🔍 Starting local GKE-style smoke tests..."

# 1. Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    echo "❌ Error: Namespace '$NAMESPACE' not found. Run ./scripts/local-k8s-deploy.sh first."
    exit 1
fi

# 2. Wait for deployment to be ready
echo "⏳ Waiting for deployment/$SERVICE_NAME to be ready in $NAMESPACE..."
kubectl rollout status deployment/"$SERVICE_NAME" -n "$NAMESPACE" --timeout=120s

# 3. Get Pod logs to check for startup errors
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=lornu-ai -o jsonpath="{.items[0].metadata.name}")
echo "📋 Checking logs for pod: $POD_NAME"
kubectl logs "$POD_NAME" -n "$NAMESPACE" --tail=20

# 4. Perform a port-forward and test connectivity
echo "🌐 Testing service connectivity via port-forward..."
TEMP_PORT=18080

# Start port-forward in background
kubectl port-forward svc/"$SERVICE_NAME" -n "$NAMESPACE" $TEMP_PORT:80 > /dev/null 2>&1 &
PF_PID=$!

# Ensure cleanup on exit
trap "kill $PF_PID" EXIT

# Wait a moment for port-forward to establish
sleep 3

# Attempt to connect
count=0
success=false
while [ $count -lt $MAX_RETRIES ]; do
    if curl -s -f "http://localhost:$TEMP_PORT" > /dev/null; then
        echo "✅ Success: Service is reachable and returned HTTP 200!"
        success=true
        break
    fi
    echo "🌕 Service not ready yet... (Attempt $((count+1))/$MAX_RETRIES)"
    count=$((count+1))
    sleep $RETRY_INTERVAL
done

if [ "$success" = false ]; then
    echo "❌ Error: Service failed to respond after $MAX_RETRIES attempts."
    exit 1
fi

echo "🚀 Smoke tests passed successfully!"
