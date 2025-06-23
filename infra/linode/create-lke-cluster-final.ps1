# PowerShell script to create Linode LKE cluster  
# Final version with validation and error handling

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east",
    [string]$NodeType = "g6-nanode-1", 
    [int]$NodeCount = 3,
    [string]$K8sVersion = ""  # Will auto-detect latest
)

function Write-Status {
    param([string]$Message, [string]$Type = "Info")
    
    switch ($Type) {
        "Success" { Write-Host "✓ $Message" -ForegroundColor Green }
        "Error" { Write-Host "✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "⚠ $Message" -ForegroundColor Yellow }
        "Info" { Write-Host "ℹ $Message" -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

Write-Status "Creating Linode LKE cluster: $ClusterName" "Info"
Write-Host "Region: $Region"
Write-Host "Node Type: $NodeType" 
Write-Host "Node Count: $NodeCount"
Write-Host ""

# Validate linode-cli
Write-Status "Checking linode-cli installation..." "Info"
try {
    $null = & linode-cli --version 2>$null
    Write-Status "linode-cli found and working" "Success"
} catch {
    Write-Status "linode-cli not found or not working" "Error"
    Write-Host "Install with: pip install linode-cli"
    Write-Host "Configure with: linode-cli configure"
    exit 1
}

# Get available Kubernetes versions if not specified
if (-not $K8sVersion) {
    Write-Status "Getting available Kubernetes versions..." "Info"
    try {
        $versions = & linode-cli lke versions-list --text --no-header --format="id" 2>$null
        $K8sVersion = ($versions | Select-Object -First 1).Trim()
        Write-Status "Using Kubernetes version: $K8sVersion" "Success"
    } catch {
        Write-Status "Could not get K8s versions, using default" "Warning"
        $K8sVersion = "1.27"
    }
}

# Validate region
Write-Status "Validating region: $Region" "Info"
try {
    $regions = & linode-cli regions list --text --no-header --format="id" 2>$null
    if ($regions -notcontains $Region) {
        Write-Status "Region $Region might not be valid" "Warning"
        Write-Host "Available regions: $($regions -join ', ')"
    }
} catch {
    Write-Status "Could not validate region" "Warning"
}

# Create cluster
Write-Status "Creating LKE cluster..." "Info"
try {
    if ($K8sVersion) {
        $clusterId = & linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $K8sVersion --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id" 2>&1
    } else {
        $clusterId = & linode-cli lke cluster-create --label $ClusterName --region $Region --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id" 2>&1
    }
    
    $clusterId = $clusterId.Trim()
    
    if ($clusterId -match "error" -or $clusterId -match "failed" -or $clusterId -match "Request failed") {
        Write-Status "Failed to create cluster" "Error"
        Write-Host $clusterId
        exit 1
    }
    
} catch {
    Write-Status "Error creating cluster" "Error"
    Write-Host $_.Exception.Message
    exit 1
}

if (-not $clusterId -or $clusterId -eq "") {
    Write-Status "No cluster ID returned" "Error"
    exit 1
}

Write-Status "Cluster created with ID: $clusterId" "Success"
Write-Status "Waiting for cluster to be ready - this may take 5-10 minutes..." "Info"

# Wait for cluster
$attempts = 0
$maxAttempts = 20
do {
    Start-Sleep 30
    $attempts++
    
    try {
        $status = & linode-cli lke cluster-view $clusterId --text --no-header --format="status" 2>$null
        $status = $status.Trim()
        
        Write-Host "Attempt $attempts - Status: $status"
        
        if ($status -eq "ready") {
            Write-Status "Cluster is ready!" "Success"
            break
        }
        
        if ($attempts -ge $maxAttempts) {
            Write-Status "Timeout waiting for cluster" "Error"
            exit 1
        }
    } catch {
        Write-Status "Error checking status, retrying..." "Warning"
    }
} while ($true)

# Download kubeconfig  
Write-Status "Downloading kubeconfig..." "Info"
try {
    $kubeconfig = & linode-cli lke kubeconfig-view $clusterId --text --no-header 2>$null
    $kubeconfig | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
    Write-Status "Kubeconfig saved to kubeconfig-randomcorp.yaml" "Success"
} catch {
    Write-Status "Failed to download kubeconfig" "Error"
    exit 1
}

Write-Host ""
Write-Status "LKE cluster created successfully!" "Success"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Set environment: `$env:KUBECONFIG = 'kubeconfig-randomcorp.yaml'"
Write-Host "2. Test cluster: kubectl get nodes"
Write-Host "3. Install Flux: .\install-flux.ps1"
Write-Host ""
Write-Host "Cluster Details:"
Write-Host "- ID: $clusterId"
Write-Host "- Name: $ClusterName"
Write-Host "- Region: $Region"
Write-Host "- Nodes: $NodeCount x $NodeType"
$cost = ($NodeCount * 5) + 12
Write-Host "- Est. Cost: `$$cost/month"
