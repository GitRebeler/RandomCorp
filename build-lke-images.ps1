# Build and push Docker images for LKE deployment
#
# Usage Examples:
#   .\build-lke-images.ps1
#   .\build-lke-images.ps1 -NoCache
#   .\build-lke-images.ps1 -ApiUrl "http://139.144.241.105"
#   .\build-lke-images.ps1 -ForceUpdate -ApiUrl "http://139.144.241.105"
#   .\build-lke-images.ps1 -NoCache -ForceUpdate -ApiUrl "http://139.144.241.105"
#
param(
    [switch]$NoCache,
    [string]$ApiUrl = "",
    [switch]$ForceUpdate
)

Write-Host "🏗️ Building RandomCorp images for LKE deployment..." -ForegroundColor Green

# Set variables
$DOCKER_REGISTRY = "docker.io/johnhebeler"
$API_IMAGE = "$DOCKER_REGISTRY/randomcorp"
$FRONTEND_IMAGE = "$DOCKER_REGISTRY/randomcorp-frontend"
$TAG = "latest"

# Determine cache flags
$CACHE_FLAG = if ($NoCache) { "--no-cache" } else { "" }
if ($NoCache) {
    Write-Host "🚫 Using --no-cache flag for complete rebuild" -ForegroundColor Yellow
}

# Get LoadBalancer IP or use provided URL
if ([string]::IsNullOrEmpty($ApiUrl)) {
    $API_URL = Read-Host "Enter the API LoadBalancer URL (or press Enter for default: http://api.randomcorp.lke)"
    if ([string]::IsNullOrEmpty($API_URL)) {
        $API_URL = "http://api.randomcorp.lke"
    }
} else {
    $API_URL = $ApiUrl
}

Write-Host "📝 Using API URL: $API_URL" -ForegroundColor Yellow

# Build API image
Write-Host "🔨 Building API image..." -ForegroundColor Cyan
if ($NoCache) {
    docker build --no-cache -t "$API_IMAGE`:$TAG" -f api/Dockerfile api/
} else {
    docker build -t "$API_IMAGE`:$TAG" -f api/Dockerfile api/
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ API build failed!" -ForegroundColor Red
    exit 1
}

# Build Frontend image with correct API URL
Write-Host "🔨 Building Frontend image with API URL: $API_URL..." -ForegroundColor Cyan
if ($NoCache) {
    docker build --no-cache -t "$FRONTEND_IMAGE`:$TAG" --build-arg REACT_APP_API_URL="$API_URL" .
} else {
    docker build -t "$FRONTEND_IMAGE`:$TAG" --build-arg REACT_APP_API_URL="$API_URL" .
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed!" -ForegroundColor Red
    exit 1
}

# Push images
Write-Host "📤 Pushing images to registry..." -ForegroundColor Cyan

Write-Host "  Pushing API image..." -ForegroundColor Yellow
docker push "$API_IMAGE`:$TAG"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ API push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  Pushing Frontend image..." -ForegroundColor Yellow
docker push "$FRONTEND_IMAGE`:$TAG"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Images built and pushed successfully!" -ForegroundColor Green
Write-Host "🏷️ API Image: $API_IMAGE`:$TAG" -ForegroundColor Cyan
Write-Host "🏷️ Frontend Image: $FRONTEND_IMAGE`:$TAG" -ForegroundColor Cyan

# Force Kubernetes to pull new images if requested
if ($ForceUpdate) {
    Write-Host ""
    Write-Host "🔄 Forcing Kubernetes to pull new images..." -ForegroundColor Cyan
    
    # Check if kubectl is available
    try {
        kubectl version --client=true --output=json | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   Deleting frontend pods to force recreation..." -ForegroundColor Yellow
            kubectl delete pods -l app.kubernetes.io/component=frontend -n default --ignore-not-found=true
            
            Write-Host "   Deleting API pods to force recreation..." -ForegroundColor Yellow  
            kubectl delete pods -l app.kubernetes.io/component=api -n default --ignore-not-found=true
            
            Write-Host "✅ Pod deletion complete. New pods will be created with updated images." -ForegroundColor Green
        } else {
            Write-Host "⚠️ kubectl not available. Please manually delete pods to force update." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Could not connect to Kubernetes cluster. Please manually delete pods to force update." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "💡 To force Kubernetes to pull the new image (same tag), you can:" -ForegroundColor Yellow
Write-Host "   Option 1: Use -ForceUpdate flag with this script" -ForegroundColor White
Write-Host "   .\build-lke-images.ps1 -ForceUpdate -ApiUrl 'http://your-api-ip'" -ForegroundColor Gray
Write-Host ""
Write-Host "   Option 2: Manually delete pods to trigger recreation" -ForegroundColor White
Write-Host "   kubectl delete pods -l app.kubernetes.io/component=frontend -n default" -ForegroundColor Gray
Write-Host ""
Write-Host "   Option 3: Use imagePullPolicy: Always in your deployment" -ForegroundColor White
Write-Host "   This ensures Kubernetes always pulls the latest image" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy to LKE using: .\deploy-lke.ps1" -ForegroundColor White
Write-Host "2. Get LoadBalancer IPs and update DNS/API URLs if needed" -ForegroundColor White
