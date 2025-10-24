#!/bin/bash

# Build and test the algosvc locally
# This script should be run from the WSL Ubuntu terminal

set -e

echo "🔨 Building algosvc container..."

# Change to project directory
cd ~/work/algosvc 2>/dev/null || {
    echo "❌ Please run this from WSL and ensure the project is at ~/work/algosvc"
    echo "   You may need to copy the project files to WSL first:"
    echo "   cp -r /mnt/c/Users/jmasengesho/Documents/developer/AI/MLOps/Danaher/CustomAlgorithms/algosvc ~/work/"
    exit 1
}

# Build the Docker image
echo "📦 Building Docker image..."
docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .

echo "✅ Build complete!"
echo ""
echo "🚀 Starting container on port 8080..."
echo "   Use Ctrl+C to stop"
echo ""

# Run the container
docker run --rm -p 8080:8080 algosvc:v0.1.0