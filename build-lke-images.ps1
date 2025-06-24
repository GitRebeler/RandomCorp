# Build and push Docker images for LKE deployment
Write-Host "🏗️ Building RandomCorp images for LKE deployment..." -ForegroundColor Green

# Set variables
$DOCKER_REGISTRY = "docker.io/johnhebeler"
$API_IMAGE = "$DOCKER_REGISTRY/randomcorp"
$FRONTEND_IMAGE = "$DOCKER_REGISTRY/randomcorp-frontend"
$TAG = "latest"

# Get LoadBalancer IP or use placeholder for now
$API_URL = Read-Host "Enter the API LoadBalancer URL (or press Enter for default: http://api.randomcorp.lke)"
if ([string]::IsNullOrEmpty($API_URL)) {
    $API_URL = "http://api.randomcorp.lke"
}

Write-Host "📝 Using API URL: $API_URL" -ForegroundColor Yellow

# Build API image
Write-Host "🔨 Building API image..." -ForegroundColor Cyan
docker build -t "$API_IMAGE`:$TAG" -f api/Dockerfile api/

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ API build failed!" -ForegroundColor Red
    exit 1
}

# Build Frontend image with correct API URL
Write-Host "🔨 Building Frontend image with API URL: $API_URL..." -ForegroundColor Cyan
docker build -t "$FRONTEND_IMAGE`:$TAG" --build-arg REACT_APP_API_URL="$API_URL" .

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
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy to LKE using: .\deploy-lke.ps1" -ForegroundColor White
Write-Host "2. Get LoadBalancer IPs and update DNS/API URLs if needed" -ForegroundColor White
