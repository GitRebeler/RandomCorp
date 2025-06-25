# RandomCorp Automated Deployment Script
# This script automates the full deployment of RandomCorp to Linode Kubernetes Engine (LKE)

param(
    [switch]$Force,
    [switch]$SkipClusterCreation,
    [switch]$SkipImageBuild,
    [switch]$Help
)

# Set error action preference to stop on errors
$ErrorActionPreference = "Stop"

# Color functions for output
function Write-Step($stepNumber, $message) {
    Write-Host "[$stepNumber] $message" -ForegroundColor Cyan
}

function Write-Success($message) {
    Write-Host "[SUCCESS] $message" -ForegroundColor Green
}

function Write-Warning($message) {
    Write-Host "[WARNING] $message" -ForegroundColor Yellow
}

function Write-Error($message) {
    Write-Host "[ERROR] $message" -ForegroundColor Red
}

function Show-Help {
    Write-Host "RandomCorp Automated Deployment Script" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script automates the full deployment of RandomCorp to Linode Kubernetes Engine (LKE)."
    Write-Host ""
    Write-Host "Usage: .\build-cluster-deploy-app.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Force                  Force recreate cluster even if it exists"
    Write-Host "  -SkipClusterCreation   Skip cluster creation (use existing cluster)"
    Write-Host "  -SkipImageBuild        Skip Docker image building"
    Write-Host "  -Help                  Show this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\build-cluster-deploy-app.ps1                    # Full deployment"
    Write-Host "  .\build-cluster-deploy-app.ps1 -Force             # Force recreate cluster"
    Write-Host "  .\build-cluster-deploy-app.ps1 -SkipImageBuild    # Skip image building"
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

try {
    Write-Host "Starting RandomCorp Automated Deployment" -ForegroundColor Magenta
    Write-Host "=========================================" -ForegroundColor Magenta
    Write-Host ""

    # Ensure we're in the correct directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    Set-Location $scriptDir

    # Step 1: Create LKE Cluster
    if (-not $SkipClusterCreation) {
        Write-Step "1" "Creating LKE Cluster"
        
        if ($Force) {
            & .\infra\linode\create-lke-cluster.ps1 -Force
        } else {
            & .\infra\linode\create-lke-cluster.ps1
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create LKE cluster"
        }
        Write-Success "LKE cluster created successfully"
    } else {
        Write-Warning "Skipping cluster creation (using existing cluster)"
    }

    # Wait for all nodes to be ready
    Write-Step "1.5" "Waiting for all cluster nodes to be ready"
    
    $maxAttempts = 30
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "Checking node status (attempt $attempt/$maxAttempts)..."
        
        $notReadyNodes = kubectl get nodes --no-headers | Where-Object { $_ -notmatch '\s+Ready\s+' }
        
        if (-not $notReadyNodes) {
            Write-Success "All nodes are ready!"
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            throw "Timed out waiting for nodes to be ready"
        }
        
        Write-Host "Some nodes not ready yet, waiting 30 seconds..."
        Start-Sleep -Seconds 30
        
    } while ($true)

    # Step 2: Build and Push Docker Images
    if (-not $SkipImageBuild) {
        Write-Step "2" "Building and Pushing Docker Images"
        
        # Get the API service external IP to use as API URL
        Write-Host "Getting API service external IP..."
        $maxAttempts = 20
        $attempt = 0
        $apiUrl = ""
        
        do {
            $attempt++
            $apiService = kubectl get service randomcorp-api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
            
            if ($apiService -and $apiService -ne "") {
                $apiUrl = "http://$apiService"
                Write-Success "Found API URL: $apiUrl"
                break
            }
            
            if ($attempt -ge $maxAttempts) {
                Write-Warning "Could not get API service IP, using placeholder"
                $apiUrl = "http://api.placeholder.com"
                break
            }
            
            Write-Host "API service not ready yet, waiting 15 seconds... (attempt $attempt/$maxAttempts)"
            Start-Sleep -Seconds 15
            
        } while ($true)
        
        & .\build-lke-images.ps1 -NoCache -ApiUrl $apiUrl -ForceUpdate
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to build and push Docker images"
        }
        Write-Success "Docker images built and pushed successfully"
    } else {
        Write-Warning "Skipping Docker image building"
    }

    # Step 3: Update Helm Dependencies
    Write-Step "3" "Updating Helm Dependencies"
    
    Set-Location "helm-charts\randomcorp"
    helm dependency update
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update Helm dependencies"
    }
    
    Set-Location "..\.."
    Write-Success "Helm dependencies updated successfully"

    # Step 4: Commit and Push Changes
    Write-Step "4" "Committing and Pushing Git Changes"
    
    $gitStatus = git status --porcelain
    if ($gitStatus) {
        Write-Host "Found uncommitted changes, committing..."
        git add .
        git commit -m "Automated deployment update - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        git push
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to push git changes"
        }
        Write-Success "Git changes committed and pushed"
    } else {
        Write-Success "No git changes to commit"
    }

    # Step 5: Ensure GitHub Token Exists
    Write-Step "5" "Checking GitHub Token"
    
    $tokenPath = "infra\linode\github-token.txt"
    if (-not (Test-Path $tokenPath)) {
        Write-Error "GitHub token file not found at: $tokenPath"
        Write-Host "Please create this file with your GitHub personal access token."
        throw "GitHub token required for Flux installation"
    }
    Write-Success "GitHub token found"

    # Step 6: Install Flux
    Write-Step "6" "Installing Flux"
    
    Set-Location "infra\linode"
    & .\install-flux.ps1
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install Flux"
    }
    Set-Location "..\.."
    Write-Success "Flux installed successfully"

    # Step 7: Wait for Flux Components
    Write-Step "7" "Waiting for Flux Components to be Ready"
    
    $maxAttempts = 20
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "Checking Flux components (attempt $attempt/$maxAttempts)..."
        
        $fluxPods = kubectl get pods -n flux-system --no-headers
        $notReadyPods = $fluxPods | Where-Object { $_ -notmatch '\s+Running\s+' -and $_ -notmatch '\s+Completed\s+' }
        
        if (-not $notReadyPods) {
            Write-Success "All Flux components are ready!"
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Warning "Some Flux components may not be ready, continuing anyway..."
            break
        }
        
        Write-Host "Some Flux components not ready yet, waiting 15 seconds..."
        Start-Sleep -Seconds 15
        
    } while ($true)

    # Step 8: Wait for GitRepository
    Write-Step "8" "Waiting for GitRepository to be Ready"
    
    $maxAttempts = 15
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "Checking GitRepository status (attempt $attempt/$maxAttempts)..."
        
        $gitRepoStatus = kubectl get gitrepository randomcorp-source -n flux-system -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
        
        if ($gitRepoStatus -eq "True") {
            Write-Success "GitRepository is ready!"
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Warning "GitRepository may not be ready, continuing anyway..."
            break
        }
        
        Write-Host "GitRepository not ready yet, waiting 20 seconds..."
        Start-Sleep -Seconds 20
        
    } while ($true)

    # Step 9: Wait for HelmRelease
    Write-Step "9" "Waiting for HelmRelease to be Ready"
    
    $maxAttempts = 15
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "Checking HelmRelease status (attempt $attempt/$maxAttempts)..."
        
        $helmReleaseStatus = kubectl get helmrelease randomcorp -n default -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>$null
        
        if ($helmReleaseStatus -eq "True") {
            Write-Success "HelmRelease is ready!"
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Warning "HelmRelease may not be ready, continuing anyway..."
            break
        }
        
        Write-Host "HelmRelease not ready yet, waiting 20 seconds..."
        Start-Sleep -Seconds 20
        
    } while ($true)

    # Step 10: Wait for Application Pods
    Write-Step "10" "Waiting for Application Pods to be Ready"
    
    $maxAttempts = 20
    $attempt = 0
    
    do {
        $attempt++
        Write-Host "Checking application pods (attempt $attempt/$maxAttempts)..."
        
        $appPods = kubectl get pods -l app.kubernetes.io/name=randomcorp --no-headers 2>$null
        $notReadyPods = $appPods | Where-Object { $_ -notmatch '\s+Running\s+' -and $_ -notmatch '\s+Completed\s+' }
        
        if (-not $notReadyPods -and $appPods) {
            Write-Success "All application pods are ready!"
            break
        }
        
        if ($attempt -ge $maxAttempts) {
            Write-Warning "Some application pods may not be ready, continuing anyway..."
            break
        }
        
        Write-Host "Some application pods not ready yet, waiting 15 seconds..."
        Start-Sleep -Seconds 15
        
    } while ($true)

    # Step 11: Get the actual API URL and rebuild frontend if needed
    Write-Step "11" "Verifying API URL and Rebuilding Frontend if Needed"
    
    $apiService = kubectl get service randomcorp-api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if ($apiService -and $apiService -ne "") {
        $actualApiUrl = "http://$apiService"
        Write-Success "Actual API URL: $actualApiUrl"
        
        # Check if we need to rebuild the frontend with the correct API URL
        if ($apiUrl -ne $actualApiUrl) {
            Write-Step "11.1" "Rebuilding Frontend with Correct API URL"
            
            & .\build-lke-images.ps1 -NoCache -ApiUrl $actualApiUrl -ForceUpdate
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to rebuild frontend with correct API URL"
            }
            
            Write-Success "Frontend rebuilt with correct API URL"
            
            # Force restart of frontend deployment
            Write-Step "11.2" "Restarting Frontend Deployment"
            kubectl rollout restart deployment randomcorp-frontend
            
            # Wait for rollout to complete
            kubectl rollout status deployment randomcorp-frontend --timeout=300s
            
            Write-Success "Frontend deployment restarted"
        }
    } else {
        Write-Warning "Could not get API service external IP"
    }

    # Step 12: Final Verification
    Write-Step "12" "Final Verification"
    
    Write-Host ""
    Write-Host "=== Cluster Status ===" -ForegroundColor Yellow
    kubectl get nodes
    
    Write-Host ""
    Write-Host "=== Application Pods ===" -ForegroundColor Yellow
    kubectl get pods -l app.kubernetes.io/name=randomcorp
    
    Write-Host ""
    Write-Host "=== Services ===" -ForegroundColor Yellow
    kubectl get services
    
    Write-Host ""
    Write-Host "=== Flux Status ===" -ForegroundColor Yellow
    kubectl get gitrepository,helmrelease -A
    
    # Final Summary
    Write-Host ""
    Write-Host "DEPLOYMENT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "==================================" -ForegroundColor Green
    Write-Host ""
    
    $frontendService = kubectl get service randomcorp-frontend-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    $apiService = kubectl get service randomcorp-api-service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    
    if ($frontendService) {
        Write-Host "Frontend URL: http://$frontendService" -ForegroundColor Cyan
    }
    
    if ($apiService) {
        Write-Host "API URL: http://$apiService" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "RandomCorp application is now deployed and running on LKE!" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "You can try running the script again or use these options:" -ForegroundColor Yellow
    Write-Host "   -SkipClusterCreation    # Skip cluster creation if cluster exists" -ForegroundColor White
    Write-Host "   -SkipImageBuild         # Skip image building if images are up to date" -ForegroundColor White
    Write-Host "   -Force                  # Force recreate cluster" -ForegroundColor White
    Write-Host ""
    exit 1
}
