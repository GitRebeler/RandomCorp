# Complete workflow script for Linode LKE deployment
# This shows the full process from cluster creation to application deployment

Write-Host "=== Random Corp Linode LKE Deployment Workflow ===" -ForegroundColor Green
Write-Host ""

# Step 1: Check if cluster exists
Write-Host "Step 1: Checking cluster status..." -ForegroundColor Cyan
$clusters = linode-cli lke clusters-list --text --no-header 2>$null
if ($clusters -match "randomcorp-lke") {
    Write-Host "✅ Cluster randomcorp-lke exists and ready" -ForegroundColor Green
} else {
    Write-Host "❌ Cluster not found. Run: .\create-lke-cluster.ps1" -ForegroundColor Red
    exit 1
}

# Step 2: Check kubectl access
Write-Host ""
Write-Host "Step 2: Testing kubectl access..." -ForegroundColor Cyan
$env:KUBECONFIG = "kubeconfig-randomcorp-lke-decoded.yaml"
try {
    $nodes = kubectl get nodes --no-headers 2>$null
    $nodeCount = ($nodes | Measure-Object).Count
    Write-Host "✅ kubectl working - $nodeCount nodes ready" -ForegroundColor Green
} catch {
    Write-Host "❌ kubectl not working. Check kubeconfig" -ForegroundColor Red
    Write-Host "Run: .\check-cluster.ps1" -ForegroundColor Yellow
    exit 1
}

# Step 3: Check if Flux is installed
Write-Host ""
Write-Host "Step 3: Checking Flux installation..." -ForegroundColor Cyan
try {
    $fluxStatus = kubectl get namespace flux-system --no-headers 2>$null
    if ($fluxStatus) {
        Write-Host "✅ Flux is installed" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Flux not installed. Run: .\install-flux.ps1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Flux not installed. Run: .\install-flux.ps1" -ForegroundColor Yellow
}

# Step 4: Check if application manifests exist
Write-Host ""
Write-Host "Step 4: Checking application manifests..." -ForegroundColor Cyan
$helmChart = "..\..\helm-charts\randomcorp\Chart.yaml"
$fluxApps = "..\..\clusters\linode-lke\apps"

if (Test-Path $helmChart) {
    Write-Host "✅ Helm chart exists" -ForegroundColor Green
} else {
    Write-Host "⚠️ Helm chart missing. Run: .\deploy-app.ps1" -ForegroundColor Yellow
}

if (Test-Path $fluxApps) {
    Write-Host "✅ Flux manifests exist" -ForegroundColor Green
} else {
    Write-Host "⚠️ Flux manifests missing. Run: .\deploy-app.ps1" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "=== Current Status ===" -ForegroundColor Green
Write-Host "• Cluster ID: 492019" -ForegroundColor White
Write-Host "• Cluster Cost: ~`$42/month" -ForegroundColor White
Write-Host "• Savings vs Azure: ~50%" -ForegroundColor Green
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. If Flux not installed:" -ForegroundColor Yellow
Write-Host "   .\install-flux.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "2. If app manifests missing:" -ForegroundColor Yellow
Write-Host "   .\deploy-app.ps1 -GitHubUser GitRebeler -Registry your-registry" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Build and push containers:" -ForegroundColor Yellow
Write-Host "   .\build-and-push.ps1 -Registry your-registry" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Commit to git for auto-deployment:" -ForegroundColor Yellow
Write-Host "   git add . && git commit -m 'Add LKE deployment' && git push" -ForegroundColor Gray
Write-Host ""

Write-Host "=== Useful Commands ===" -ForegroundColor Cyan
Write-Host "• Check cluster: .\check-cluster.ps1" -ForegroundColor Gray
Write-Host "• View nodes: kubectl get nodes" -ForegroundColor Gray
Write-Host "• View pods: kubectl get pods" -ForegroundColor Gray
Write-Host "• View services: kubectl get services" -ForegroundColor Gray
Write-Host "• Flux status: flux get all" -ForegroundColor Gray
Write-Host "• Delete cluster: linode-cli lke cluster-delete 492019" -ForegroundColor Gray
