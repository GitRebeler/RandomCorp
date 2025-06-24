# Setup kubectl for LKE cluster
Write-Host "Setting up kubectl for LKE cluster..." -ForegroundColor Green

# Check if kubeconfig files exist
$kubeconfigPath = Join-Path $PSScriptRoot "kubeconfig-randomcorp-lke-decoded.yaml"
$kubeconfigEncodedPath = Join-Path $PSScriptRoot "kubeconfig-randomcorp-lke.yaml"

if (Test-Path $kubeconfigPath) {
    Write-Host "Found kubeconfig file: kubeconfig-randomcorp-lke-decoded.yaml" -ForegroundColor Green
    $env:KUBECONFIG = $kubeconfigPath
} elseif (Test-Path $kubeconfigEncodedPath) {
    Write-Host "Found encoded kubeconfig file: kubeconfig-randomcorp-lke.yaml" -ForegroundColor Yellow
    Write-Host "Please use the decoded version: kubeconfig-randomcorp-lke-decoded.yaml" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "No kubeconfig file found!" -ForegroundColor Red
    Write-Host "Please download your LKE kubeconfig file and place it in the project root." -ForegroundColor Yellow
    exit 1
}

# Test connection
Write-Host "Testing connection to LKE cluster..." -ForegroundColor Cyan
try {
    kubectl cluster-info --request-timeout=10s
    Write-Host "Successfully connected to LKE cluster!" -ForegroundColor Green
    
    # Show current context
    $context = kubectl config current-context
    Write-Host "Current context: $context" -ForegroundColor Yellow
    
    # Show nodes
    Write-Host "Cluster nodes:" -ForegroundColor Cyan
    kubectl get nodes
    
} catch {
    Write-Host "Failed to connect to LKE cluster!" -ForegroundColor Red
    Write-Host "Please check your kubeconfig file and network connection." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "kubectl is configured for LKE!" -ForegroundColor Green
Write-Host "You can now run: .\deploy-lke.ps1" -ForegroundColor Cyan
