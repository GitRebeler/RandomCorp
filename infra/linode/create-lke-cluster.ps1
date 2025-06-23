# Create Linode Kubernetes Engine (LKE) cluster for Random Corp
# This script creates a 3-node LKE cluster with proper configuration

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east", 
    [string]$NodeType = "g6-standard-1",
    [int]$NodeCount = 3,
    [string]$KubernetesVersion = "1.31",
    [switch]$WhatIf
)

Write-Host "=== Linode Kubernetes Engine Cluster Creation ===" -ForegroundColor Green
Write-Host ""

# Check if linode-cli is installed
if (-not (Get-Command "linode-cli" -ErrorAction SilentlyContinue)) {
    Write-Host "linode-cli not found. Please install it first:" -ForegroundColor Red
    Write-Host "pip install linode-cli" -ForegroundColor Yellow
    Write-Host "Then configure with: linode-cli configure" -ForegroundColor Yellow
    exit 1
}

# Validate parameters
Write-Host "Cluster Configuration:" -ForegroundColor Cyan
Write-Host "  Name: $ClusterName" -ForegroundColor White
Write-Host "  Region: $Region" -ForegroundColor White
Write-Host "  Node Type: $NodeType" -ForegroundColor White
Write-Host "  Node Count: $NodeCount" -ForegroundColor White
Write-Host "  Kubernetes Version: $KubernetesVersion" -ForegroundColor White
Write-Host ""

if ($WhatIf) {
    Write-Host "WhatIf Mode - No actual changes will be made" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Would create LKE cluster with the following command:" -ForegroundColor Cyan
    Write-Host "linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $KubernetesVersion --node_pools.type $NodeType --node_pools.count $NodeCount" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Estimated monthly cost: ~42 USD/month" -ForegroundColor Yellow
    Write-Host "To proceed, run without -WhatIf parameter" -ForegroundColor Green
    exit 0
}

# Check if cluster already exists
Write-Host "Checking if cluster already exists..." -ForegroundColor Cyan
try {
    $existingClusters = linode-cli lke clusters-list --json 2>$null | ConvertFrom-Json
    if ($existingClusters) {
        $existingCluster = $existingClusters | Where-Object { $_.label -eq $ClusterName }
        if ($existingCluster) {
            Write-Host "Cluster '$ClusterName' already exists (ID: $($existingCluster.id))" -ForegroundColor Green
            Write-Host "Status: $($existingCluster.status)" -ForegroundColor Yellow
            exit 0
        }
    }
} catch {
    Write-Host "Unable to check existing clusters, proceeding with creation..." -ForegroundColor Yellow
}

# Create the cluster
Write-Host "Creating LKE cluster..." -ForegroundColor Cyan
Write-Host "This may take 5-10 minutes..." -ForegroundColor Yellow

try {
    $clusterId = linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $KubernetesVersion --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format id

    if ($LASTEXITCODE -eq 0 -and $clusterId) {
        $clusterId = $clusterId.Trim()
        Write-Host "Cluster created successfully!" -ForegroundColor Green
        Write-Host "Cluster ID: $clusterId" -ForegroundColor White
        Write-Host ""
        
        # Wait for cluster to be ready
        Write-Host "Waiting for cluster to be ready..." -ForegroundColor Cyan
        $attempt = 0
        $maxAttempts = 20
        
        do {
            Start-Sleep -Seconds 30
            $attempt++
            $status = linode-cli lke cluster-view $clusterId --text --no-header --format status
            $status = $status.Trim()
            Write-Host "[$attempt/$maxAttempts] Current status: $status" -ForegroundColor Yellow
            
            if ($status -eq "ready") {
                break
            }
            
            if ($attempt -ge $maxAttempts) {
                Write-Host "Timeout waiting for cluster. Check Linode Cloud Manager for status." -ForegroundColor Yellow
                break
            }
        } while ($status -ne "ready")
        
        if ($status -eq "ready") {
            Write-Host "Cluster is ready!" -ForegroundColor Green
            
            # Download kubeconfig
            Write-Host "Downloading kubeconfig..." -ForegroundColor Cyan
            $kubeconfigFile = "kubeconfig-$ClusterName.yaml"
            linode-cli lke kubeconfig-view $clusterId --no-headers --text | Out-File -FilePath $kubeconfigFile -Encoding UTF8
            
            Write-Host ""
            Write-Host "Next steps:" -ForegroundColor Cyan
            Write-Host "1. Set KUBECONFIG:" -ForegroundColor White
            Write-Host "   `$env:KUBECONFIG = `"$(Get-Location)\$kubeconfigFile`"" -ForegroundColor Gray
            Write-Host "2. Test connection:" -ForegroundColor White
            Write-Host "   kubectl get nodes" -ForegroundColor Gray
            Write-Host "3. Deploy app:" -ForegroundColor White
            Write-Host "   .\deploy-app.ps1" -ForegroundColor Gray
        }
    } else {
        Write-Host "Failed to create cluster" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error creating cluster: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Check cluster status with proper command
Write-Host "Checking cluster status..." -ForegroundColor Cyan
$statusOutput = linode-cli lke cluster-view $clusterId --text --no-header --format status
Write-Host "Raw status output: '$statusOutput'" -ForegroundColor Gray

# Quick setup commands for immediate use
Write-Host ""
Write-Host "=== QUICK SETUP ===" -ForegroundColor Green
Write-Host "Your cluster ID is: $clusterId" -ForegroundColor White
Write-Host ""
Write-Host "Download kubeconfig:" -ForegroundColor Cyan
Write-Host "linode-cli lke kubeconfig-view $clusterId --no-headers --text > kubeconfig-randomcorp.yaml" -ForegroundColor Gray
Write-Host ""
Write-Host "Set kubeconfig:" -ForegroundColor Cyan  
Write-Host "`$env:KUBECONFIG = `"$(Get-Location)\kubeconfig-randomcorp.yaml`"" -ForegroundColor Gray
Write-Host ""
Write-Host "Test cluster:" -ForegroundColor Cyan
Write-Host "kubectl get nodes" -ForegroundColor Gray
Write-Host ""
Write-Host "Deploy app:" -ForegroundColor Cyan
Write-Host ".\deploy-app.ps1" -ForegroundColor Gray

Write-Host ""
Write-Host "=== Cluster Creation Complete ===" -ForegroundColor Green