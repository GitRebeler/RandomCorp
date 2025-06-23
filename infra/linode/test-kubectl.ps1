# Test kubectl connectivity and cluster readiness
Write-Host "=== Kubernetes Cluster Test ===" -ForegroundColor Green
Write-Host ""

# Check if KUBECONFIG is set
if (-not $env:KUBECONFIG) {
    Write-Host "Setting KUBECONFIG..." -ForegroundColor Yellow
    $env:KUBECONFIG = "$(Get-Location)\kubeconfig-randomcorp.yaml"
}

Write-Host "KUBECONFIG: $env:KUBECONFIG" -ForegroundColor Gray
Write-Host ""

# Test basic connectivity
Write-Host "Testing cluster connectivity..." -ForegroundColor Cyan
try {
    $nodes = kubectl get nodes --no-headers 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Cluster connection successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Cluster Nodes:" -ForegroundColor Cyan
        kubectl get nodes
        Write-Host ""
        
        Write-Host "Cluster Info:" -ForegroundColor Cyan
        kubectl cluster-info
        Write-Host ""
        
        Write-Host "Available Namespaces:" -ForegroundColor Cyan
        kubectl get namespaces
        Write-Host ""
        
        Write-Host "✅ Cluster is ready for deployment!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Deploy app: .\deploy-app.ps1" -ForegroundColor White
        Write-Host "2. Setup GitOps: .\install-flux.ps1" -ForegroundColor White
        Write-Host "3. Build images: .\setup-docker-hub.ps1" -ForegroundColor White
        
    } else {
        Write-Host "❌ Cluster connection failed" -ForegroundColor Red
        Write-Host "Error: $nodes" -ForegroundColor Red
        Write-Host ""
        Write-Host "Try running: .\check-cluster.ps1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error testing cluster: $($_.Exception.Message)" -ForegroundColor Red
}
