# AlgoSvc - MLOps Container Service

[![GitHub Repository](https://img.shields.io/badge/GitHub-algosvc--mlops-blue?logo=github)](https://github.com/jmasengeshomsft/algosvc-mlops)
[![Docker](https://img.shields.io/badge/Docker-Multi--stage%20Build-2496ED?logo=docker)](./docker/Dockerfile.cpu)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-326CE5?logo=kubernetes)](./k8s/deployment.yaml)

A containerized machine learning batch job that combines a native C++ computational kernel with a Java application for high-performance inference. Processes input files from a directory and writes results to an output directory.

## Repository

🔗 **GitHub**: https://github.com/jmasengeshomsft/algosvc-mlops

## Architecture

- **libkernels.so** — C++ shared library with fast sigmoid operations via JNI
- **algosvc.jar** — Java batch application that processes files from input directory
- **Multi-stage Docker build** — Compiles both components in isolated build stages
- **Batch job pattern** — Starts, processes files, and exits (not a long-running service)
- **Production ready** — Configurable input/output directories via environment variables

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

### 2. Prepare Input Data
```bash
# Create input/output directories
mkdir -p rundata/input rundata/output

# Create a sample input file
cat > rundata/input/sample.json <<EOF
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
EOF
```

### 3. Run with Docker Compose
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run the batch job
docker-compose up

# The job will process all JSON files in rundata/input
# and write results to rundata/output
```

### 4. Check Results
```bash
# View output files
ls -la rundata/output/
cat rundata/output/sample.json
```

### Alternative: Direct Docker Build
```bash
# Build and run without compose
./scripts/build-and-run.sh
```

## Usage

### Input/Output Format

The job processes JSON files from the input directory. Each file should contain:

#### Input File Format (`/rundata/input/*.json`)
```json
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
```

#### Output File Format (`/rundata/output/*.json`)
```json
{
  "y": [0.018, 0.119, 0.5, 0.881, 0.982],
  "algoVersion": "0.1.0",
  "elapsedNs": 1234567
}
```

### Environment Variables

- `INPUT_DIR` - Input directory path (default: `/rundata/input`)
- `OUTPUT_DIR` - Output directory path (default: `/rundata/output`)
- `ALGO_VERSION` - Algorithm version string (default: `0.1.0`)

### Behavior

- Processes all `.json` files in the input directory
- Creates output files with the same name in the output directory
- Exits with code 0 on success, 1 on error
- Logs processing information to stdout/stderr

## Docker Compose Usage

```bash
# Run the batch job
docker-compose up

# Run with custom input/output directories
INPUT_DIR=/custom/input OUTPUT_DIR=/custom/output docker-compose up

# Rebuild and run
docker-compose build && docker-compose up

# View logs
docker-compose logs

# Clean up
docker-compose down
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

### Run Container as Batch Job
```bash
# Create input/output directories
mkdir -p /tmp/algosvc/input /tmp/algosvc/output

# Create sample input
echo '{"x": [1, 2, 3], "scale": 1.0}' > /tmp/algosvc/input/test.json

# Run the job
docker run --rm \
  -v /tmp/algosvc/input:/rundata/input:ro \
  -v /tmp/algosvc/output:/rundata/output \
  algosvc:v0.1.0

# Check output
cat /tmp/algosvc/output/test.json
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
│       └── AlgoService.java        # Batch job application
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

# Create PVCs and deploy the job
kubectl apply -f k8s/deployment.yaml

# Check job status
kubectl get jobs
kubectl get pods

# View job logs
kubectl logs job/algosvc-job

# Clean up
kubectl delete -f k8s/deployment.yaml
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

**No Input Files Found**
```bash
# Ensure input directory exists and contains JSON files
mkdir -p rundata/input
echo '{"x": [1, 2, 3], "scale": 1.0}' > rundata/input/test.json
```

**Permission Denied on Output Directory**
```bash
# Ensure output directory is writable
mkdir -p rundata/output
chmod 777 rundata/output  # Or use appropriate permissions
```