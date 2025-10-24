#!/bin/bash

# Docker Compose management script for algosvc
# Provides common Docker Compose operations

set -e

# Change to project directory
cd ~/work/algosvc 2>/dev/null || {
    echo "❌ Please run this from WSL and ensure the project is at ~/work/algosvc"
    exit 1
}

# Use docker compose (newer) or docker-compose (legacy)
COMPOSE_CMD="docker compose"
if ! docker compose version &> /dev/null; then
    COMPOSE_CMD="docker-compose"
fi

case "${1:-help}" in
    "up"|"start")
        echo "🚀 Starting services..."
        $COMPOSE_CMD up -d
        echo "✅ Services started in background"
        echo "   AlgoSvc: http://localhost:8080"
        ;;
    
    "up-nginx")
        echo "🚀 Starting services with Nginx reverse proxy..."
        $COMPOSE_CMD --profile with-nginx up -d
        echo "✅ Services started with Nginx"
        echo "   AlgoSvc (direct): http://localhost:8080"
        echo "   AlgoSvc (via Nginx): http://localhost:80"
        ;;
    
    "down"|"stop")
        echo "🛑 Stopping services..."
        $COMPOSE_CMD down
        echo "✅ Services stopped"
        ;;
    
    "restart")
        echo "🔄 Restarting services..."
        $COMPOSE_CMD restart
        echo "✅ Services restarted"
        ;;
    
    "build")
        echo "📦 Building images..."
        $COMPOSE_CMD build
        echo "✅ Build complete"
        ;;
    
    "rebuild")
        echo "🔨 Rebuilding images (no cache)..."
        $COMPOSE_CMD build --no-cache
        echo "✅ Rebuild complete"
        ;;
    
    "logs")
        echo "📄 Showing service logs..."
        $COMPOSE_CMD logs -f
        ;;
    
    "status"|"ps")
        echo "📊 Service status:"
        $COMPOSE_CMD ps
        ;;
    
    "clean")
        echo "🧹 Cleaning up..."
        $COMPOSE_CMD down --volumes --remove-orphans
        docker system prune -f
        echo "✅ Cleanup complete"
        ;;
    
    "test")
        echo "🧪 Testing services..."
        # Wait for services to be ready
        echo "Waiting for service to be ready..."
        sleep 10
        ../scripts/test-endpoints.sh
        ;;
    
    "help"|*)
        echo "🐳 AlgoSvc Docker Compose Management"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  up, start     Start services in background"
        echo "  up-nginx      Start services with Nginx reverse proxy"
        echo "  down, stop    Stop all services"
        echo "  restart       Restart services"
        echo "  build         Build images"
        echo "  rebuild       Rebuild images (no cache)"
        echo "  logs          Show service logs"
        echo "  status, ps    Show service status"
        echo "  test          Test service endpoints"
        echo "  clean         Stop services and clean up"
        echo "  help          Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 up         # Start algosvc in background"
        echo "  $0 up-nginx   # Start with nginx reverse proxy"
        echo "  $0 logs       # Follow service logs"
        echo "  $0 test       # Test the API endpoints"
        ;;
esac