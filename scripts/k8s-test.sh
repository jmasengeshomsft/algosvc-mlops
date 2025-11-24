#!/bin/bash

# Kubernetes testing script for Docker Desktop
# This script helps test the algosvc batch job on Kubernetes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Kubernetes Testing Script for AlgoSvc"
echo "========================================"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    echo "   Please install kubectl: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Check if Kubernetes is running
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    echo "   Make sure Docker Desktop Kubernetes is enabled and running"
    exit 1
fi

echo "✅ Kubernetes cluster is accessible"
echo ""

# Check if Docker image exists locally
if ! docker image inspect algosvc:v0.1.0 &> /dev/null; then
    echo "📦 Docker image algosvc:v0.1.0 not found locally"
    echo "   Building image..."
    cd "$PROJECT_DIR"
    docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .
    echo ""
fi

echo "✅ Docker image ready: algosvc:v0.1.0"
echo ""

# Ensure input directory has files
if [ ! -d "$PROJECT_DIR/rundata/input" ] || [ -z "$(ls -A $PROJECT_DIR/rundata/input/*.json 2>/dev/null)" ]; then
    echo "⚠️  No input files found. Creating sample input..."
    mkdir -p "$PROJECT_DIR/rundata/input"
    cat > "$PROJECT_DIR/rundata/input/sample.json" <<EOF
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
EOF
    echo "✅ Created sample.json"
    echo ""
fi

# Ensure output directory exists
mkdir -p "$PROJECT_DIR/rundata/output"

echo "📋 Input files:"
ls -1 "$PROJECT_DIR/rundata/input"/*.json 2>/dev/null || echo "   (none)"
echo ""

# Ask user which method to use
echo "Choose deployment method:"
echo "1) hostPath volumes (simpler, for testing)"
echo "2) PersistentVolumeClaims (production-like)"
read -p "Enter choice [1 or 2]: " choice

case $choice in
    1)
        echo ""
        echo "📝 Deploying with hostPath volumes..."
        kubectl apply -f "$PROJECT_DIR/k8s/job-test.yaml"
        JOB_NAME="algosvc-job-test"
        ;;
    2)
        echo ""
        echo "📝 Deploying with PersistentVolumeClaims..."
        
        # First, populate the input PVC
        echo "   Setting up input data..."
        kubectl apply -f "$PROJECT_DIR/k8s/deployment.yaml"
        
        # Create a helper pod to copy data to PVC
        echo "   Copying input files to PVC..."
        kubectl run algosvc-copy-input --rm -i --restart=Never \
            --image=busybox \
            --overrides='
{
  "spec": {
    "containers": [{
      "name": "algosvc-copy-input",
      "image": "busybox",
      "command": ["sh", "-c"],
      "args": ["echo Copying files..."],
      "volumeMounts": [{
        "name": "input-data",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "input-data",
      "hostPath": {
        "path": "'"$PROJECT_DIR/rundata/input"'",
        "type": "Directory"
      }
    }]
  }
}' || true
        
        # For PVC approach, we need to use a different method
        # Let's create a ConfigMap with the input data instead
        echo "   Note: For PVC testing, you may need to manually populate the PVC"
        echo "   or use a different approach. Using hostPath for now..."
        kubectl apply -f "$PROJECT_DIR/k8s/job-test.yaml"
        JOB_NAME="algosvc-job-test"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "⏳ Waiting for job to start..."
kubectl wait --for=condition=Ready pod -l app=algosvc --timeout=60s || true

echo ""
echo "📊 Job status:"
kubectl get jobs
echo ""

echo "📋 Pod status:"
kubectl get pods -l app=algosvc
echo ""

# Wait for job completion
echo ""
echo "⏳ Waiting for job to complete..."
kubectl wait --for=condition=complete job/$JOB_NAME --timeout=300s || {
    echo "❌ Job did not complete in time"
    echo ""
    echo "📋 Pod logs:"
    kubectl logs -l app=algosvc --tail=50
    exit 1
}

echo ""
echo "✅ Job completed successfully!"
echo ""

# Show logs
echo "📋 Job logs:"
kubectl logs -l app=algosvc
echo ""

# Check output files
echo "📁 Output files:"
if [ -d "$PROJECT_DIR/rundata/output" ]; then
    ls -lh "$PROJECT_DIR/rundata/output"/*.json 2>/dev/null || echo "   (no output files found)"
    echo ""
    echo "📄 Sample output:"
    if [ -f "$PROJECT_DIR/rundata/output/sample.json" ]; then
        cat "$PROJECT_DIR/rundata/output/sample.json" | python3 -m json.tool 2>/dev/null || \
        cat "$PROJECT_DIR/rundata/output/sample.json"
    fi
else
    echo "   Output directory not found"
fi

echo ""
echo "🧹 To clean up:"
echo "   kubectl delete job $JOB_NAME"
echo "   kubectl delete pvc algosvc-input-pvc algosvc-output-pvc 2>/dev/null || true"

