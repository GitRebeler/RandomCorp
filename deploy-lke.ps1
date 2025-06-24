# Deploy RandomCorp to LKE (Linode Kubernetes Engine)
Write-Host "🚀 Deploying RandomCorp to LKE..." -ForegroundColor Green

# Check if kubectl is available and configured
try {
    $kubectl_version = kubectl version --client=true --output=json | ConvertFrom-Json
    Write-Host "✅ kubectl found: $($kubectl_version.clientVersion.gitVersion)" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl not found or not configured!" -ForegroundColor Red
    Write-Host "Please install kubectl and configure it for your LKE cluster." -ForegroundColor Yellow
    exit 1
}

# Check if connected to cluster
try {
    kubectl cluster-info 2>$null | Out-Null
    Write-Host "✅ Connected to Kubernetes cluster" -ForegroundColor Green
} catch {
    Write-Host "❌ Not connected to Kubernetes cluster!" -ForegroundColor Red
    Write-Host "Please configure your kubeconfig file." -ForegroundColor Yellow
    exit 1
}

# Navigate to helm chart directory
$helmChartPath = Join-Path $PSScriptRoot "helm-charts\randomcorp"
if (-not (Test-Path $helmChartPath)) {
    Write-Host "❌ Helm chart not found at: $helmChartPath" -ForegroundColor Red
    exit 1
}

Set-Location $helmChartPath

# Update Helm dependencies
Write-Host "📦 Updating Helm dependencies..." -ForegroundColor Cyan
helm dependency update

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Helm dependency update failed!" -ForegroundColor Red
    exit 1
}

# Deploy or upgrade the application
$releaseName = "randomcorp"
$namespace = "default"

Write-Host "🎯 Deploying to LKE cluster..." -ForegroundColor Cyan
helm upgrade --install $releaseName . -n $namespace --wait --timeout=10m

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Helm deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Deployment successful!" -ForegroundColor Green

# Get service information
Write-Host "📊 Getting service information..." -ForegroundColor Cyan
kubectl get services -n $namespace

Write-Host ""
Write-Host "🌐 Getting LoadBalancer IPs (this may take a few minutes)..." -ForegroundColor Yellow
Write-Host "Frontend Service:" -ForegroundColor Cyan
kubectl get service randomcorp-frontend -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if ($LASTEXITCODE -eq 0) {
    $frontendIP = kubectl get service randomcorp-frontend -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if (![string]::IsNullOrEmpty($frontendIP)) {
        Write-Host "Frontend URL: http://$frontendIP" -ForegroundColor Green
    } else {
        Write-Host "LoadBalancer IP not yet assigned. Check again in a few minutes." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "API Service:" -ForegroundColor Cyan
kubectl get service randomcorp -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if ($LASTEXITCODE -eq 0) {
    $apiIP = kubectl get service randomcorp -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
    if (![string]::IsNullOrEmpty($apiIP)) {
        Write-Host "API URL: http://$apiIP" -ForegroundColor Green
    } else {
        Write-Host "LoadBalancer IP not yet assigned. Check again in a few minutes." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "📋 To monitor the deployment:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace" -ForegroundColor White
Write-Host "  kubectl logs -f deployment/randomcorp -n $namespace" -ForegroundColor White
Write-Host "  kubectl logs -f deployment/randomcorp-frontend -n $namespace" -ForegroundColor White

Write-Host ""
Write-Host "🔧 To update LoadBalancer IPs later:" -ForegroundColor Yellow
Write-Host "  kubectl get services -n $namespace" -ForegroundColor White
