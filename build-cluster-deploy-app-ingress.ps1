# RandomCorp Ingress-Based Deployment Script
# This script deploys RandomCorp to LKE using NGINX Ingress Controller

param(
    [switch]$Force,
    [switch]$SkipClusterCreation,
    [switch]$SkipImageBuild,
    [switch]$SkipIngressSetup,
    [string]$Domain = "randomcorp.local",
    [switch]$UseHTTPS,
    [string]$Email = "",
    [switch]$Help
)

$ErrorActionPreference = "Stop"

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
    Write-Host "RandomCorp Ingress-Based Deployment Script" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "This script deploys RandomCorp to LKE using NGINX Ingress Controller."
    Write-Host ""
    Write-Host "Usage: .\build-cluster-deploy-app-ingress.ps1 [OPTIONS]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Force                  Force recreate cluster even if it exists"
    Write-Host "  -SkipClusterCreation   Skip cluster creation (use existing cluster)"
    Write-Host "  -SkipImageBuild        Skip Docker image building"
    Write-Host "  -SkipIngressSetup      Skip ingress controller setup"
    Write-Host "  -Domain <domain>       Domain name (default: randomcorp.local)"
    Write-Host "  -UseHTTPS              Enable HTTPS with Let's Encrypt"
    Write-Host "  -Email <email>         Email for Let's Encrypt (required with -UseHTTPS)"
    Write-Host "  -Help                  Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\build-cluster-deploy-app-ingress.ps1                           # Basic deployment"
    Write-Host "  .\build-cluster-deploy-app-ingress.ps1 -Domain 'randomcorp.com'  # Custom domain"
    Write-Host "  .\build-cluster-deploy-app-ingress.ps1 -UseHTTPS -Email 'admin@example.com' # HTTPS"
    Write-Host ""
}

if ($Help) {
    Show-Help
    exit 0
}

Write-Host ""
Write-Host "🚀 RandomCorp Ingress-Based Deployment to LKE" -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""

# Step 1: Create or verify LKE cluster with Terraform
if (-not $SkipClusterCreation) {
    Write-Step "1" "Creating/Verifying LKE Cluster with Terraform"
    $originalLocation = Get-Location
    Set-Location ".\infra\terraform"
    
    try {
        if ($Force) {
            & ".\deploy-infrastructure.ps1" -Force
        } else {
            & ".\deploy-infrastructure.ps1"
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Terraform infrastructure deployment failed"
            exit 1
        }
        
        # Set kubeconfig from Terraform output
        $kubeconfigPath = terraform output -raw kubeconfig_path
        $env:KUBECONFIG = $kubeconfigPath
        Write-Success "Cluster ready with Terraform"
    }
    finally {
        Set-Location $originalLocation
    }
} else {
    Write-Step "1" "Skipping cluster creation (using existing cluster)"
    
    # Ensure kubeconfig is set
    $kubeconfigPath = "$env:USERPROFILE\.kube\randomcorp-lke-kubeconfig.yaml"
    if (Test-Path $kubeconfigPath) {
        $env:KUBECONFIG = $kubeconfigPath
        Write-Success "Using existing kubeconfig: $kubeconfigPath"
    } else {
        Write-Error "Kubeconfig not found at $kubeconfigPath"
        exit 1
    }
}

# Step 2: Setup NGINX Ingress Controller
if (-not $SkipIngressSetup) {
    Write-Step "2" "Setting up NGINX Ingress Controller"
    $ingressArgs = @("-Domain", $Domain)
    if ($UseHTTPS) {
        $ingressArgs += "-UseHTTPS"
        if (-not [string]::IsNullOrEmpty($Email)) {
            $ingressArgs += "-Email", $Email
        } else {
            Write-Error "Email is required when using HTTPS"
            exit 1
        }
    }
    
    & ".\infra\linode\setup-ingress.ps1" @ingressArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Ingress setup failed"
        exit 1
    }
    Write-Success "Ingress controller ready"
} else {
    Write-Step "2" "Skipping ingress setup"
}

# Step 3: Build and push Docker images with ingress configuration
if (-not $SkipImageBuild) {
    Write-Step "3" "Building and pushing Docker images"
    & ".\build-lke-images.ps1" -ApiUrl "/api"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Image build failed"
        exit 1
    }
    Write-Success "Images built and pushed"
} else {
    Write-Step "3" "Skipping image build"
}

# Step 4: Install Flux CD
Write-Step "4" "Installing Flux CD"
& ".\infra\linode\install-flux.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Flux installation failed"
    exit 1
}
Write-Success "Flux CD installed"

# Step 5: Update Helm values with domain configuration
Write-Step "5" "Updating Helm values for domain: $Domain"
$valuesPath = ".\helm-charts\randomcorp\values.yaml"
$valuesContent = Get-Content $valuesPath -Raw

# Update domain in values.yaml
$valuesContent = $valuesContent -replace "host: randomcorp\.local", "host: $Domain"

# Update TLS configuration if HTTPS is enabled
if ($UseHTTPS) {
    $valuesContent = $valuesContent -replace "# cert-manager\.io/cluster-issuer:", "cert-manager.io/cluster-issuer:"
    $valuesContent = $valuesContent -replace "# nginx\.ingress\.kubernetes\.io/ssl-redirect:", "nginx.ingress.kubernetes.io/ssl-redirect:"
    $valuesContent = $valuesContent -replace "tls: \[\]", "tls:`n    - secretName: randomcorp-tls`n      hosts:`n        - $Domain"
    $valuesContent = $valuesContent -replace "# tls:", "tls:"
    $valuesContent = $valuesContent -replace "#   - secretName:", "  - secretName:"
    $valuesContent = $valuesContent -replace "#     hosts:", "    hosts:"
    $valuesContent = $valuesContent -replace "#       - randomcorp\.local", "      - $Domain"
}

Set-Content $valuesPath -Value $valuesContent
Write-Success "Helm values updated for domain: $Domain"

# Step 6: Deploy RandomCorp application
Write-Step "6" "Deploying RandomCorp application"
& ".\infra\linode\deploy-app.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Application deployment failed"
    exit 1
}
Write-Success "Application deployed"

# Step 7: Verify deployment and show access information
Write-Step "7" "Verifying deployment"

Write-Host ""
Write-Host "⏳ Waiting for application to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Get ingress IP
$ingressIP = kubectl get service ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null

if ($ingressIP) {
    Write-Host ""
    Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Access Information:" -ForegroundColor Cyan
    Write-Host "  Ingress IP: $ingressIP" -ForegroundColor White
    Write-Host "  Domain: $Domain" -ForegroundColor White
    
    $protocol = if ($UseHTTPS) { "https" } else { "http" }
    
    Write-Host ""
    Write-Host "🌐 Application URLs:" -ForegroundColor Cyan
    Write-Host "  Frontend: $protocol`://$Domain/" -ForegroundColor Green
    Write-Host "  API: $protocol`://$Domain/api/" -ForegroundColor Green
    Write-Host "  API Docs: $protocol`://$Domain/api/docs" -ForegroundColor Green
    Write-Host ""
    
    if ($Domain -like "*.local") {
        Write-Host "📝 Add this to your hosts file:" -ForegroundColor Yellow
        Write-Host "   $ingressIP $Domain" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "   Windows: C:\Windows\System32\drivers\etc\hosts" -ForegroundColor Gray
        Write-Host "   Linux/Mac: /etc/hosts" -ForegroundColor Gray
    } else {
        Write-Host "🌐 Ensure DNS A record points to: $ingressIP" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "✅ RandomCorp is now running with ingress-based routing!" -ForegroundColor Green
    Write-Host "   No more two-step build process needed! 🎊" -ForegroundColor Green
} else {
    Write-Warning "Could not retrieve ingress IP. Check ingress controller status."
}

Write-Host ""
