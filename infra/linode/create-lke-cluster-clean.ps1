# PowerShell script to create Linode LKE cluster
# Simplified version to avoid syntax issues

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east", 
    [string]$NodeType = "g6-nanode-1",
    [int]$NodeCount = 3,
    [string]$K8sVersion = "1.27"
)

Write-Host "Creating Linode LKE cluster: $ClusterName" -ForegroundColor Green
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Node Type: $NodeType" -ForegroundColor Cyan
Write-Host "Node Count: $NodeCount" -ForegroundColor Cyan
Write-Host "Kubernetes Version: $K8sVersion" -ForegroundColor Cyan
Write-Host ""

# Check if linode-cli is available
Write-Host "Checking linode-cli..." -ForegroundColor Yellow
try {
    $null = & linode-cli --version 2>$null
    Write-Host "SUCCESS: linode-cli found" -ForegroundColor Green
} catch {
    Write-Host "ERROR: linode-cli not found" -ForegroundColor Red
    Write-Host "Install with: pip install linode-cli" -ForegroundColor Yellow
    Write-Host "Configure with: linode-cli configure" -ForegroundColor Yellow
    exit 1
}

Write-Host "Creating LKE cluster..." -ForegroundColor Yellow

# Create the cluster
try {
    $clusterId = & linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $K8sVersion --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id"
    $clusterId = $clusterId.Trim()
} catch {
    Write-Host "ERROR: Failed to create cluster" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

if (-not $clusterId -or $clusterId -eq "") {
    Write-Host "ERROR: No cluster ID returned" -ForegroundColor Red
    exit 1
}

Write-Host "SUCCESS: Cluster created with ID: $clusterId" -ForegroundColor Green
Write-Host "Waiting for cluster to be ready - this may take 5-10 minutes..." -ForegroundColor Yellow

# Wait for cluster to be ready
$attempts = 0
$maxAttempts = 20
do {
    Start-Sleep 30
    $attempts++
    
    try {
        $status = & linode-cli lke cluster-view $clusterId --text --no-header --format="status"
        $status = $status.Trim()
        
        Write-Host "Attempt $attempts`: Cluster status is $status" -ForegroundColor Cyan
        
        if ($status -eq "ready") {
            Write-Host "SUCCESS: Cluster is ready!" -ForegroundColor Green
            break
        }
        
        if ($attempts -ge $maxAttempts) {
            Write-Host "ERROR: Timeout waiting for cluster to be ready" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Warning: Error checking cluster status, retrying..." -ForegroundColor Yellow
    }
} while ($true)

# Download kubeconfig
Write-Host "Downloading kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfigContent = & linode-cli lke kubeconfig-view $clusterId --text --no-header
    $kubeconfigContent | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
    Write-Host "SUCCESS: Kubeconfig saved to kubeconfig-randomcorp.yaml" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to download kubeconfig" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "LKE cluster created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Set kubeconfig environment variable" -ForegroundColor White
Write-Host "2. Verify cluster with: kubectl get nodes" -ForegroundColor White  
Write-Host "3. Install Flux for GitOps" -ForegroundColor White
Write-Host "4. Deploy your application" -ForegroundColor White
Write-Host ""
Write-Host "Cluster Details:" -ForegroundColor Cyan
Write-Host "- Cluster ID: $clusterId"
Write-Host "- Name: $ClusterName"
Write-Host "- Region: $Region"  
Write-Host "- Nodes: $NodeCount x $NodeType"
$monthlyCost = ($NodeCount * 5) + 12
Write-Host "- Monthly Cost: approximately $monthlyCost USD"
