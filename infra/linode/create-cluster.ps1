# Simple PowerShell script to create Linode LKE cluster
# Basic version that works reliably

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east",
    [string]$NodeType = "g6-nanode-1",
    [int]$NodeCount = 3
)

Write-Host "=== Creating Linode LKE Cluster ===" -ForegroundColor Green
Write-Host "Cluster Name: $ClusterName"
Write-Host "Region: $Region"
Write-Host "Node Type: $NodeType" 
Write-Host "Node Count: $NodeCount"
Write-Host ""

# Check linode-cli
Write-Host "Checking linode-cli..." -ForegroundColor Yellow
try {
    $version = & linode-cli --version 2>&1
    Write-Host "SUCCESS: Found $version" -ForegroundColor Green
} catch {
    Write-Host "ERROR: linode-cli not found" -ForegroundColor Red
    Write-Host "Install: pip install linode-cli" -ForegroundColor Yellow
    Write-Host "Configure: linode-cli configure" -ForegroundColor Yellow
    exit 1
}

# Get latest K8s version
Write-Host "Getting available Kubernetes versions..." -ForegroundColor Yellow
try {
    $k8sResult = & linode-cli lke versions-list --text --no-header --format="id" 2>&1
    
    # Filter for valid k8s versions (format like 1.27, 1.28, etc.)
    $validVersions = $k8sResult | Where-Object { $_ -match '^\d+\.\d+$' -and $_ -le "1.30" }
    
    if ($validVersions) {
        # Get the highest stable version (usually 1.27, 1.28, 1.29, or 1.30)
        $latestK8s = ($validVersions | Sort-Object {[version]$_} -Descending)[0]
        Write-Host "Using K8s version: $latestK8s" -ForegroundColor Green
    } else {
        $latestK8s = "1.28"  # Safe default
        Write-Host "Could not find valid versions, using safe default: $latestK8s" -ForegroundColor Yellow
    }
} catch {
    $latestK8s = "1.28"  # Safe default
    Write-Host "Error getting versions, using safe default: $latestK8s" -ForegroundColor Yellow
}

# Create cluster
Write-Host "Creating cluster..." -ForegroundColor Yellow

try {
    $result = & linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $latestK8s --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id" 2>&1
    
    # Convert result to string and check for errors
    $resultString = $result | Out-String
    $resultString = $resultString.Trim()
    
    if ($resultString -match "error|failed|Request failed|400|401|403|404|500") {
        Write-Host "ERROR: $resultString" -ForegroundColor Red
        exit 1
    }
    
    # Extract just the cluster ID (should be a number)
    $clusterId = $resultString -replace '\s+', '' # Remove any whitespace
    
    if ($clusterId -match '^\d+$') {
        Write-Host "SUCCESS: Cluster ID = $clusterId" -ForegroundColor Green
    } else {
        Write-Host "ERROR: Invalid cluster ID returned: $clusterId" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Failed to create cluster" -ForegroundColor Red
    if ($_.Exception.Message) {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    exit 1
}

# Wait for ready
Write-Host "Waiting for cluster to become ready..." -ForegroundColor Yellow
$maxWait = 600  # 10 minutes
$waited = 0

do {
    Start-Sleep 30
    $waited += 30
      try {
        $statusResult = & linode-cli lke cluster-view $clusterId --text --no-header --format="status" 2>&1
        $status = ($statusResult | Out-String).Trim()
        
        Write-Host "Status: $status (waited $waited seconds)" -ForegroundColor Cyan
        
        if ($status -eq "ready") {
            Write-Host "SUCCESS: Cluster is ready!" -ForegroundColor Green
            break
        }
        
        if ($waited -ge $maxWait) {
            Write-Host "ERROR: Timeout waiting for cluster" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Warning: Could not check status" -ForegroundColor Yellow
    }
} while ($true)

# Get kubeconfig
Write-Host "Downloading kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfigResult = & linode-cli lke kubeconfig-view $clusterId --text --no-header 2>&1
    $kubeconfigResult | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
    Write-Host "SUCCESS: Kubeconfig saved" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Could not download kubeconfig" -ForegroundColor Red
    if ($_.Exception.Message) {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "=== CLUSTER CREATED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set kubeconfig:"
Write-Host "   `$env:KUBECONFIG = '$(Get-Location)\kubeconfig-randomcorp.yaml'"
Write-Host ""
Write-Host "2. Test connection:"
Write-Host "   kubectl get nodes"
Write-Host ""
Write-Host "Cluster Info:" -ForegroundColor Cyan
Write-Host "- ID: $clusterId"
Write-Host "- Name: $ClusterName"
Write-Host "- Region: $Region"
Write-Host "- Nodes: $NodeCount x $NodeType"
$monthlyCost = ($NodeCount * 5) + 12
Write-Host "- Cost: ~`$$monthlyCost/month"
