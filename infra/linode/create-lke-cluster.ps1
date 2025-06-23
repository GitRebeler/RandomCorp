# PowerShell script to create Linode LKE cluster
# For Windows users who prefer PowerShell

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east",
    [string]$NodeType = "g6-standard-1",  # g6-standard-1 ($10/mo) - Nanodes not supported in LKE
    [int]$NodeCount = 3,
    [string]$K8sVersion = "1.31"  # Use available version
)

Write-Host "🚀 Creating Linode LKE cluster: $ClusterName" -ForegroundColor Green
Write-Host "Region: $Region"
Write-Host "Node Type: $NodeType"
Write-Host "Node Count: $NodeCount"
Write-Host "Kubernetes Version: $K8sVersion"
Write-Host ""

# Check if linode-cli is available
try {
    $null = & linode-cli --version 2>$null
    Write-Host "✅ linode-cli found" -ForegroundColor Green
} catch {
    Write-Host "❌ linode-cli not found. Please install:" -ForegroundColor Red
    Write-Host "pip install linode-cli"
    Write-Host "linode-cli configure"
    exit 1
}

Write-Host "📋 Creating LKE cluster..." -ForegroundColor Yellow

# Create the cluster - properly escape arguments for PowerShell
try {
    $clusterId = & linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $K8sVersion --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id"
    $clusterId = $clusterId.Trim()
} catch {
    Write-Host "❌ Failed to create cluster: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $clusterId -or $clusterId -eq "") {
    Write-Host "❌ Failed to create cluster - no cluster ID returned" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Cluster created with ID: $clusterId" -ForegroundColor Green
Write-Host 'Waiting for cluster to be ready (may take 5-10 minutes)...' -ForegroundColor Yellow

# Wait for cluster to be ready
do {
    try {
        $status = & linode-cli lke cluster-view $clusterId --text --no-header --format="status"
        $status = $status.Trim()
        
        if ($status -eq "ready") {
            Write-Host "✅ Cluster is ready!" -ForegroundColor Green
            break
        }
        Write-Host "Cluster status: $status (waiting...)" -ForegroundColor Yellow
        Start-Sleep 30
    } catch {
        Write-Host "⚠️ Error checking cluster status, retrying..." -ForegroundColor Yellow
        Start-Sleep 30
    }
} while ($true)

# Download kubeconfig
Write-Host "📥 Downloading kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfigContent = & linode-cli lke kubeconfig-view $clusterId --text --no-header
    $kubeconfigContent | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
    Write-Host "✅ Kubeconfig saved to kubeconfig-randomcorp.yaml" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to download kubeconfig: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 LKE cluster created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Set kubeconfig: " -NoNewline
Write-Host "`$env:KUBECONFIG = `"$(Get-Location)\kubeconfig-randomcorp.yaml`"" -ForegroundColor Cyan
Write-Host "2. Verify cluster: " -NoNewline
Write-Host "kubectl get nodes" -ForegroundColor Cyan
Write-Host "3. Install Flux: " -NoNewline
Write-Host ".\install-flux.ps1" -ForegroundColor Cyan
Write-Host "4. Deploy application: " -NoNewline
Write-Host ".\deploy-app.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Cluster Details:"
Write-Host "- Cluster ID: $clusterId"
Write-Host "- Name: $ClusterName"
Write-Host "- Region: $Region"
Write-Host "- Nodes: $NodeCount x $NodeType"
$monthlyCost = ($NodeCount * 5) + 12
Write-Host "- Monthly Cost: ~`$${monthlyCost} including NodeBalancer and storage"
