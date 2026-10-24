# Kubernetes Deployment

## Prerequisites

- Docker Desktop running
- `kind` installed
- `kubectl` installed

## Quick Start with Deploy Script

The easiest way to deploy is to use the automated `deploy.ps1` script.

### Basic Deployment

```powershell
.\deploy.ps1
```

This will automatically:
- Build the Docker image
- Create a kind cluster
- Load the image into the cluster
- Deploy all manifests
- Verify the deployment is running

### Deploy Script Usage

```powershell
# Full deployment (default)
.\deploy.ps1

# Check deployment status
.\deploy.ps1 -Action status

# View pod logs
.\deploy.ps1 -Action logs

# Restart the deployment
.\deploy.ps1 -Action restart

# Delete the cluster and cleanup
.\deploy.ps1 -Action clean

# Custom cluster name
.\deploy.ps1 -ClusterName my-cluster

# Verbose output for debugging
.\deploy.ps1 -Verbose

# Get help
.\deploy.ps1 -Help
```

### Accessing the API

After deployment, you have two options to access your services:

**Option 1: NodePort (Direct access)**
- **API Endpoint**: http://localhost:30008/info
- **Interactive Docs**: http://localhost:30008/docs
- **ReDoc**: http://localhost:30008/redoc

**Option 2: Port Forwarding (Local 8080)**

If you prefer to use port 8080 locally, set up port forwarding:

```powershell
kubectl port-forward svc/simple-api 8080:80
```

Then access at:
- **API Endpoint**: http://localhost:8080/info
- **Interactive Docs**: http://localhost:8080/docs
- **ReDoc**: http://localhost:8080/redoc

### Test the API

```powershell
# Using NodePort
curl http://localhost:30008/info

# Or using port-forward (after running the command above)
curl http://localhost:8080/info
```
