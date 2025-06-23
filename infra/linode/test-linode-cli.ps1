# Simple test script to validate Linode CLI is working
# Run this before using the main cluster creation script

Write-Host "🔍 Testing Linode CLI configuration..." -ForegroundColor Green
Write-Host ""

# Test 1: Check if linode-cli is installed
Write-Host "Test 1: Checking if linode-cli is installed..." -ForegroundColor Yellow
try {
    $version = & linode-cli --version 2>&1
    Write-Host "✅ linode-cli version: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ linode-cli not found. Install with: pip install linode-cli" -ForegroundColor Red
    exit 1
}

# Test 2: Check if linode-cli is configured
Write-Host ""
Write-Host "Test 2: Checking if linode-cli is configured..." -ForegroundColor Yellow
try {
    $userProfile = & linode-cli profile view --text --no-header 2>&1
    if ($userProfile -match "error" -or $userProfile -match "not configured") {
        Write-Host "❌ linode-cli not configured. Run: linode-cli configure" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ linode-cli is configured" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ linode-cli not configured. Run: linode-cli configure" -ForegroundColor Red
    exit 1
}

# Test 3: List available regions
Write-Host ""
Write-Host "Test 3: Checking available regions..." -ForegroundColor Yellow
try {
    $regions = & linode-cli regions list --text --no-header --format="id,country" 2>&1
    Write-Host "✅ Available regions:" -ForegroundColor Green
    $regions | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
    Write-Host "  (showing first 5 regions)"
} catch {
    Write-Host "⚠️ Could not list regions: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Test 4: Check LKE availability
Write-Host ""
Write-Host "Test 4: Checking LKE clusters..." -ForegroundColor Yellow
try {
    $clusters = & linode-cli lke clusters-list --text --no-header 2>&1
    if ($clusters -match "error") {
        Write-Host "⚠️ LKE may not be available in your region" -ForegroundColor Yellow
    } else {
        Write-Host "✅ LKE is available" -ForegroundColor Green
        if ($clusters.Trim() -eq "") {
            Write-Host "  No existing clusters found" -ForegroundColor Cyan
        } else {
            Write-Host "  Existing clusters:" -ForegroundColor Cyan
            $clusters | ForEach-Object { Write-Host "    $_" }
        }
    }
} catch {
    Write-Host "⚠️ Could not check LKE clusters: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎉 Linode CLI validation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "If all tests passed, you can now run:" -ForegroundColor Cyan
Write-Host '  .\create-lke-cluster.ps1' -ForegroundColor Yellow
