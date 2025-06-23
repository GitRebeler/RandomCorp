# PowerShell script to build and push Docker images to a container registry
# Supports Docker Hub, Linode Container Registry, or other registries

param(
    [string]$Registry = "your-registry",  # e.g., "docker.io/yourusername" or "us-east-1.linodeobjects.com/your-registry"
    [string]$ApiImageName = "randomcorp",
    [string]$FrontendImageName = "randomcorp-frontend",
    [string]$Tag = "latest"
)

Write-Host "🐳 Building and pushing Random Corp Docker images" -ForegroundColor Green
Write-Host "Registry: $Registry"
Write-Host "API Image: $Registry/$ApiImageName`:$Tag"
Write-Host "Frontend Image: $Registry/$FrontendImageName`:$Tag"
Write-Host ""

# Check if Docker is running
try {
    $null = & docker info 2>$null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker." -ForegroundColor Red
    exit 1
}

# Build API image
Write-Host "🔨 Building API image..." -ForegroundColor Yellow
try {
    Set-Location api
    & docker build -t "$Registry/$ApiImageName`:$Tag" .
    Write-Host "✅ API image built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to build API image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Set-Location ..
}

# Build Frontend image  
Write-Host "🔨 Building Frontend image..." -ForegroundColor Yellow
try {
    & docker build -t "$Registry/$FrontendImageName`:$Tag" .
    Write-Host "✅ Frontend image built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to build Frontend image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Push images
Write-Host "📤 Pushing images to registry..." -ForegroundColor Yellow

Write-Host "📤 Pushing API image..." -ForegroundColor Yellow
try {
    & docker push "$Registry/$ApiImageName`:$Tag"
    Write-Host "✅ API image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to push API image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "📤 Pushing Frontend image..." -ForegroundColor Yellow
try {
    & docker push "$Registry/$FrontendImageName`:$Tag"
    Write-Host "✅ Frontend image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to push Frontend image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 All images built and pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Update these values in your Helm chart (helm-charts/randomcorp/values.yaml):" -ForegroundColor Cyan
Write-Host "  image.repository: $Registry/$ApiImageName"
Write-Host "  frontend.image.repository: $Registry/$FrontendImageName"
Write-Host ""
Write-Host "🚀 Ready to deploy with Flux!" -ForegroundColor Green
