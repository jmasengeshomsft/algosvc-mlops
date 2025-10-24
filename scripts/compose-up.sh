#!/bin/bash

# Docker Compose build and run script for algosvc
# This script should be run from the WSL Ubuntu terminal

set -e

echo "🐳 Building and running algosvc with Docker Compose..."

# Change to project directory
cd ~/work/algosvc 2>/dev/null || {
    echo "❌ Please run this from WSL and ensure the project is at ~/work/algosvc"
    echo "   You may need to copy the project files to WSL first:"
    echo "   cp -r /mnt/c/Users/jmasengesho/Documents/developer/AI/MLOps/Danaher/CustomAlgorithms/algosvc ~/work/"
    exit 1
}

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not found. Please install Docker Compose or use Docker Desktop."
    exit 1
fi

# Use docker compose (newer) or docker-compose (legacy)
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

echo "📦 Building algosvc image..."
$COMPOSE_CMD build algosvc

echo "✅ Build complete!"
echo ""
echo "🚀 Starting services..."
echo "   AlgoSvc will be available at: http://localhost:8080"
echo "   Use Ctrl+C to stop all services"
echo ""

# Start the services
$COMPOSE_CMD up

echo ""
echo "🛑 Services stopped."