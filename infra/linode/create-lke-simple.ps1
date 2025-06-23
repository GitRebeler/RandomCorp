# Simple, reliable PowerShell script to create Linode LKE cluster
# Uses known working values to avoid API issues

param(
    [string]$ClusterName = "randomcorp-lke",
    [string]$Region = "us-east",
    [string]$NodeType = "g6-standard-1",  # 2GB instances (Nanodes not supported in LKE)
    [int]$NodeCount = 3
)

# Use a known stable Kubernetes version (check with: linode-cli lke versions-list)
$K8sVersion = "1.31"

Write-Host "=== Creating Linode LKE Cluster ===" -ForegroundColor Green
Write-Host "Cluster Name: $ClusterName"
Write-Host "Region: $Region"
Write-Host "Node Type: $NodeType"
Write-Host "Node Count: $NodeCount"
Write-Host "K8s Version: $K8sVersion"
Write-Host ""

# Validate linode-cli
Write-Host "Validating linode-cli..." -ForegroundColor Yellow
try {
    $cliVersion = & linode-cli --version 2>&1
    Write-Host "SUCCESS: $cliVersion" -ForegroundColor Green
} catch {
    Write-Host "ERROR: linode-cli not found" -ForegroundColor Red
    Write-Host "Install: pip install linode-cli" -ForegroundColor Yellow
    Write-Host "Configure: linode-cli configure" -ForegroundColor Yellow
    exit 1
}

# Test API access
Write-Host "Testing API access..." -ForegroundColor Yellow
try {
    $userInfo = & linode-cli profile view --text --no-header 2>&1
    if ($userInfo -match "error") {
        Write-Host "ERROR: API access failed. Run: linode-cli configure" -ForegroundColor Red
        exit 1
    }
    Write-Host "SUCCESS: API access working" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot access Linode API" -ForegroundColor Red
    exit 1
}

# Create cluster with explicit parameters
Write-Host "Creating LKE cluster..." -ForegroundColor Yellow
Write-Host "Command: linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $K8sVersion --node_pools.type $NodeType --node_pools.count $NodeCount" -ForegroundColor Cyan

try {
    # Execute the command and capture all output
    $createResult = & linode-cli lke cluster-create --label $ClusterName --region $Region --k8s_version $K8sVersion --node_pools.type $NodeType --node_pools.count $NodeCount --text --no-header --format="id" 2>&1
    
    # Join all output into a single string
    $output = $createResult -join "`n"
    Write-Host "Raw output: $output" -ForegroundColor Gray
    
    # Look for cluster ID (should be a number)
    $clusterId = $null
    foreach ($line in $createResult) {
        if ($line -match '^\d+$') {
            $clusterId = $line.Trim()
            break
        }
    }
    
    if ($clusterId) {
        Write-Host "SUCCESS: Cluster created with ID: $clusterId" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No valid cluster ID found in output" -ForegroundColor Red
        Write-Host "Full output: $output" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Exception during cluster creation" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Wait for cluster to be ready
Write-Host "Waiting for cluster to be ready..." -ForegroundColor Yellow
$attempts = 0
$maxAttempts = 20

do {
    $attempts++
    Start-Sleep 30
    
    try {
        $statusResult = & linode-cli lke cluster-view $clusterId --text --no-header --format="status" 2>&1
        $status = ($statusResult | Where-Object { $_ -notmatch "error" })[0]
        
        if ($status) {
            $status = $status.Trim()
            Write-Host "Attempt $attempts - Status: $status" -ForegroundColor Cyan
            
            if ($status -eq "ready") {
                Write-Host "SUCCESS: Cluster is ready!" -ForegroundColor Green
                break
            }
        }
        
        if ($attempts -ge $maxAttempts) {
            Write-Host "ERROR: Timeout waiting for cluster" -ForegroundColor Red
            exit 1
        }
        
    } catch {
        Write-Host "Warning: Could not check status (attempt $attempts)" -ForegroundColor Yellow
    }
} while ($true)

# Download kubeconfig
Write-Host "Downloading kubeconfig..." -ForegroundColor Yellow
try {
    $kubeconfigData = & linode-cli lke kubeconfig-view $clusterId --text --no-header 2>&1
    
    # Filter out any error messages and keep only valid YAML
    $validLines = $kubeconfigData | Where-Object { $_ -notmatch "error|warning|usage:" -and $_ -match "\S" }
    
    if ($validLines) {
        $validLines | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
        Write-Host "SUCCESS: Kubeconfig saved to kubeconfig-randomcorp.yaml" -ForegroundColor Green
    } else {
        Write-Host "ERROR: No valid kubeconfig data received" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "ERROR: Could not download kubeconfig" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== CLUSTER CREATED SUCCESSFULLY ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Set kubeconfig environment variable:"
Write-Host "   `$env:KUBECONFIG = '$(Get-Location)\kubeconfig-randomcorp.yaml'" -ForegroundColor White
Write-Host ""
Write-Host "2. Test the cluster:"
Write-Host "   kubectl get nodes" -ForegroundColor White
Write-Host ""
Write-Host "3. View cluster in Linode Cloud Manager:"
Write-Host "   https://cloud.linode.com/kubernetes/clusters/$clusterId" -ForegroundColor White
Write-Host ""
Write-Host "Cluster Information:" -ForegroundColor Cyan
Write-Host "- Cluster ID: $clusterId"
Write-Host "- Name: $ClusterName"
Write-Host "- Region: $Region"
Write-Host "- Node Type: $NodeType"
Write-Host "- Node Count: $NodeCount"
Write-Host "- Kubernetes: $K8sVersion"
$cost = ($NodeCount * 5) + 12
Write-Host "- Estimated Cost: `$$cost/month"
