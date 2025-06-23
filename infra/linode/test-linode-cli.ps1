# Simple test script to validate Linode CLI is working
# Run this before using the main cluster creation script

Write-Host "Checking Linode CLI configuration..." -ForegroundColor Green
Write-Host ""

# Test 1: Check if linode-cli is installed
Write-Host "Test 1: Checking if linode-cli is installed..." -ForegroundColor Yellow
try {
    $version = & linode-cli --version 2>&1
    Write-Host "SUCCESS: linode-cli version: $version" -ForegroundColor Green
} catch {
    Write-Host "ERROR: linode-cli not found. Install with: pip install linode-cli" -ForegroundColor Red
    exit 1
}

# Test 2: Check if linode-cli is configured
Write-Host ""
Write-Host "Test 2: Checking if linode-cli is configured..." -ForegroundColor Yellow
try {
    $userProfile = & linode-cli profile view --text --no-header 2>&1
    if ($userProfile -match "error" -or $userProfile -match "not configured") {
        Write-Host "ERROR: linode-cli not configured. Run: linode-cli configure" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "SUCCESS: linode-cli is configured" -ForegroundColor Green
    }
} catch {
    Write-Host "ERROR: linode-cli not configured. Run: linode-cli configure" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Linode CLI validation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run the cluster creation script" -ForegroundColor Cyan
