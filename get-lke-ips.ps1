# Get LoadBalancer IPs for RandomCorp LKE deployment
Write-Host "🌐 Getting LoadBalancer IPs for RandomCorp..." -ForegroundColor Green

$namespace = "default"

# Get Frontend LoadBalancer IP
Write-Host "🎨 Frontend Service:" -ForegroundColor Cyan
$frontendIP = kubectl get service randomcorp-frontend -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if (![string]::IsNullOrEmpty($frontendIP)) {
    Write-Host "  Status: ✅ Ready" -ForegroundColor Green
    Write-Host "  URL: http://$frontendIP" -ForegroundColor Green
    Write-Host "  IP: $frontendIP" -ForegroundColor Yellow
} else {
    Write-Host "  Status: ⏳ LoadBalancer IP not yet assigned" -ForegroundColor Yellow
}

Write-Host ""

# Get API LoadBalancer IP
Write-Host "🔌 API Service:" -ForegroundColor Cyan
$apiIP = kubectl get service randomcorp -n $namespace -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>$null
if (![string]::IsNullOrEmpty($apiIP)) {
    Write-Host "  Status: ✅ Ready" -ForegroundColor Green
    Write-Host "  URL: http://$apiIP" -ForegroundColor Green
    Write-Host "  Health Check: http://$apiIP/health" -ForegroundColor Green
    Write-Host "  IP: $apiIP" -ForegroundColor Yellow
} else {
    Write-Host "  Status: ⏳ LoadBalancer IP not yet assigned" -ForegroundColor Yellow
}

Write-Host ""

# Show all services
Write-Host "📊 All Services:" -ForegroundColor Cyan
kubectl get services -n $namespace

Write-Host ""

# If we have the API IP, test it
if (![string]::IsNullOrEmpty($apiIP)) {
    Write-Host "🩺 Testing API health..." -ForegroundColor Cyan
    try {
        $healthResponse = Invoke-RestMethod -Uri "http://$apiIP/health" -Method GET -TimeoutSec 10
        Write-Host "  ✅ API is healthy: $($healthResponse.status)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️ API not yet responding (this is normal during startup)" -ForegroundColor Yellow
    }
}

Write-Host ""

# Check if we need to rebuild frontend with correct API URL
if (![string]::IsNullOrEmpty($apiIP)) {
    $currentApiUrl = "http://api.randomcorp.lke"
    $actualApiUrl = "http://$apiIP"
    
    if ($currentApiUrl -ne $actualApiUrl) {
        Write-Host "⚠️ IMPORTANT: Frontend was built with placeholder API URL" -ForegroundColor Yellow
        Write-Host "   Current: $currentApiUrl" -ForegroundColor Yellow
        Write-Host "   Actual:  $actualApiUrl" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "🔄 To update the frontend with the correct API URL:" -ForegroundColor Cyan
        Write-Host "   1. Run: .\build-lke-images.ps1" -ForegroundColor White
        Write-Host "   2. Enter the API URL: $actualApiUrl" -ForegroundColor White
        Write-Host "   3. Run: .\deploy-lke.ps1" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "📋 Useful Commands:" -ForegroundColor Yellow
Write-Host "  kubectl get pods -n $namespace" -ForegroundColor White
Write-Host "  kubectl logs -f deployment/randomcorp -n $namespace" -ForegroundColor White
Write-Host "  kubectl logs -f deployment/randomcorp-frontend -n $namespace" -ForegroundColor White
