#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Trigger GitHub Actions deployment for RandomCorp

.DESCRIPTION
    This script triggers the GitHub Actions workflow to deploy RandomCorp to Linode LKE.

.PARAMETER Repository
    GitHub repository in format owner/repo (default: GitRebeler/RandomCorp)

.PARAMETER ForceRebuild
    Force rebuild all images even if no changes detected

.EXAMPLE
    .\trigger-deployment.ps1
    
.EXAMPLE
    .\trigger-deployment.ps1 -ForceRebuild
    
.EXAMPLE
    .\trigger-deployment.ps1 -Repository "yourusername/RandomCorp"
#>

param(
    [string]$Repository = "GitRebeler/RandomCorp",
    [switch]$ForceRebuild
)

Write-Host "🚀 Triggering RandomCorp Deployment" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ GitHub CLI (gh) is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install GitHub CLI from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Check if user is authenticated with GitHub
gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Not authenticated with GitHub CLI" -ForegroundColor Red
    Write-Host "Please run: gh auth login" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ GitHub CLI is ready" -ForegroundColor Green
Write-Host ""

# Prepare workflow inputs
$inputs = @{}
if ($ForceRebuild) {
    $inputs["force_rebuild"] = "true"
    Write-Host "🔄 Force rebuild enabled" -ForegroundColor Yellow
}

Write-Host "📡 Triggering workflow for repository: $Repository" -ForegroundColor Green

try {
    if ($inputs.Count -gt 0) {
        $inputArgs = @()
        foreach ($key in $inputs.Keys) {
            $inputArgs += "-f"
            $inputArgs += "$key=$($inputs[$key])"
        }
        gh workflow run "deploy.yml" --repo $Repository @inputArgs
    } else {
        gh workflow run "deploy.yml" --repo $Repository
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Workflow triggered successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "🔍 Monitor the deployment progress at:" -ForegroundColor Cyan
        Write-Host "https://github.com/$Repository/actions" -ForegroundColor Blue
        Write-Host ""
        
        # Wait a moment and try to get the latest run
        Start-Sleep -Seconds 2
        Write-Host "📊 Recent workflow runs:" -ForegroundColor Cyan
        gh run list --repo $Repository --limit 3 --workflow "deploy.yml"
        
        Write-Host ""
        Write-Host "💡 You can also watch the logs in real-time:" -ForegroundColor Gray
        Write-Host "gh run watch --repo $Repository" -ForegroundColor Gray
    } else {
        Write-Host "❌ Failed to trigger workflow" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "❌ Error triggering workflow: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual trigger options:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/$Repository/actions" -ForegroundColor Yellow
    Write-Host "2. Select 'Deploy RandomCorp to LKE' workflow" -ForegroundColor Yellow
    Write-Host "3. Click 'Run workflow'" -ForegroundColor Yellow
    exit 1
}
