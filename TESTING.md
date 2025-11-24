# Testing Guide for Mac (Docker Desktop)

## Quick Start

### 1. Verify Directory Structure

The project already has sample input files set up. Verify the structure:

```bash
cd /Users/jmasengesho/Developer/microsoft/misc/algosvc-mlops

# Check input directory
ls -la rundata/input/

# You should see:
# - sample.json
# - test1.json
# - test2.json
```

### 2. Sample Input File Format

Each input file should be a JSON file with this structure:

```json
{
  "x": [-2, -1, 0, 1, 2],
  "scale": 2.0
}
```

Where:
- `x`: Array of floating-point numbers to process
- `scale`: Optional scaling factor (defaults to 1.0 if not provided)

### 3. Build and Run with Docker Compose

```bash
# Build the image and run the batch job
docker-compose up --build

# The job will:
# 1. Process all .json files in rundata/input/
# 2. Write results to rundata/output/
# 3. Exit when complete
```

### 4. Check Results

```bash
# View output files
ls -la rundata/output/

# View a specific output file
cat rundata/output/sample.json

# Or use the test script
./scripts/test-batch-job.sh
```

### 5. Expected Output Format

Each output file will contain:

```json
{
  "y": [0.018, 0.119, 0.5, 0.881, 0.982],
  "algoVersion": "0.1.0",
  "elapsedNs": 1234567
}
```

Where:
- `y`: Processed output array (sigmoid applied)
- `algoVersion`: Algorithm version
- `elapsedNs`: Processing time in nanoseconds

## Alternative: Direct Docker Run

If you prefer to run without docker-compose:

```bash
# Build the image
docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .

# Run the batch job
docker run --rm \
  -v "$(pwd)/rundata/input:/rundata/input:ro" \
  -v "$(pwd)/rundata/output:/rundata/output" \
  algosvc:v0.1.0
```

## Adding Your Own Test Files

1. Create a new JSON file in `rundata/input/`:

```bash
cat > rundata/input/my-test.json <<EOF
{
  "x": [0.1, 0.5, 1.0, 2.0, 5.0],
  "scale": 1.0
}
EOF
```

2. Run the job again:

```bash
docker-compose up
```

3. Check the output:

```bash
cat rundata/output/my-test.json
```

## Troubleshooting

### No output files created
- Check that input directory contains `.json` files
- Verify Docker has permission to write to `rundata/output/`
- Check container logs: `docker-compose logs`

### Permission errors
```bash
# Ensure output directory is writable
chmod 755 rundata/output
```

### Container exits immediately
- Check input directory exists and contains JSON files
- View logs: `docker-compose logs algosvc`

### Rebuild after code changes
```bash
# Force rebuild
docker-compose build --no-cache
docker-compose up
```

## Clean Up

```bash
# Remove output files
rm -f rundata/output/*.json

# Remove Docker containers and images
docker-compose down
docker rmi algosvc:v0.1.0
```

