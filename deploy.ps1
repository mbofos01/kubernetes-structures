param(
    [ValidateSet('deploy', 'clean', 'logs', 'restart', 'status')]
    [string]$Action = 'deploy',
    
    [string]$ClusterName = 'demo',
    [string]$ImageTag = 'dev',
    [switch]$Verbose
)

function Write-Log {
    param([string]$Message, [ValidateSet('Info', 'Success', 'Error', 'Warning')][string]$Level = 'Info')
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Error'   = 'Red'
        'Warning' = 'Yellow'
    }
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $Message" -ForegroundColor $colors[$Level]
}

function Test-Prerequisites {
    Write-Log "Checking prerequisites..." -Level Info
    
    $prerequisites = @('docker', 'kind', 'kubectl')
    $missing = @()
    
    foreach ($tool in $prerequisites) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            $missing += $tool
        }
    }
    
    if ($missing.Count -gt 0) {
        Write-Log "Missing prerequisites: $($missing -join ', ')" -Level Error
        exit 1
    }
    
    Write-Log "All prerequisites found" -Level Success
}

function Build-Image {
    Write-Log "Building Docker image: simple-api:$ImageTag" -Level Info
    
    Push-Location "simple-api"
    try {
        if ($Verbose) {
            docker build -t simple-api:$ImageTag .
        } else {
            docker build -t simple-api:$ImageTag . -q
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Image built successfully" -Level Success
        } else {
            Write-Log "Failed to build image" -Level Error
            exit 1
        }
    } finally {
        Pop-Location
    }
}

function Create-Cluster {
    Write-Log "Creating kind cluster: $ClusterName" -Level Info
    
    # Check if cluster already exists
    $existingCluster = kind get clusters 2>$null | Select-String $ClusterName
    
    if ($existingCluster) {
        Write-Log "Cluster '$ClusterName' already exists" -Level Warning
        return
    }
    
    kind create cluster --name $ClusterName --config kind-config.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Cluster created successfully" -Level Success
        # Wait a bit for cluster to stabilize
        Start-Sleep -Seconds 3
    } else {
        Write-Log "Failed to create cluster" -Level Error
        exit 1
    }
}

function Load-Image {
    Write-Log "Loading image into kind cluster: $ClusterName" -Level Info
    
    kind load docker-image simple-api:$ImageTag --name $ClusterName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Image loaded successfully" -Level Success
    } else {
        Write-Log "Failed to load image" -Level Error
        exit 1
    }
}

function Deploy-Manifests {
    Write-Log "Deploying Kubernetes manifests" -Level Info
    
    kubectl apply -f k8s-deploy.yaml
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Manifests applied successfully" -Level Success
    } else {
        Write-Log "Failed to apply manifests" -Level Error
        exit 1
    }
}

function Check-Deployment {
    Write-Log "Checking deployment status..." -Level Info
    
    $maxRetries = 30
    $retryCount = 0
    
    while ($retryCount -lt $maxRetries) {
        $status = kubectl rollout status deployment/simple-api --timeout=10s 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Deployment is ready" -Level Success
            
            # Show pod information
            Write-Log "Running pods:" -Level Info
            kubectl get pods -l app=simple-api -o wide
            
            return $true
        }
        
        $retryCount++
        Write-Log "Waiting for deployment... ($retryCount/$maxRetries)" -Level Warning
        Start-Sleep -Seconds 2
    }
    
    Write-Log "Deployment timeout" -Level Error
    return $false
}

function Show-Status {
    Write-Log "=== Deployment Status ===" -Level Info
    Write-Host ""
    
    Write-Log "Cluster Info:" -Level Info
    kubectl cluster-info
    
    Write-Host ""
    Write-Log "Deployments:" -Level Info
    kubectl get deployments
    
    Write-Host ""
    Write-Log "Services:" -Level Info
    kubectl get services
    
    Write-Host ""
    Write-Log "Pods:" -Level Info
    kubectl get pods -o wide
}

function Show-Logs {
    param([string]$Pod = $null)
    
    if ($Pod) {
        Write-Log "Logs for pod: $Pod" -Level Info
        kubectl logs $Pod
    } else {
        Write-Log "Available pods:" -Level Info
        kubectl get pods -l app=simple-api
        Write-Host ""
        Write-Log "Use: .\deploy.ps1 -Action logs -Pod <pod-name>" -Level Info
    }
}

function Restart-Deployment {
    Write-Log "Restarting deployment..." -Level Info
    
    kubectl rollout restart deployment/simple-api
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Deployment restarted" -Level Success
        Check-Deployment | Out-Null
    } else {
        Write-Log "Failed to restart deployment" -Level Error
        exit 1
    }
}

function Clean-Cluster {
    Write-Log "Deleting kind cluster: $ClusterName" -Level Warning
    
    kind delete cluster --name $ClusterName
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Cluster deleted successfully" -Level Success
    } else {
        Write-Log "Failed to delete cluster" -Level Error
        exit 1
    }
}

function Show-Help {
    Write-Host @"
Usage: .\deploy.ps1 [Action] [Options]

Actions:
  deploy      Complete deployment (build, create cluster, load image, deploy manifests)
  status      Show current deployment status
  logs        Show pod logs
  restart     Restart the deployment
  clean       Delete the kind cluster

Options:
  -ClusterName <name>    Kind cluster name (default: demo)
  -ImageTag <tag>        Docker image tag (default: dev)
  -Verbose              Show detailed output
  -Help                 Show this help message

Examples:
  .\deploy.ps1                                    # Full deployment with defaults
  .\deploy.ps1 -Action status                     # Check deployment status
  .\deploy.ps1 -Action clean -ClusterName demo    # Delete cluster
  .\deploy.ps1 -Verbose                           # Verbose deployment output
"@
}

# Main execution
if ($Action -eq 'deploy') {
    Write-Log "Starting Kubernetes deployment" -Level Info
    Write-Log "Cluster: $ClusterName | Image Tag: $ImageTag" -Level Info
    Write-Host ""
    
    Test-Prerequisites
    Build-Image
    Create-Cluster
    Load-Image
    Deploy-Manifests
    
    Write-Host ""
    Check-Deployment
    
    Write-Host ""
    Write-Log "=== Access Information ===" -Level Success
    Write-Log "NodePort Service: http://localhost:30008/info" -Level Info
    Write-Log "API Docs: http://localhost:30008/docs" -Level Info
    Write-Log "Redoc: http://localhost:30008/redoc" -Level Info
    Write-Host ""
    Write-Log "To forward port 8080 locally:" -Level Info
    Write-Log "kubectl port-forward svc/simple-api 8080:80" -Level Info
    
} elseif ($Action -eq 'status') {
    Show-Status
    
} elseif ($Action -eq 'logs') {
    Show-Logs
    
} elseif ($Action -eq 'restart') {
    Restart-Deployment
    
} elseif ($Action -eq 'clean') {
    Clean-Cluster
    
} else {
    Show-Help
}

Write-Log "Done!" -Level Success
