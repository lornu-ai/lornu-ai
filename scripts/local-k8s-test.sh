#!/bin/bash
# Smoke-test Lornu AI deployment in local Kubernetes

set -euo pipefail

echo "🧪 Testing Lornu AI deployment..."

# Check if deployment exists
if ! kubectl get deployment -l app.kubernetes.io/name=lornu-ai --no-headers 2>/dev/null | grep -q lornu-ai; then
    echo "❌ Deployment not found. Run ./scripts/local-k8s-deploy.sh first"
    exit 1
fi

# Check pod status
echo "📊 Pod Status:"
kubectl get pods -l app.kubernetes.io/name=lornu-ai

# Get pod name
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=lornu-ai -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD_NAME" ]; then
    echo "❌ No pods found"
    exit 1
fi

echo ""
echo "🔍 Testing pod: $POD_NAME"
echo ""

# Test health endpoint
echo "🏥 Testing /api/health endpoint..."
HEALTH_RESPONSE=$(kubectl exec "$POD_NAME" -- curl -s http://localhost:8080/api/health || echo "FAILED")

if echo "$HEALTH_RESPONSE" | grep -q "ok"; then
    echo "✅ Health check passed: $HEALTH_RESPONSE"
else
    echo "❌ Health check failed: $HEALTH_RESPONSE"
    exit 1
fi

# Test frontend (check for HTML)
echo ""
echo "🌐 Testing frontend..."
FRONTEND_RESPONSE=$(kubectl exec "$POD_NAME" -- curl -s http://localhost:8080/ || echo "FAILED")

if echo "$FRONTEND_RESPONSE" | grep -q "<!DOCTYPE html>"; then
    echo "✅ Frontend serving correctly"
else
    echo "❌ Frontend not responding"
    echo "Response: $FRONTEND_RESPONSE"
    exit 1
fi

echo ""
echo "✅ All tests passed!"
echo ""
echo "📋 Ready to ship to AWS EKS via CI once images/manifests are pushed."
