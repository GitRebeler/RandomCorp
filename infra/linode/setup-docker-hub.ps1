# PowerShell script to build and push Random Corp images to Docker Hub
# This script helps you get started with Docker Hub as your container registry

param(
    [string]$DockerHubUsername = "gitrebeler",  # Your Docker Hub username
    [string]$Tag = "latest"
)

Write-Host "=== Random Corp Container Registry Setup ===" -ForegroundColor Green
Write-Host "Using Docker Hub registry: docker.io/$DockerHubUsername" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
    Write-Host "✅ Docker is running (version: $dockerVersion)" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check if logged in to Docker Hub
Write-Host "Checking Docker Hub authentication..." -ForegroundColor Yellow
$authCheck = docker info 2>&1 | Select-String "Username"
if ($authCheck) {
    Write-Host "✅ Logged in to Docker Hub" -ForegroundColor Green
} else {
    Write-Host "⚠️ Not logged in to Docker Hub" -ForegroundColor Yellow
    Write-Host "Please run: docker login" -ForegroundColor Cyan
    Write-Host ""
    $response = Read-Host "Do you want to login now? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        docker login
    } else {
        Write-Host "Please login manually and run this script again" -ForegroundColor Yellow
        exit 1
    }
}

# Build API image
Write-Host ""
Write-Host "Building API image..." -ForegroundColor Yellow
$apiImage = "docker.io/$DockerHubUsername/randomcorp:$Tag"

try {
    Set-Location "..\..\api"
    Write-Host "Building: $apiImage" -ForegroundColor Cyan
    docker build -t $apiImage .
    Write-Host "✅ API image built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to build API image" -ForegroundColor Red
    exit 1
} finally {
    Set-Location "..\infra\linode"
}

# Build Frontend image
Write-Host ""
Write-Host "Building Frontend image..." -ForegroundColor Yellow
$frontendImage = "docker.io/$DockerHubUsername/randomcorp-frontend:$Tag"

try {
    Set-Location "..\.."
    Write-Host "Building: $frontendImage" -ForegroundColor Cyan
    docker build -t $frontendImage .
    Write-Host "✅ Frontend image built successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to build Frontend image" -ForegroundColor Red
    exit 1
} finally {
    Set-Location "infra\linode"
}

# Push images to Docker Hub
Write-Host ""
Write-Host "Pushing images to Docker Hub..." -ForegroundColor Yellow

Write-Host "Pushing API image..." -ForegroundColor Cyan
try {
    docker push $apiImage
    Write-Host "✅ API image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to push API image" -ForegroundColor Red
    exit 1
}

Write-Host "Pushing Frontend image..." -ForegroundColor Cyan
try {
    docker push $frontendImage
    Write-Host "✅ Frontend image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to push Frontend image" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== SUCCESS: Images pushed to Docker Hub! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Published images:" -ForegroundColor Cyan
Write-Host "• API: $apiImage" -ForegroundColor White
Write-Host "• Frontend: $frontendImage" -ForegroundColor White
Write-Host ""
Write-Host "Docker Hub URLs:" -ForegroundColor Cyan
Write-Host "• https://hub.docker.com/r/$DockerHubUsername/randomcorp" -ForegroundColor Gray
Write-Host "• https://hub.docker.com/r/$DockerHubUsername/randomcorp-frontend" -ForegroundColor Gray
Write-Host ""
Write-Host "Your Helm values.yaml is already configured to use these images!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Install Flux: .\install-flux.ps1" -ForegroundColor White
Write-Host "2. Commit and push to git for auto-deployment" -ForegroundColor White
Write-Host "3. Monitor deployment: kubectl get pods" -ForegroundColor White
