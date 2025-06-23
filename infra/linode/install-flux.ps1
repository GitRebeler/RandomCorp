# PowerShell script to install Flux v2 on Linode LKE cluster
# This sets up GitOps for continuous deployment

param(
    [string]$GitHubUser = "GitRebeler",  # Change this!
    [string]$GitHubRepo = "RandomCorp",
    [string]$GitHubTokenFile = "github-token.txt",  # Create this file with your GitHub token
    [string]$FluxNamespace = "flux-system"
)

Write-Host "Installing Flux v2 for GitOps deployment" -ForegroundColor Green
Write-Host ""

# Check prerequisites
try {
    $null = & kubectl version --client 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl version check failed"
    }
    Write-Host "kubectl found" -ForegroundColor Green
} catch {
    Write-Host "kubectl not found. Please install kubectl." -ForegroundColor Red
    exit 1
}

try {
    $null = & flux version --client 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "flux version check failed"
    }
    Write-Host "flux CLI found" -ForegroundColor Green
} catch {
    Write-Host "flux CLI not found. Please install:" -ForegroundColor Red
    Write-Host "# Windows (using Chocolatey):"
    Write-Host "choco install flux"
    Write-Host ""
    Write-Host "# Or download from: https://github.com/fluxcd/flux2/releases"
    exit 1
}

# Check GitHub token
if (-not (Test-Path $GitHubTokenFile)) {
    Write-Host "GitHub token file not found: $GitHubTokenFile" -ForegroundColor Red
    Write-Host "Create this file with your GitHub Personal Access Token" -ForegroundColor Yellow
    Write-Host "Token needs 'repo' permissions" -ForegroundColor Yellow
    exit 1
}

$GitHubToken = Get-Content $GitHubTokenFile -Raw
$GitHubToken = $GitHubToken.Trim()

# Check cluster connection
Write-Host "Checking cluster connection..." -ForegroundColor Yellow
try {
    $nodes = & kubectl get nodes 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "kubectl get nodes failed"
    }
    Write-Host "Connected to cluster:" -ForegroundColor Green
    Write-Host $nodes
} catch {
    Write-Host "Cannot connect to cluster. Check your kubeconfig:" -ForegroundColor Red
    Write-Host "`$env:KUBECONFIG = `"$(Get-Location)\kubeconfig-randomcorp-lke-decoded.yaml`"" -ForegroundColor Cyan
    exit 1
}

# Pre-flight check
Write-Host ""
Write-Host "Running Flux pre-flight check..." -ForegroundColor Yellow
try {
    & flux check --pre
    if ($LASTEXITCODE -ne 0) {
        throw "flux pre-flight check failed"
    }
    Write-Host "Pre-flight check passed" -ForegroundColor Green
} catch {
    Write-Host "Pre-flight check failed" -ForegroundColor Red
    exit 1
}

# Bootstrap Flux
Write-Host ""
Write-Host "Bootstrapping Flux..." -ForegroundColor Yellow

try {
    $env:GITHUB_TOKEN = $GitHubToken
    & flux bootstrap github --owner=$GitHubUser --repository=$GitHubRepo --branch=master --path=clusters/linode-lke --personal --token-auth
    if ($LASTEXITCODE -ne 0) {
        throw "flux bootstrap command failed with exit code: $LASTEXITCODE"
    }
    Write-Host "Flux installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Failed to bootstrap Flux: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    Remove-Item env:GITHUB_TOKEN -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Flux will monitor: clusters/linode-lke/ in your repository" -ForegroundColor Cyan
Write-Host "Any changes to YAML files in that directory will be automatically deployed" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Commit the generated flux-system files to your repo"
Write-Host "2. Create application manifests in clusters/linode-lke/"
Write-Host "3. Use '.\deploy-app.ps1' to set up the initial application structure"
