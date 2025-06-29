#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Setup GitHub secrets for RandomCorp deployment automation

.DESCRIPTION
    This script helps you set up the required GitHub secrets for automated 
    deployment of RandomCorp using GitHub Actions.

.PARAMETER Repository
    GitHub repository in format owner/repo (default: GitRebeler/RandomCorp)

.EXAMPLE
    .\setup-github-secrets.ps1
    
.EXAMPLE
    .\setup-github-secrets.ps1 -Repository "yourusername/RandomCorp"
#>

param(
    [string]$Repository = "GitRebeler/RandomCorp"
)

Write-Host "🔐 GitHub Secrets Setup for RandomCorp" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install GitHub CLI from: https://cli.github.com/" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, you can set up secrets manually:" -ForegroundColor Yellow
    Write-Host "1. Go to https://github.com/$Repository/settings/secrets/actions" -ForegroundColor Yellow
    Write-Host "2. Add the required secrets as described in .github/GITHUB_ACTIONS_SETUP.md" -ForegroundColor Yellow
    exit 1
}

# Check if user is authenticated with GitHub
$authStatus = gh auth status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not authenticated with GitHub CLI" -ForegroundColor Red
    Write-Host "Please run: gh auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ GitHub CLI is installed and authenticated" -ForegroundColor Green
Write-Host ""

# Function to securely prompt for password
function Get-SecureInput {
    param(
        [string]$Prompt,
        [string]$Description = ""
    )
    
    if ($Description) {
        Write-Host $Description -ForegroundColor Gray
    }
    
    $secureString = Read-Host $Prompt -AsSecureString
    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    try {
        return [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    }
    finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

Write-Host "📝 Setting up GitHub secrets for repository: $Repository" -ForegroundColor Green
Write-Host ""

# Docker Hub credentials
Write-Host "🐳 Docker Hub Credentials" -ForegroundColor Cyan
Write-Host "-------------------------" -ForegroundColor Cyan
$dockerUsername = Read-Host "Enter your Docker Hub username"
$dockerPassword = Get-SecureInput "Enter your Docker Hub password/token" "Get this from: https://hub.docker.com/settings/security"

Write-Host ""

# Linode API Token
Write-Host "☁️  Linode API Token" -ForegroundColor Cyan
Write-Host "------------------" -ForegroundColor Cyan
$linodeToken = Get-SecureInput "Enter your Linode API token" "Get this from: https://cloud.linode.com/profile/tokens"

Write-Host ""
Write-Host "🔄 Setting GitHub secrets..." -ForegroundColor Yellow

try {
    # Set Docker Hub secrets
    Write-Host "Setting DOCKER_USERNAME..." -ForegroundColor Gray
    $env:DOCKER_USERNAME = $dockerUsername
    echo $dockerUsername | gh secret set DOCKER_USERNAME --repo $Repository
    
    Write-Host "Setting DOCKER_PASSWORD..." -ForegroundColor Gray
    echo $dockerPassword | gh secret set DOCKER_PASSWORD --repo $Repository
    
    # Set Linode token
    Write-Host "Setting LINODE_TOKEN..." -ForegroundColor Gray
    echo $linodeToken | gh secret set LINODE_TOKEN --repo $Repository
    
    Write-Host ""
    Write-Host "✅ All secrets have been successfully set!" -ForegroundColor Green
    Write-Host ""
    
    # Verify secrets
    Write-Host "🔍 Verifying secrets..." -ForegroundColor Cyan
    $secrets = gh secret list --repo $Repository --json name | ConvertFrom-Json
    $requiredSecrets = @("DOCKER_USERNAME", "DOCKER_PASSWORD", "LINODE_TOKEN")
    
    foreach ($required in $requiredSecrets) {
        if ($secrets.name -contains $required) {
            Write-Host "✅ $required" -ForegroundColor Green
        } else {
            Write-Host "❌ $required" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "🚀 Setup Complete!" -ForegroundColor Green
    Write-Host "You can now trigger the GitHub Actions workflow by:" -ForegroundColor White
    Write-Host "1. Pushing to the main/master branch" -ForegroundColor White
    Write-Host "2. Creating a pull request" -ForegroundColor White
    Write-Host "3. Manually triggering from: https://github.com/$Repository/actions" -ForegroundColor White
    Write-Host ""
    Write-Host "📖 For more information, see: .github/GITHUB_ACTIONS_SETUP.md" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Error setting secrets: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual setup instructions:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/$Repository/settings/secrets/actions" -ForegroundColor Yellow
    Write-Host "2. Add the following secrets:" -ForegroundColor Yellow
    Write-Host "   - DOCKER_USERNAME: $dockerUsername" -ForegroundColor Yellow
    Write-Host "   - DOCKER_PASSWORD: [your Docker Hub password/token]" -ForegroundColor Yellow
    Write-Host "   - LINODE_TOKEN: [your Linode API token]" -ForegroundColor Yellow
    exit 1
}

# Clean up sensitive variables
$dockerPassword = $null
$linodeToken = $null
Remove-Variable dockerPassword -ErrorAction SilentlyContinue
Remove-Variable linodeToken -ErrorAction SilentlyContinue
