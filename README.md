# AlgoSvc - MLOps Container Service

[![GitHub Repository](https://img.shields.io/badge/GitHub-algosvc--mlops-blue?logo=github)](https://github.com/jmasengeshomsft/algosvc-mlops)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage%20Build-2496ED?logo=docker)](./docker/Dockerfile.cpu)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes)](./k8s/deployment.yaml)

A containerized machine learning service that combines a native C++ computational kernel with a Java HTTP service for high-performance inference.

## Repository

🔗 **GitHub**: https://github.com/jmasengeshomsft/algosvc-mlops

## Architecture

- **libkernels.so** — C++ shared library with fast sigmoid operations via JNI
- **algosvc.jar** — Java Javalin HTTP service that exposes REST endpoints
- **Multi-stage Docker build** — Compiles both components in isolated build stages
- **Production ready** — Includes health checks, observability hooks, and security best practices

## Prerequisites

### Windows with WSL2
```powershell
# Run in PowerShell as Administrator
wsl --install -d Ubuntu-22.04
wsl --set-default-version 2
```

### WSL Ubuntu Setup
```bash
# Update system and install build tools
sudo apt-get update
sudo apt-get install -y build-essential cmake git curl unzip ca-certificates gnupg lsb-release

# Install JDK and Maven
sudo apt-get install -y openjdk-21-jdk maven

# Set JAVA_HOME
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.bashrc
source ~/.bashrc
```

### Docker Desktop
- Install Docker Desktop with WSL2 backend enabled
- Enable WSL integration for Ubuntu-22.04 in Docker settings

## Quick Start

### 1. Copy Project to WSL
```bash
# From WSL terminal
mkdir -p ~/work
cp -r /mnt/c/Users/jmasengesho/Documents/developer/AI/MLOps/Danaher/CustomAlgorithms/algosvc ~/work/
cd ~/work/algosvc
```

### 2. Run with Docker Compose (Recommended)
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Start services in background
./scripts/compose.sh up

# Or start with interactive logs
./scripts/compose-up.sh
```

### 3. Test the Service
```bash
# Test endpoints
./scripts/compose.sh test

# Or manually test
./scripts/test-endpoints.sh
```

### Alternative: Direct Docker Build
```bash
# Build and run without compose
./scripts/build-and-run.sh
```

## API Endpoints

### Health Checks
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe

### Service Information
- `GET /version` - Returns service version and configuration

### Inference
- `POST /infer` - Perform sigmoid inference on input data

#### Request Format
```json
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
```

#### Response Format
```json
{
  "y": [0.018, 0.119, 0.5, 0.881, 0.982],
  "algoVersion": "0.1.0"
}
```

## Docker Compose Commands

```bash
# Start services in background
./scripts/compose.sh up

# Start with Nginx reverse proxy
./scripts/compose.sh up-nginx

# View logs
./scripts/compose.sh logs

# Stop services
./scripts/compose.sh down

# Rebuild images
./scripts/compose.sh rebuild

# Test endpoints
./scripts/compose.sh test

# Clean up everything
./scripts/compose.sh clean
```

## Manual Build (Alternative to Compose)

### Build Native Library
```bash
cd ~/work/algosvc/native
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --target kernels
ls build/libkernels.so
```

### Build Java Service
```bash
cd ~/work/algosvc/java
mvn -q -DskipTests package
ls target/algosvc-0.1.0-shaded.jar
```

### Build Container
```bash
cd ~/work/algosvc
docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .
```

### Run Container
```bash
docker run --rm -p 8080:8080 algosvc:v0.1.0
```

## Project Structure
```
algosvc/
├── native/
│   ├── CMakeLists.txt           # C++ build configuration
│   └── kernels.cpp              # JNI implementation with sigmoid
├── java/
│   ├── pom.xml                 # Maven configuration
│   └── src/main/java/com/acme/
│       ├── NativeKernels.java      # JNI wrapper
│       └── AlgoService.java        # Javalin HTTP service
├── docker/
│   └── Dockerfile.cpu          # Multi-stage build
├── nginx/
│   └── nginx.conf              # Nginx reverse proxy config
├── k8s/
│   └── deployment.yaml         # Kubernetes manifests
├── logs/                       # Application logs (Docker volume)
├── scripts/
│   ├── build-and-run.sh        # Direct Docker build and run
│   ├── compose-up.sh           # Docker Compose with logs
│   ├── compose.sh              # Docker Compose management
│   └── test-endpoints.sh       # API testing script
├── docker-compose.yml          # Docker Compose configuration
└── .env                        # Environment variables
```

## Development Workflow

### Clone Repository
```bash
git clone https://github.com/jmasengeshomsft/algosvc-mlops.git
cd algosvc-mlops
```

### Local Development
```bash
# Copy to WSL for building (if needed)
cp -r . ~/work/algosvc-mlops && cd ~/work/algosvc-mlops

# Build and run with Docker Compose
chmod +x scripts/*.sh
./scripts/compose.sh up

# Test endpoints
./scripts/compose.sh test
```

### Kubernetes Development
```bash
# Switch to Docker Desktop Kubernetes
kubectl config use-context docker-desktop

# Deploy to local Kubernetes
kubectl apply -f k8s/deployment.yaml

# Port-forward for testing
kubectl port-forward svc/algosvc 8081:80
```

### Contributing
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make changes and test locally
4. Commit with clear messages: `git commit -m "Add: feature description"`
5. Push to your fork: `git push origin feature/your-feature`
6. Create a Pull Request

## Next Steps

Once local testing is working, you can proceed with:

1. **Azure Container Registry** - Push images to ACR
2. **Azure Kubernetes Service** - Deploy to AKS cluster  
3. **Azure Container Apps** - Deploy with internal ingress
4. **Monitoring** - Add Prometheus, Application Insights
5. **Security** - Key Vault integration, Workload Identity
6. **CI/CD** - GitHub Actions workflows

## Troubleshooting

### Common Issues

**JNI Headers Not Found**
```bash
# Ensure JAVA_HOME is set correctly
echo $JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
```

**Docker Build Fails**
```bash
# Ensure you're in WSL, not Windows path
pwd  # Should show /home/username/work/algosvc, not /mnt/c/...
```

**UnsatisfiedLinkError**
```bash
# Check if library exists in container
docker run --rm algosvc:v0.1.0 ls -la /app/lib/
```

**Port Already in Use**
```bash
# Kill existing containers or use different port
docker ps
docker kill <container_id>
# OR
docker run --rm -p 8081:8080 algosvc:v0.1.0
```