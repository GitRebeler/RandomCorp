# Setup script for GitHub Container Registry (GHCR) as alternative to Docker Hub
# Run this if you want to use GitHub Container Registry instead of Docker Hub

param(
    [string]$GitHubUsername = "gitrebeler",
    [string]$ImageTag = "latest"
)

Write-Host "=== GitHub Container Registry Setup ===" -ForegroundColor Green
Write-Host ""

# Check if GitHub CLI is installed
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Host "GitHub CLI (gh) not found. Installing..." -ForegroundColor Yellow
    winget install GitHub.cli
    Write-Host "Please restart your terminal and run this script again." -ForegroundColor Yellow
    exit 1
}

# Login to GitHub Container Registry
Write-Host "Logging into GitHub Container Registry..." -ForegroundColor Cyan
Write-Output $env:GITHUB_TOKEN | docker login ghcr.io -u $GitHubUsername --password-stdin

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Successfully logged into ghcr.io" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to login to ghcr.io" -ForegroundColor Red
    Write-Host "Make sure you have GITHUB_TOKEN environment variable set" -ForegroundColor Yellow
    Write-Host "Create token at: https://github.com/settings/tokens" -ForegroundColor Yellow
    Write-Host "Required scopes: write:packages, read:packages" -ForegroundColor Yellow
    exit 1
}

# Build and push backend
Write-Host ""
Write-Host "Building and pushing backend image..." -ForegroundColor Cyan
docker build -t "ghcr.io/$GitHubUsername/randomcorp:$ImageTag" ./backend
docker push "ghcr.io/$GitHubUsername/randomcorp:$ImageTag"

# Build and push frontend  
Write-Host ""
Write-Host "Building and pushing frontend image..." -ForegroundColor Cyan
docker build -t "ghcr.io/$GitHubUsername/randomcorp-frontend:$ImageTag" ./frontend
docker push "ghcr.io/$GitHubUsername/randomcorp-frontend:$ImageTag"

Write-Host ""
Write-Host "=== GitHub Container Registry Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Images pushed to:" -ForegroundColor White
Write-Host "  - ghcr.io/$GitHubUsername/randomcorp:$ImageTag" -ForegroundColor Gray
Write-Host "  - ghcr.io/$GitHubUsername/randomcorp-frontend:$ImageTag" -ForegroundColor Gray
Write-Host ""
Write-Host "To use GHCR, update your values.yaml:" -ForegroundColor Yellow
Write-Host "  repository: ghcr.io/$GitHubUsername/randomcorp" -ForegroundColor Gray
Write-Host "  frontendRepository: ghcr.io/$GitHubUsername/randomcorp-frontend" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Update helm-charts/randomcorp/values.yaml" -ForegroundColor White
Write-Host "2. Run: .\deploy-app.ps1" -ForegroundColor White
