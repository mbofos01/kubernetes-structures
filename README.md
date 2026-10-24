# Kubernetes Deployment

## Prerequisites

- Docker Desktop running
- `kind` installed
- `kubectl` installed

## Step 1: Build the Docker image

```powershell
cd simple-api
docker build -t simple-api:dev .
```

## Step 2: Create the kind cluster

```powershell
cd ..
kind create cluster --name demo --config kind-config.yaml
```

## Step 3: Load the image into kind

```powershell
kind load docker-image simple-api:dev --name demo
```

## Step 4: Deploy to Kubernetes

```powershell
kubectl apply -f k8s-deploy.yaml
```

## Step 5: Check deployment status

```powershell
kubectl rollout status deployment/simple-api
```

## Step 6: Test the API

```powershell
curl http://localhost:8080/info
```

## Cleanup

```powershell
kind delete cluster --name demo
```
