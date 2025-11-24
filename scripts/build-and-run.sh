#!/bin/bash

# Build and run the algosvc batch job locally
# This script should be run from the WSL Ubuntu terminal

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🔨 Building algosvc container..."

cd "$PROJECT_DIR"

# Build the Docker image
echo "📦 Building Docker image..."
docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .

echo "✅ Build complete!"
echo ""

# Create input/output directories if they don't exist
mkdir -p rundata/input rundata/output

# Create a sample input file if none exists
if [ ! -f "rundata/input/sample.json" ]; then
    echo "📝 Creating sample input file..."
    cat > rundata/input/sample.json <<EOF
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
EOF
fi

echo "🚀 Running batch job..."
echo "   Input:  rundata/input/"
echo "   Output: rundata/output/"
echo ""

# Run the container as a batch job
docker run --rm \
  -v "$PROJECT_DIR/rundata/input:/rundata/input:ro" \
  -v "$PROJECT_DIR/rundata/output:/rundata/output" \
  algosvc:v0.1.0

echo ""
echo "✅ Job completed! Check rundata/output/ for results."