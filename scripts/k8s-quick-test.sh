#!/bin/bash

# Quick Kubernetes test script
# Uses ConfigMap for input data (works reliably on Docker Desktop)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Quick Kubernetes Test"
echo "========================"
echo ""

# Check kubectl
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes"
    echo "   Enable Kubernetes in Docker Desktop first"
    exit 1
fi

# Build image if needed
if ! docker image inspect algosvc:v0.1.0 &> /dev/null; then
    echo "📦 Building Docker image..."
    cd "$PROJECT_DIR"
    docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .
    echo ""
fi

# Clean up any existing job
echo "🧹 Cleaning up any existing jobs..."
kubectl delete job algosvc-job-configmap 2>/dev/null || true
kubectl delete configmap algosvc-input-data 2>/dev/null || true
sleep 2

# Deploy
echo "📝 Deploying job with ConfigMap..."
kubectl apply -f "$PROJECT_DIR/k8s/job-configmap.yaml"

echo ""
echo "⏳ Waiting for job to complete..."
kubectl wait --for=condition=complete job/algosvc-job-configmap --timeout=120s || {
    echo "❌ Job did not complete"
    echo ""
    echo "📋 Pod status:"
    kubectl get pods -l app=algosvc
    echo ""
    echo "📋 Logs:"
    kubectl logs -l app=algosvc --tail=50
    exit 1
}

echo ""
echo "✅ Job completed!"
echo ""

# Show logs
echo "📋 Job logs:"
kubectl logs -l app=algosvc
echo ""

# Get output from pod
echo "📄 Output files:"
POD_NAME=$(kubectl get pods -l app=algosvc -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$POD_NAME" ]; then
    echo ""
    echo "📊 Extracting output files from pod..."
    kubectl exec "$POD_NAME" -- sh -c "ls -la /rundata/output/" 2>/dev/null || true
    echo ""
    echo "📄 Sample output content:"
    kubectl exec "$POD_NAME" -- cat /rundata/output/sample.json 2>/dev/null | python3 -m json.tool 2>/dev/null || \
    kubectl exec "$POD_NAME" -- cat /rundata/output/sample.json 2>/dev/null || echo "   (could not retrieve)"
fi

echo ""
echo "🧹 To clean up:"
echo "   kubectl delete job algosvc-job-configmap"
echo "   kubectl delete configmap algosvc-input-data"

