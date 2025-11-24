# Kubernetes Testing Guide (Docker Desktop)

## Prerequisites

1. **Enable Kubernetes in Docker Desktop**
   - Open Docker Desktop
   - Go to Settings → Kubernetes
   - Check "Enable Kubernetes"
   - Click "Apply & Restart"
   - Wait for Kubernetes to start (green indicator)

2. **Verify kubectl access**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

3. **Build the Docker image** (if not already built)
   ```bash
   cd /Users/jmasengesho/Developer/microsoft/misc/algosvc-mlops
   docker build -f docker/Dockerfile.cpu -t algosvc:v0.1.0 .
   ```

## Quick Test (Recommended)

Use the automated test script:

```bash
cd /Users/jmasengesho/Developer/microsoft/misc/algosvc-mlops
./scripts/k8s-test.sh
```

The script will:
- Check prerequisites
- Build the image if needed
- Deploy the job
- Wait for completion
- Show logs and results

## Manual Testing

### Option 1: hostPath Volumes (Simpler for Testing)

This uses your local directories directly:

```bash
# Deploy the test job
kubectl apply -f k8s/job-test.yaml

# Watch the job
kubectl get jobs -w

# Check pod status
kubectl get pods -l app=algosvc

# View logs
kubectl logs -l app=algosvc

# Check results locally
ls -la rundata/output/
cat rundata/output/sample.json
```

### Option 2: PersistentVolumeClaims (Production-like)

For a more production-like setup:

```bash
# Deploy with PVCs
kubectl apply -f k8s/deployment.yaml

# Check PVCs
kubectl get pvc

# Watch the job
kubectl get jobs -w

# View logs
kubectl logs -l app=algosvc
```

**Note:** For PVC testing, you'll need to populate the input PVC with data. You can use a helper pod:

```bash
# Create a pod to copy files to the PVC
kubectl run file-copy --rm -i --restart=Never \
  --image=busybox \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "file-copy",
      "image": "busybox",
      "command": ["sh"],
      "stdin": true,
      "volumeMounts": [{
        "name": "input-data",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "input-data",
      "persistentVolumeClaim": {
        "claimName": "algosvc-input-pvc"
      }
    }]
  }
}' < rundata/input/sample.json
```

## Monitoring the Job

```bash
# Watch job status
kubectl get jobs -w

# Watch pods
kubectl get pods -w

# View detailed job info
kubectl describe job algosvc-job

# View pod logs (real-time)
kubectl logs -f -l app=algosvc

# View events
kubectl get events --sort-by='.lastTimestamp'
```

## Checking Results

### With hostPath volumes:
```bash
# Results are in your local directory
ls -la rundata/output/
cat rundata/output/sample.json
```

### With PVCs:
```bash
# Copy results from PVC to local
kubectl run result-copy --rm -i --restart=Never \
  --image=busybox \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "result-copy",
      "image": "busybox",
      "command": ["sh", "-c", "cat /data/sample.json"],
      "volumeMounts": [{
        "name": "output-data",
        "mountPath": "/data"
      }]
    }],
    "volumes": [{
      "name": "output-data",
      "persistentVolumeClaim": {
        "claimName": "algosvc-output-pvc"
      }
    }]
  }
}'
```

## Cleanup

```bash
# Delete the job
kubectl delete job algosvc-job-test
# or
kubectl delete job algosvc-job

# Delete PVCs (if using PVC approach)
kubectl delete pvc algosvc-input-pvc algosvc-output-pvc

# Clean up any remaining pods
kubectl delete pods -l app=algosvc
```

## Troubleshooting

### Job doesn't start
```bash
# Check job status
kubectl describe job algosvc-job

# Check pod events
kubectl describe pod -l app=algosvc

# Check if image exists
docker images | grep algosvc
```

### Image pull errors
```bash
# Make sure imagePullPolicy is set to Never for local testing
# Check the deployment.yaml file

# Verify image exists locally
docker images algosvc:v0.1.0
```

### Permission errors
```bash
# Check pod security context
kubectl describe pod -l app=algosvc | grep -A 5 Security

# For hostPath, ensure directories are accessible
ls -la rundata/input/
ls -la rundata/output/
```

### Job completes but no output
```bash
# Check logs for errors
kubectl logs -l app=algosvc

# Verify input files exist
kubectl exec -it <pod-name> -- ls -la /rundata/input/

# Check output directory
kubectl exec -it <pod-name> -- ls -la /rundata/output/
```

## Expected Output

When successful, you should see:
- Job status: `COMPLETIONS: 1/1`
- Pod status: `Completed`
- Output files in `rundata/output/` (if using hostPath)
- Logs showing: "INFO: Successfully processed all files. Exiting."

## Next Steps

Once local testing works:
1. Push image to a container registry
2. Update `imagePullPolicy` to `IfNotPresent` or `Always`
3. Update image reference in deployment.yaml
4. Deploy to a real Kubernetes cluster (AKS, EKS, GKE, etc.)

