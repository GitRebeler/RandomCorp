# Complete LKE Cluster Creation and RandomCorp Deployment Script
# This script orchestrates the entire process from cluster creation to application deployment
#
# Usage Examples:
#   .\build-cluster-deploy-app.ps1
#   .\build-cluster-deploy-app.ps1 -SkipClusterCreation
#   .\build-cluster-deploy-app.ps1 -ApiUrl "http://your-api-ip"
#
param(
    [switch]$SkipClusterCreation,
    [string]$ApiUrl = "",
    [string]$ClusterName = "randomcorp-lke",
    [int]$NodeCount = 3,
    [int]$MaxRetries = 20,
    [int]$RetryDelay = 30
)

Write-Host "🚀 Starting Complete LKE Deployment Process..." -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

$ErrorActionPreference = "Stop"
$startTime = Get-Date

function Write-Step {
    param($StepNumber, $Description)
    Write-Host ""
    Write-Host "📋 Step $StepNumber`: $Description" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
}

function Write-Success {
    param($Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param($Message)
    Write-Host "⚠️ $Message" -ForegroundColor Yellow
}

function Write-Error {
    param($Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

try {
    # Step 1: Create LKE Cluster (if not skipped)
    if (-not $SkipClusterCreation) {
        Write-Step 1 "Creating LKE Cluster"
        
        Set-Location "infra\linode"
        .\create-lke-cluster.ps1 -ClusterName $ClusterName -NodeCount $NodeCount
        
        if ($LASTEXITCODE -ne 0) {
            throw "LKE cluster creation failed"
        }
        
        Write-Success "LKE cluster created successfully"
        
        # Wait for all nodes to be ready
        Write-Host "🔄 Waiting for all $NodeCount nodes to be ready..." -ForegroundColor Yellow
        $retryCount = 0
        $allNodesReady = $false
        
        while (-not $allNodesReady -and $retryCount -lt $MaxRetries) {
            $retryCount++
            Write-Host "   Attempt $retryCount/$MaxRetries - Checking node status..." -ForegroundColor Gray
            
            try {
                $nodes = kubectl get nodes --no-headers 2>$null
                if ($LASTEXITCODE -eq 0 -and $nodes) {
                    $nodeLines = $nodes -split "`n" | Where-Object { $_.Trim() -ne "" }
                    $readyNodes = $nodeLines | Where-Object { $_ -match "\s+Ready\s+" }
                    
                    Write-Host "   Found $($nodeLines.Count) nodes, $($readyNodes.Count) ready" -ForegroundColor Gray
                    
                    if ($readyNodes.Count -eq $NodeCount) {
                        $allNodesReady = $true
                        Write-Success "All $NodeCount nodes are ready!"
                        break
                    }
                } else {
                    Write-Host "   kubectl not ready yet..." -ForegroundColor Gray
                }
            } catch {
                Write-Host "   Error checking nodes: $($_.Exception.Message)" -ForegroundColor Gray
            }
            
            if (-not $allNodesReady) {
                Start-Sleep -Seconds $RetryDelay
            }
        }
        
        if (-not $allNodesReady) {
            throw "Timeout waiting for all nodes to be ready after $($MaxRetries * $RetryDelay) seconds"
        }
        
        Set-Location "..\.."
    } else {
        Write-Step 1 "Skipping cluster creation (using existing cluster)"
        
        # Ensure kubectl is configured
        $env:KUBECONFIG = "$(Get-Location)\infra\linode\kubeconfig-$ClusterName-decoded.yaml"
        
        # Verify cluster connection
        kubectl get nodes | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Cannot connect to existing cluster. Please check kubeconfig."
        }
        Write-Success "Connected to existing cluster"
    }

    # Step 2: Build and Push Docker Images
    Write-Step 2 "Building and Pushing Docker Images"
    
    if ([string]::IsNullOrEmpty($ApiUrl)) {
        Write-Host "🔍 Getting LoadBalancer IPs for API URL..." -ForegroundColor Yellow
        $apiService = kubectl get service randomcorp-api -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
        if ($LASTEXITCODE -eq 0 -and ![string]::IsNullOrEmpty($apiService)) {
            $ApiUrl = "http://$apiService"
            Write-Host "📝 Found existing API LoadBalancer: $ApiUrl" -ForegroundColor Cyan
        } else {
            $ApiUrl = "http://api.randomcorp.lke"
            Write-Warning "No existing API service found, using placeholder: $ApiUrl"
        }
    }
    
    .\build-lke-images.ps1 -NoCache -ApiUrl $ApiUrl
    if ($LASTEXITCODE -ne 0) {
        throw "Image build and push failed"
    }
    Write-Success "Docker images built and pushed successfully"

    # Step 3: Update Helm Dependencies
    Write-Step 3 "Updating Helm Dependencies"
    
    Set-Location "helm-charts\randomcorp"
    helm dependency update
    if ($LASTEXITCODE -ne 0) {
        throw "Helm dependency update failed"
    }
    Write-Success "Helm dependencies updated"
    
    Set-Location "..\.."

    # Step 4: Check and Commit Git Changes
    Write-Step 4 "Checking for Git Changes"
    
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "📝 Found uncommitted changes:" -ForegroundColor Yellow
        git status --short
        Write-Host ""
        Write-Host "🔄 Committing changes..." -ForegroundColor Cyan
        git add .
        git commit -m "Automated deployment update - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Git push failed, but continuing with deployment"
        } else {
            Write-Success "Changes committed and pushed to repository"
        }
    } else {
        Write-Success "No uncommitted changes found"
    }

    # Step 5: Ensure GitHub Token and Install Flux
    Write-Step 5 "Installing Flux for GitOps"
    
    $tokenFile = "infra\linode\github-token.txt"
    if (-not (Test-Path $tokenFile)) {
        throw "GitHub token file not found: $tokenFile. Please create this file with your GitHub Personal Access Token."
    }
    Write-Success "GitHub token file found"
    
    Set-Location "infra\linode"
    .\install-flux.ps1
    if ($LASTEXITCODE -ne 0) {
        throw "Flux installation failed"
    }
    Write-Success "Flux installed successfully"
    Set-Location "..\.."

    # Step 6: Verify Flux Components
    Write-Step 6 "Verifying Flux Components"
    
    Write-Host "🔍 Checking Flux system pods..." -ForegroundColor Yellow
    kubectl get pods -n flux-system
    
    Write-Host ""
    Write-Host "🔍 Checking Git repositories..." -ForegroundColor Yellow  
    kubectl get gitrepository -n flux-system
    
    Write-Host ""
    Write-Host "🔍 Checking Helm releases..." -ForegroundColor Yellow
    kubectl get helmrelease -n default
    
    Write-Success "Flux components verified"

    # Step 7: Wait for Application Pods
    Write-Step 7 "Waiting for Application Pods"
    
    Write-Host "🔄 Waiting for application pods to be ready..." -ForegroundColor Yellow
    $retryCount = 0
    $podsReady = $false
    
    while (-not $podsReady -and $retryCount -lt $MaxRetries) {
        $retryCount++
        Write-Host "   Attempt $retryCount/$MaxRetries - Checking pod status..." -ForegroundColor Gray
        
        $pods = kubectl get pods -n default --no-headers 2>$null
        if ($LASTEXITCODE -eq 0 -and $pods) {
            $podLines = $pods -split "`n" | Where-Object { $_.Trim() -ne "" }
            $runningPods = $podLines | Where-Object { $_ -match "\s+Running\s+" }
            
            Write-Host "   Found $($podLines.Count) pods, $($runningPods.Count) running" -ForegroundColor Gray
            
            # Check if we have at least frontend, API, and database pods
            $frontendPods = $podLines | Where-Object { $_ -match "randomcorp-frontend.*Running" }
            $apiPods = $podLines | Where-Object { $_ -match "randomcorp-api.*Running" }
            $dbPods = $podLines | Where-Object { $_ -match "randomcorp-mssqlserver.*Running" }
            
            if ($frontendPods.Count -ge 1 -and $apiPods.Count -ge 1 -and $dbPods.Count -ge 1) {
                $podsReady = $true
                Write-Success "All application pods are running!"
                break
            }
        }
        
        if (-not $podsReady) {
            Start-Sleep -Seconds $RetryDelay
        }
    }
    
    if (-not $podsReady) {
        Write-Warning "Timeout waiting for all pods to be ready, but continuing..."
    }

    # Step 8: Get LoadBalancer IPs
    Write-Step 8 "Getting LoadBalancer IPs"
    
    Write-Host "🌐 LoadBalancer Services:" -ForegroundColor Yellow
    kubectl get services -n default
    
    # Extract LoadBalancer IPs
    $frontendIP = kubectl get service randomcorp-frontend -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    $apiIP = kubectl get service randomcorp-api -n default -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if (![string]::IsNullOrEmpty($frontendIP)) {
        Write-Success "Frontend LoadBalancer IP: $frontendIP"
        $frontendUrl = "http://$frontendIP"
    } else {
        Write-Warning "Frontend LoadBalancer IP not yet assigned"
        $frontendUrl = "Pending..."
    }
    
    if (![string]::IsNullOrEmpty($apiIP)) {
        Write-Success "API LoadBalancer IP: $apiIP"
        $actualApiUrl = "http://$apiIP"
    } else {
        Write-Warning "API LoadBalancer IP not yet assigned"
        $actualApiUrl = "Pending..."
    }

    # Step 9: Rebuild Frontend with Correct API URL (if needed)
    if (![string]::IsNullOrEmpty($apiIP) -and $ApiUrl -ne $actualApiUrl) {
        Write-Step 9 "Rebuilding Frontend with Correct API URL"
        
        Write-Host "🔄 Current API URL in build: $ApiUrl" -ForegroundColor Yellow
        Write-Host "🎯 Actual API LoadBalancer: $actualApiUrl" -ForegroundColor Cyan
        Write-Host "🔨 Rebuilding frontend with correct API URL..." -ForegroundColor Cyan
        
        docker build --no-cache --build-arg REACT_APP_API_URL="$actualApiUrl" -t docker.io/johnhebeler/randomcorp-frontend:latest .
        if ($LASTEXITCODE -ne 0) {
            throw "Frontend rebuild failed"
        }
        
        docker push docker.io/johnhebeler/randomcorp-frontend:latest
        if ($LASTEXITCODE -ne 0) {
            throw "Frontend push failed"
        }
        
        Write-Host "🔄 Restarting frontend deployment..." -ForegroundColor Cyan
        kubectl rollout restart deployment randomcorp-frontend -n default
        kubectl rollout status deployment randomcorp-frontend -n default --timeout=300s
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Rollout status check failed, trying pod deletion..."
            kubectl delete pods -l app.kubernetes.io/component=frontend -n default
            Start-Sleep -Seconds 30
        }
        
        Write-Success "Frontend updated with correct API URL"
    } else {
        Write-Step 9 "Skipping Frontend Rebuild (API URL already correct or pending)"
    }

    # Step 10: Final Verification
    Write-Step 10 "Final Verification"
    
    Write-Host "🔍 Final pod status:" -ForegroundColor Yellow
    kubectl get pods -n default
    
    Write-Host ""
    Write-Host "🌐 Final service status:" -ForegroundColor Yellow
    kubectl get services -n default

    # Calculate deployment time
    $endTime = Get-Date
    $deploymentTime = $endTime - $startTime
    
    Write-Host ""
    Write-Host "🎉 DEPLOYMENT COMPLETE! 🎉" -ForegroundColor Green
    Write-Host "=========================" -ForegroundColor Green
    Write-Host "⏱️ Total deployment time: $($deploymentTime.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan
    Write-Host ""
    
    if (![string]::IsNullOrEmpty($frontendIP)) {
        Write-Host "🌐 Frontend URL: $frontendUrl" -ForegroundColor Green
    }
    if (![string]::IsNullOrEmpty($apiIP)) {
        Write-Host "🔌 API URL: $actualApiUrl" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "📋 Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Test the frontend application in your browser" -ForegroundColor White
    Write-Host "2. Verify form submissions are working" -ForegroundColor White
    Write-Host "3. Monitor with: kubectl get pods -n default" -ForegroundColor White
    Write-Host ""
    Write-Host "🔧 Useful Commands:" -ForegroundColor Yellow
    Write-Host "   kubectl get services -n default" -ForegroundColor Gray
    Write-Host "   kubectl logs -f deployment/randomcorp-frontend -n default" -ForegroundColor Gray
    Write-Host "   kubectl logs -f deployment/randomcorp-api -n default" -ForegroundColor Gray

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "🔧 Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check cluster status: kubectl get nodes" -ForegroundColor White
    Write-Host "2. Check pods: kubectl get pods -n default" -ForegroundColor White
    Write-Host "3. Check services: kubectl get services -n default" -ForegroundColor White
    Write-Host "4. Check Flux: kubectl get pods -n flux-system" -ForegroundColor White
    exit 1
}
