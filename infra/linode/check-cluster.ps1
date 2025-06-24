# Check status of Linode LKE cluster and download kubeconfig when ready
$clusterId = 493485
Write-Host "=== Linode LKE Cluster Status ===" -ForegroundColor Green
Write-Host ""

# List all clusters
Write-Host "Existing clusters:" -ForegroundColor Cyan
linode-cli lke clusters-list

Write-Host ""
Write-Host "Checking cluster $clusterId status..." -ForegroundColor Yellow

# Try to get kubeconfig
try {
    Write-Host "Attempting to download kubeconfig..." -ForegroundColor Yellow
    $kubeconfig = linode-cli lke kubeconfig-view $clusterId --text --no-header 2>&1

    if ($kubeconfig -match "503|not yet available") {
        Write-Host "Cluster is still being provisioned. Please wait..." -ForegroundColor Yellow
        Write-Host "Try again in a few minutes." -ForegroundColor Yellow    } else {
        # Save and decode kubeconfig (Linode returns base64 encoded)
        $kubeconfig | Out-File -FilePath "kubeconfig-randomcorp-encoded.yaml" -Encoding UTF8
        $base64Content = Get-Content "kubeconfig-randomcorp-encoded.yaml" -Raw
        $decodedContent = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))
        $decodedContent | Out-File -FilePath "kubeconfig-randomcorp.yaml" -Encoding UTF8
        Remove-Item "kubeconfig-randomcorp-encoded.yaml" -Force
        
        Write-Host "SUCCESS: Kubeconfig downloaded and decoded!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Set environment variable:" -ForegroundColor White
        Write-Host "   `$env:KUBECONFIG = '$(Get-Location)\kubeconfig-randomcorp.yaml'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "2. Test cluster connection:" -ForegroundColor White
        Write-Host "   kubectl get nodes" -ForegroundColor Gray
        Write-Host ""
        Write-Host "3. View cluster dashboard:" -ForegroundColor White
        Write-Host "   https://cloud.linode.com/kubernetes/clusters/$clusterId" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error checking cluster: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Cluster Details:" -ForegroundColor Cyan
Write-Host "- Cluster ID: $clusterId"
Write-Host "- Name: randomcorp-lke"  
Write-Host "- Region: us-east"
Write-Host "- Node Type: g6-standard-1 (2GB Linode)"
Write-Host "- Node Count: 3"
Write-Host "- Kubernetes Version: 1.31"
Write-Host "- Monthly Cost: ~`$42 (3 x `$10 nodes + `$12 load balancer)"
Write-Host ""
Write-Host "Cost Comparison:" -ForegroundColor Yellow
Write-Host "- Linode LKE: `$42/month"
Write-Host "- Azure AKS: `$90-94/month"
Write-Host "- Savings: ~50% vs Azure!"
