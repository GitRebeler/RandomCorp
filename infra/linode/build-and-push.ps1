# PowerShell script to build and push Docker images to a container registry
# Supports Docker Hub, Linode Container Registry, or other registries

param(
    [string]$Registry = "docker.io/johnhebeler",
    [string]$ApiImageName = "randomcorp",
    [string]$FrontendImageName = "randomcorp-frontend",
    [string]$Tag = "latest",
    [string]$ApiUrl = ""
)

Write-Host "Building and pushing Random Corp Docker images" -ForegroundColor Green
Write-Host "Registry: $Registry"
Write-Host "API Image: $Registry/$ApiImageName`:$Tag"
Write-Host "Frontend Image: $Registry/$FrontendImageName`:$Tag"
if ($ApiUrl) {
    Write-Host "Frontend API URL: $ApiUrl" -ForegroundColor Cyan
}
Write-Host ""

# Check if Docker is running
try {
    $null = & docker info 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker info command failed"
    }
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Docker is not running. Please start Docker." -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Validate paths before building
$apiPath = "..\..\api"
$rootPath = "..\.."
$apiDockerfile = "$apiPath\Dockerfile"
$frontendDockerfile = "$rootPath\Dockerfile"

Write-Host "Validating paths..." -ForegroundColor Cyan
Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
Write-Host "API path: $apiPath" -ForegroundColor Gray
Write-Host "Root path: $rootPath" -ForegroundColor Gray

if (-not (Test-Path $apiDockerfile)) {
    Write-Host "API Dockerfile not found at: $apiDockerfile" -ForegroundColor Red
    exit 1
}
Write-Host "API Dockerfile found" -ForegroundColor Green

if (-not (Test-Path $frontendDockerfile)) {
    Write-Host "Frontend Dockerfile not found at: $frontendDockerfile" -ForegroundColor Red
    exit 1
}
Write-Host "Frontend Dockerfile found" -ForegroundColor Green
Write-Host ""

# Build API image
Write-Host "Building API image..." -ForegroundColor Yellow
Write-Host "Changing to API directory: $apiPath" -ForegroundColor Gray
$originalLocation = Get-Location
try {
    Set-Location $apiPath
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    Write-Host "Running: docker build -t `"$Registry/$ApiImageName`:$Tag`" ." -ForegroundColor Gray
    
    & docker build -t "$Registry/$ApiImageName`:$Tag" .
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for API with exit code: $LASTEXITCODE"
    }
    Write-Host "API image built successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to build API image: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location $originalLocation
    exit 1
} finally {
    Set-Location $originalLocation
}

# Build Frontend image  
Write-Host "Building Frontend image..." -ForegroundColor Yellow
Write-Host "Changing to root directory: $rootPath" -ForegroundColor Gray
$originalLocation = Get-Location
try {
    Set-Location $rootPath
    Write-Host "Current directory: $(Get-Location)" -ForegroundColor Gray
    
    # Prepare build command with API URL if provided
    $buildCommand = "docker build -t `"$Registry/$FrontendImageName`:$Tag`""
    if ($ApiUrl) {
        $buildCommand += " --build-arg REACT_APP_API_URL=`"$ApiUrl`""
        Write-Host "Using API URL: $ApiUrl" -ForegroundColor Cyan
    } else {
        Write-Host "No API URL provided - frontend will use relative URLs" -ForegroundColor Yellow
    }
    $buildCommand += " ."
    
    Write-Host "Running: $buildCommand" -ForegroundColor Gray
    Invoke-Expression $buildCommand
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for Frontend with exit code: $LASTEXITCODE"
    }
    Write-Host "Frontend image built successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to build Frontend image: $($_.Exception.Message)" -ForegroundColor Red
    Set-Location $originalLocation
    exit 1
} finally {
    Set-Location $originalLocation
}

# Push images
Write-Host "Pushing images to registry..." -ForegroundColor Yellow

Write-Host "Pushing API image..." -ForegroundColor Yellow
try {
    & docker push "$Registry/$ApiImageName`:$Tag"
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed for API with exit code: $LASTEXITCODE"
    }
    Write-Host "API image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to push API image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "Pushing Frontend image..." -ForegroundColor Yellow
try {
    & docker push "$Registry/$FrontendImageName`:$Tag"
    if ($LASTEXITCODE -ne 0) {
        throw "Docker push failed for Frontend with exit code: $LASTEXITCODE"
    }
    Write-Host "Frontend image pushed successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to push Frontend image: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "All images built and pushed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Update these values in your Helm chart (helm-charts/randomcorp/values.yaml):" -ForegroundColor Cyan
Write-Host "  image.repository: $Registry/$ApiImageName"
Write-Host "  frontend.image.repository: $Registry/$FrontendImageName"
Write-Host ""
Write-Host "Ready to deploy with Flux!" -ForegroundColor Green
